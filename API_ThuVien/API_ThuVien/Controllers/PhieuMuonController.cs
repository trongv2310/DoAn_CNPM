using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using API_ThuVien.Models;
using API_ThuVien.DTO;
using System.Linq;
using System.Threading.Tasks;
using System;
using System.Collections.Generic;

namespace API_ThuVien.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PhieuMuonController : ControllerBase
    {
        private readonly ThuVienDbContext _context;

        public PhieuMuonController(ThuVienDbContext context)
        {
            _context = context;
        }

        // --- ENDPOINT 1: Độc giả gửi yêu cầu mượn ---
        [HttpPost]
        public async Task<IActionResult> CreateBorrowRequest([FromBody] BorrowRequestDto request)
        {
            // 1. VALIDATION
            if (request == null || request.SachMuon == null || !request.SachMuon.Any())
                return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ." });

            DateOnly ngayHienTai = DateOnly.FromDateTime(DateTime.Now);
            DateOnly hanTra = DateOnly.FromDateTime(request.NgayHenTra);

            if (hanTra <= ngayHienTai)
                return BadRequest(new { success = false, message = "Ngày hẹn trả phải sau ngày hôm nay." });

            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    // Tìm sinh viên
                    var sinhVien = await _context.Sinhviens.FirstOrDefaultAsync(sv => sv.Mataikhoan == request.MaTaiKhoan);
                    if (sinhVien == null) return NotFound(new { success = false, message = "Không tìm thấy thông tin sinh viên." });

                    // 2. KIỂM TRA VÀ TRỪ TỒN KHO (ĐỂ GIỮ CHỖ SÁCH)
                    foreach (var item in request.SachMuon)
                    {
                        var sach = await _context.Saches.FindAsync(item.MaSach);
                        if (sach == null) throw new Exception($"Sách ID {item.MaSach} không tồn tại.");

                        if (sach.Soluongton < item.SoLuong)
                            throw new Exception($"Sách '{sach.Tensach}' không đủ số lượng (Còn: {sach.Soluongton}).");

                        // Trừ kho ngay khi đặt để giữ sách
                        sach.Soluongton -= item.SoLuong;

                        // LƯU Ý: KHÔNG CẦN SET sach.Trangthai THỦ CÔNG
                        // Trigger 'TG_TRANGTHAI_SACH' trong SQL sẽ tự động làm việc này khi Soluongton thay đổi.

                        _context.Saches.Update(sach);
                    }

                    // 3. TẠO PHIẾU MƯỢN (TRẠNG THÁI CHỜ DUYỆT)
                    var defaultThuThu = await _context.Thuthus.FirstOrDefaultAsync();
                    var newPhieuMuon = new Phieumuon
                    {
                        Masv = sinhVien.Masv,
                        Matt = defaultThuThu?.Matt ?? 1,
                        Ngaylapphieumuon = ngayHienTai,
                        Hantra = hanTra,
                        Trangthai = "Chờ duyệt" // Trạng thái ban đầu
                    };

                    _context.Phieumuons.Add(newPhieuMuon);
                    await _context.SaveChangesAsync(); // Lưu để lấy Mapm

                    // 4. TẠO CHI TIẾT
                    foreach (var item in request.SachMuon)
                    {
                        var chiTiet = new Chitietphieumuon
                        {
                            Mapm = newPhieuMuon.Mapm,
                            Masach = item.MaSach,
                            Soluong = item.SoLuong,
                            Hantra = hanTra,
                            Solangiahan = 0
                        };
                        _context.Chitietphieumuons.Add(chiTiet);
                    }

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Ok(new
                    {
                        success = true,
                        message = "Gửi yêu cầu thành công. Vui lòng chờ thủ thư duyệt.",
                        maPhieuMuon = newPhieuMuon.Mapm
                    });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    return BadRequest(new { success = false, message = ex.Message });
                }
            }
        }

        // --- ENDPOINT 2: Thủ thư duyệt yêu cầu ---
        [HttpPost("approve/{mapm}")]
        public async Task<IActionResult> ApproveBorrowRequest(int mapm, [FromQuery] int maThuThuDuyet)
        {
            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    var phieuMuon = await _context.Phieumuons.FindAsync(mapm);
                    if (phieuMuon == null) return NotFound(new { message = "Không tìm thấy phiếu mượn." });

                    if (phieuMuon.Trangthai != "Chờ duyệt")
                        return BadRequest(new { message = "Phiếu này không ở trạng thái chờ duyệt." });

                    // Cập nhật trạng thái sang Đang mượn
                    phieuMuon.Trangthai = "Đang mượn";
                    phieuMuon.Matt = maThuThuDuyet;

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Ok(new { message = "Duyệt phiếu thành công." });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
                }
            }
        }

        // --- ENDPOINT 3: Lịch sử mượn (QUAN TRỌNG CHO APP) ---
        [HttpGet("History/{maTaiKhoan}")]
        public async Task<IActionResult> GetLichSuMuon(int maTaiKhoan)
        {
            // 1. Tìm sinh viên
            var sv = await _context.Sinhviens.FirstOrDefaultAsync(s => s.Mataikhoan == maTaiKhoan);
            if (sv == null) return NotFound("Không tìm thấy sinh viên");

            // 2. Lấy danh sách phiếu mượn (BỎ Include Phieutras để code nhẹ hơn)
            var listPhieuMuon = await _context.Phieumuons
                .Include(pm => pm.Chitietphieumuons)
                    .ThenInclude(ct => ct.MasachNavigation)
                .Where(pm => pm.Masv == sv.Masv)
                .OrderByDescending(pm => pm.Ngaylapphieumuon)
                .ToListAsync();

            var result = new List<LichSuMuonDto>();

            foreach (var pm in listPhieuMuon)
            {
                // --- SỬA ĐOẠN NÀY: TÍNH TỔNG TIỀN PHẠT TRỰC TIẾP TỪ DB ---
                // Tìm tất cả phiếu trả của phiếu mượn này và cộng tổng tiền phạt lại
                double tongTienPhat = await _context.Phieutras
                    .Where(pt => pt.Mapm == pm.Mapm)
                    .SumAsync(pt => pt.Tongtienphat ?? 0);
                // ---------------------------------------------------------

                foreach (var ct in pm.Chitietphieumuons)
                {
                    // Logic tính trạng thái (Giữ nguyên hoặc tinh chỉnh)
                    // Nếu DB đã ghi Quá hạn thì ưu tiên hiển thị Quá hạn
                    string status = pm.Trangthai;

                    // Nếu muốn logic hiển thị thông minh hơn:
                    if (status == "Đang mượn")
                    {
                        DateOnly hanTra = ct.Hantra ?? pm.Hantra;
                        if (hanTra < DateOnly.FromDateTime(DateTime.Now)) status = "Quá hạn";
                    }

                    result.Add(new LichSuMuonDto
                    {
                        MaPhieu = pm.Mapm,
                        MaSach = ct.MasachNavigation.Masach,
                        TenSach = ct.MasachNavigation.Tensach,
                        HinhAnh = ct.MasachNavigation.Hinhanh,
                        GiaMuon = ct.MasachNavigation.Giamuon,
                        NgayMuon = pm.Ngaylapphieumuon.ToDateTime(TimeOnly.MinValue),
                        HanTra = pm.Hantra.ToDateTime(TimeOnly.MinValue),

                        // Gán trạng thái đã xử lý
                        TrangThai = status,

                        // Gán tổng tiền phạt vừa tính được
                        TienPhat = tongTienPhat
                    });
                }
            }

            return Ok(result);
        }

        // --- ENDPOINT 4: Gia hạn sách ---
        [HttpPost("Extend/{mapm}")]
        public async Task<IActionResult> ExtendLoan(int mapm, [FromBody] ExtendRequestDto request)
        {
            var chiTiet = await _context.Chitietphieumuons
                .FirstOrDefaultAsync(ct => ct.Mapm == mapm && ct.Masach == request.MaSach);

            if (chiTiet == null) return NotFound(new { success = false, message = "Không tìm thấy sách." });

            DateOnly hanTraCu = chiTiet.Hantra ?? DateOnly.FromDateTime(DateTime.Now);
            DateOnly hanTraMoi = DateOnly.FromDateTime(request.NgayHenTraMoi);

            if (hanTraMoi <= hanTraCu)
                return BadRequest(new { success = false, message = "Ngày gia hạn phải sau hạn trả cũ." });

            if ((chiTiet.Solangiahan ?? 0) >= 2)
                return BadRequest(new { success = false, message = "Đã hết lượt gia hạn (Tối đa 2 lần)." });

            chiTiet.Hantra = hanTraMoi;
            chiTiet.Solangiahan = (chiTiet.Solangiahan ?? 0) + 1;

            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = "Gia hạn thành công!" });
        }
    }
}