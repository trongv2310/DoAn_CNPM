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

                    // 2. KIỂM TRA TỒN KHO (Chỉ kiểm tra, KHÔNG trừ kho tại đây)
                    foreach (var item in request.SachMuon)
                    {
                        var sach = await _context.Saches.FindAsync(item.MaSach);
                        if (sach == null) throw new Exception($"Sách ID {item.MaSach} không tồn tại.");

                        // Kiểm tra xem hiện tại kho có đủ không để báo lỗi ngay cho người dùng
                        if (sach.Soluongton < item.SoLuong)
                            throw new Exception($"Sách '{sach.Tensach}' hiện không đủ số lượng (Còn: {sach.Soluongton}).");

                        // ĐÃ XÓA: Đoạn code trừ tồn kho ở đây.
                    }

                    // 3. TẠO PHIẾU MƯỢN (TRẠNG THÁI CHỜ DUYỆT)
                    var defaultThuThu = await _context.Thuthus.FirstOrDefaultAsync(); // Có thể null nếu chưa có thủ thư nào
                    var newPhieuMuon = new Phieumuon
                    {
                        Masv = sinhVien.Masv,
                        Matt = defaultThuThu?.Matt ?? 1, // Gán tạm 1 thủ thư mặc định
                        Ngaylapphieumuon = ngayHienTai,
                        Hantra = hanTra,
                        Trangthai = "Chờ duyệt"
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

        // --- ENDPOINT 2: Thủ thư duyệt yêu cầu (ĐÃ SỬA: TRỪ KHO TẠI ĐÂY) ---
        [HttpPost("approve/{mapm}")]
        public async Task<IActionResult> ApproveBorrowRequest(int mapm, [FromQuery] int maThuThuDuyet)
        {
            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    // Phải Include chi tiết để biết sách nào cần trừ
                    var phieuMuon = await _context.Phieumuons
                                            .Include(pm => pm.Chitietphieumuons)
                                            .FirstOrDefaultAsync(p => p.Mapm == mapm);

                    if (phieuMuon == null) return NotFound(new { message = "Không tìm thấy phiếu mượn." });

                    if (phieuMuon.Trangthai != "Chờ duyệt")
                        return BadRequest(new { message = "Phiếu này không ở trạng thái chờ duyệt." });

                    // --- LOGIC MỚI: TRỪ TỒN KHO ---
                    foreach (var ct in phieuMuon.Chitietphieumuons)
                    {
                        var sach = await _context.Saches.FindAsync(ct.Masach);
                        if (sach == null) throw new Exception($"Sách ID {ct.Masach} bị lỗi dữ liệu.");

                        // Kiểm tra lại lần cuối (Race condition check)
                        if (sach.Soluongton < ct.Soluong)
                        {
                            throw new Exception($"Sách '{sach.Tensach}' đã hết hàng trong kho, không thể duyệt phiếu này.");
                        }

                        sach.Soluongton -= (ct.Soluong ?? 0);
                        _context.Saches.Update(sach);
                    }

                    // Cập nhật trạng thái sang Đang mượn
                    phieuMuon.Trangthai = "Đang mượn";
                    phieuMuon.Matt = maThuThuDuyet;

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Ok(new { message = "Duyệt phiếu thành công (Đã trừ tồn kho)." });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    return StatusCode(500, new { message = $"Lỗi: {ex.Message}" });
                }
            }
        }

        // --- ENDPOINT MỚI: Lấy danh sách phiếu chờ duyệt (Cho Thủ thư) ---
        [HttpGet("pending")]
        public async Task<IActionResult> GetPendingRequests()
        {
            var list = await _context.Phieumuons
                .Include(p => p.MasvNavigation) // Lấy tên sinh viên
                .Include(p => p.Chitietphieumuons)
                    .ThenInclude(ct => ct.MasachNavigation) // Lấy tên sách
                .Where(p => p.Trangthai == "Chờ duyệt")
                .OrderBy(p => p.Ngaylapphieumuon)
                .Select(p => new
                {
                    MaPhieu = p.Mapm,
                    TenSinhVien = p.MasvNavigation.Hovaten,
                    NgayMuon = p.Ngaylapphieumuon.ToString("dd/MM/yyyy"),
                    HanTra = p.Hantra.ToString("dd/MM/yyyy"),
                    SachMuon = p.Chitietphieumuons.Select(ct => new {
                        TenSach = ct.MasachNavigation.Tensach,
                        SoLuong = ct.Soluong
                    }).ToList()
                })
                .ToListAsync();

            return Ok(list);
        }

        // --- SỬA LẠI API LẤY LỊCH SỬ ---
        [HttpGet("History/{maTaiKhoan}")]
        public async Task<IActionResult> GetLichSuMuon(int maTaiKhoan)
        {
            var sv = await _context.Sinhviens.FirstOrDefaultAsync(s => s.Mataikhoan == maTaiKhoan);
            if (sv == null) return NotFound("Không tìm thấy sinh viên");

            var listPhieuMuon = await _context.Phieumuons
                .Include(pm => pm.Chitietphieumuons)
                    .ThenInclude(ct => ct.MasachNavigation)
                .Where(pm => pm.Masv == sv.Masv)
                .OrderByDescending(pm => pm.Ngaylapphieumuon)
                .ToListAsync();

            var result = new List<LichSuMuonDto>();
            var today = DateOnly.FromDateTime(DateTime.Now);

            foreach (var pm in listPhieuMuon)
            {
                // Lấy tổng tiền phạt của cả phiếu (nếu có) từ bảng PhieuTra
                double tongTienPhat = await _context.Phieutras
                    .Where(pt => pt.Mapm == pm.Mapm)
                    .SumAsync(pt => pt.Tongtienphat ?? 0);

                foreach (var ct in pm.Chitietphieumuons)
                {
                    // Tính số lượng đã trả
                    var soLuongDaTra = await _context.Chitietphieutras
                        .Include(ctpt => ctpt.MaptNavigation)
                        .Where(ctpt => ctpt.MaptNavigation.Mapm == pm.Mapm && ctpt.Masach == ct.Masach)
                        .SumAsync(ctpt => ctpt.Soluongtra ?? 0);

                    string statusHienThi = pm.Trangthai; // Mặc định lấy trạng thái phiếu cha

                    // LOGIC 1: Nếu đã trả đủ -> "Đã trả"
                    if (soLuongDaTra >= (ct.Soluong ?? 0))
                    {
                        statusHienThi = "Đã trả";
                    }
                    else
                    {
                        // LOGIC 2: Nếu chưa trả -> Kiểm tra hạn
                        DateOnly hanTraSach = ct.Hantra ?? pm.Hantra;

                        if (statusHienThi == "Chờ duyệt")
                        {
                            // Giữ nguyên chờ duyệt
                        }
                        // Nếu hôm nay > Hạn trả -> Ép thành "Quá hạn" (bất kể phiếu cha ghi gì)
                        else if (today > hanTraSach)
                        {
                            statusHienThi = "Quá hạn";
                        }
                        else
                        {
                            statusHienThi = "Đang mượn";
                        }
                    }

                    result.Add(new LichSuMuonDto
                    {
                        MaPhieu = pm.Mapm,
                        MaSach = ct.MasachNavigation.Masach,
                        TenSach = ct.MasachNavigation.Tensach,
                        HinhAnh = ct.MasachNavigation.Hinhanh,
                        GiaMuon = ct.MasachNavigation.Giamuon,
                        NgayMuon = pm.Ngaylapphieumuon.ToDateTime(TimeOnly.MinValue),
                        HanTra = (ct.Hantra ?? pm.Hantra).ToDateTime(TimeOnly.MinValue),
                        TrangThai = statusHienThi, // Trạng thái đã tính toán lại
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

        // DEMO QUÁ HẠN
        // Gọi API này bằng Postman hoặc Swagger: POST /api/PhieuMuon/reset-demo/{mapm}
        [HttpPost("reset-demo/{mapm}")]
        public async Task<IActionResult> ResetDemoData(int mapm)
        {
            // 1. Tìm tất cả phiếu trả liên quan đến phiếu mượn này
            var listPhieuTra = await _context.Phieutras
                .Where(pt => pt.Mapm == mapm)
                .ToListAsync();

            if (listPhieuTra.Any())
            {
                // Lấy danh sách mã phiếu trả
                var listMaPT = listPhieuTra.Select(pt => pt.Mapt).ToList();

                // 2. Xóa Chi tiết phiếu trả (Bảng con)
                var listChiTiet = await _context.Chitietphieutras
                    .Where(ct => listMaPT.Contains(ct.Mapt))
                    .ToListAsync();
                _context.Chitietphieutras.RemoveRange(listChiTiet);

                // 3. Xóa Phiếu trả (Bảng cha)
                _context.Phieutras.RemoveRange(listPhieuTra);
            }

            // 4. Cập nhật lại Phiếu Mượn thành "Quá hạn" & Chỉnh hạn trả về quá khứ
            var pm = await _context.Phieumuons.FindAsync(mapm);
            if (pm != null)
            {
                pm.Trangthai = "Quá hạn";
                // Set hạn trả lùi về 5 ngày trước để chắc chắn nó quá hạn
                pm.Hantra = DateOnly.FromDateTime(DateTime.Now.AddDays(-5));

                // Cập nhật luôn hạn trả trong chi tiết phiếu mượn (nếu có)
                var chiTietMuon = await _context.Chitietphieumuons.Where(ct => ct.Mapm == mapm).ToListAsync();
                foreach (var item in chiTietMuon)
                {
                    item.Hantra = pm.Hantra;
                    item.Solangiahan = 0; // Reset lượt gia hạn
                }
            }

            await _context.SaveChangesAsync();
            return Ok(new { message = $"Đã reset phiếu mượn {mapm} về trạng thái CHƯA TRẢ và QUÁ HẠN thành công!" });
        }
    }
}