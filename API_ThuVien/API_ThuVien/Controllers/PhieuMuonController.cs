using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using API_ThuVien.Models;
using API_ThuVien.DTO; // Using namespace DTO
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
                    // Tìm sinh viên dựa trên Mã Tài Khoản gửi lên
                    var sinhVien = await _context.Sinhviens.FirstOrDefaultAsync(sv => sv.Mataikhoan == request.MaTaiKhoan);
                    if (sinhVien == null) return NotFound(new { success = false, message = "Không tìm thấy thông tin sinh viên." });

                    // 2. KIỂM TRA TỒN KHO
                    foreach (var item in request.SachMuon)
                    {
                        var sach = await _context.Saches.FindAsync(item.MaSach);
                        if (sach == null) throw new Exception($"Sách ID {item.MaSach} không tồn tại.");

                        if (sach.Soluongton < item.SoLuong)
                            throw new Exception($"Sách '{sach.Tensach}' không đủ số lượng (Còn: {sach.Soluongton}).");

                        // Trừ kho (Trigger DB cũng làm việc này, nhưng trừ ở đây để cập nhật trạng thái ngay)
                        sach.Soluongton -= item.SoLuong;
                        if (sach.Soluongton == 0) sach.Trangthai = "Đã hết";
                    }

                    // 3. TẠO PHIẾU MƯỢN
                    // Lấy tạm 1 thủ thư mặc định để gán (vì mượn online chưa ai duyệt ngay)
                    var defaultThuThu = await _context.Thuthus.FirstOrDefaultAsync();
                    var newPhieuMuon = new Phieumuon
                    {
                        Masv = sinhVien.Masv,
                        Matt = defaultThuThu?.Matt ?? 1,
                        Ngaylapphieumuon = ngayHienTai,
                        Hantra = hanTra,
                        Trangthai = "Chờ duyệt"
                    };

                    _context.Phieumuons.Add(newPhieuMuon);
                    await _context.SaveChangesAsync();

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

                    return Ok(new { success = true, message = "Gửi yêu cầu thành công.", maPhieuMuon = newPhieuMuon.Mapm });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    return BadRequest(new { success = false, message = ex.Message });
                }
            }
        }

        // --- ENDPOINT 2: Lịch sử mượn (Fix lỗi Tủ Sách trống) ---
        [HttpGet("History/{maTaiKhoan}")]
        public async Task<IActionResult> GetLichSuMuon(int maTaiKhoan)
        {
            var sv = await _context.Sinhviens.FirstOrDefaultAsync(s => s.Mataikhoan == maTaiKhoan);
            if (sv == null) return NotFound("Không tìm thấy sinh viên");

            var listPhieuMuon = await _context.Phieumuons
                .Include(pm => pm.Chitietphieumuons).ThenInclude(ct => ct.MasachNavigation)
                .Include(pm => pm.Phieutras).ThenInclude(pt => pt.Chitietphieutras)
                .Where(pm => pm.Masv == sv.Masv)
                .OrderByDescending(pm => pm.Ngaylapphieumuon)
                .ToListAsync();

            var result = new List<LichSuMuonDto>();

            foreach (var pm in listPhieuMuon)
            {
                double tienPhatPhieu = pm.Phieutras.Sum(pt => pt.Tongtienphat ?? 0);

                foreach (var ct in pm.Chitietphieumuons)
                {
                    DateOnly hanTraSach = ct.Hantra ?? pm.Hantra;

                    // Logic tính trạng thái hiển thị
                    int soLuongDaTra = pm.Phieutras.SelectMany(pt => pt.Chitietphieutras)
                        .Where(t => t.Masach == ct.Masach).Sum(t => t.Soluongtra ?? 0);

                    string status = "Đang mượn";
                    if (pm.Trangthai == "Chờ duyệt") status = "Chờ duyệt";
                    else if (soLuongDaTra >= ct.Soluong) status = "Đã trả";
                    else if (hanTraSach < DateOnly.FromDateTime(DateTime.Now)) status = "Quá hạn";

                    result.Add(new LichSuMuonDto
                    {
                        MaPhieu = pm.Mapm,
                        MaSach = ct.MasachNavigation.Masach,
                        TenSach = ct.MasachNavigation.Tensach,
                        HinhAnh = ct.MasachNavigation.Hinhanh,
                        GiaMuon = ct.MasachNavigation.Giamuon,
                        NgayMuon = pm.Ngaylapphieumuon.ToDateTime(TimeOnly.MinValue),
                        HanTra = hanTraSach.ToDateTime(TimeOnly.MinValue),
                        TrangThai = status,
                        TienPhat = tienPhatPhieu
                    });
                }
            }
            return Ok(result);
        }

        // --- ENDPOINT 3: Gia hạn sách ---
        [HttpPost("Extend/{mapm}")]
        public async Task<IActionResult> ExtendLoan(int mapm, [FromBody] ExtendRequestDto request)
        {
            var chiTiet = await _context.Chitietphieumuons
                .FirstOrDefaultAsync(ct => ct.Mapm == mapm && ct.Masach == request.MaSach);

            if (chiTiet == null) return NotFound(new { success = false, message = "Không tìm thấy sách." });

            DateOnly hanTraCu = chiTiet.Hantra ?? DateOnly.FromDateTime(DateTime.Now);
            DateOnly hanTraMoi = DateOnly.FromDateTime(request.NgayHenTraMoi);

            if (hanTraMoi <= hanTraCu)
                return BadRequest(new { success = false, message = "Ngày gia hạn không hợp lệ." });

            if ((chiTiet.Solangiahan ?? 0) >= 2)
                return BadRequest(new { success = false, message = "Đã hết lượt gia hạn." });

            chiTiet.Hantra = hanTraMoi;
            chiTiet.Solangiahan = (chiTiet.Solangiahan ?? 0) + 1;

            await _context.SaveChangesAsync();
            return Ok(new { success = true, message = "Gia hạn thành công!" });
        }
    }
}