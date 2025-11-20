using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using API_ThuVien.Models;
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

        // --- DTO KHỚP VỚI FLUTTER ---
        public class SachMuonDto
        {
            public int MaSach { get; set; }
            public int SoLuong { get; set; }
        }

        public class BorrowRequestDto
        {
            public int MaTaiKhoan { get; set; }
            public List<SachMuonDto> SachMuon { get; set; } // Đã sửa để khớp với Flutter
            public DateTime NgayHenTra { get; set; } // Nhận ngày từ Flutter
        }

        // --- ENDPOINT 1: Độc giả gửi yêu cầu mượn ---
        [HttpPost] // Bỏ chữ "request" để khớp với đường dẫn Flutter (api/PhieuMuon)
        public async Task<IActionResult> CreateBorrowRequest([FromBody] BorrowRequestDto request)
        {
            // 1. VALIDATION CƠ BẢN
            if (request == null || request.SachMuon == null || !request.SachMuon.Any())
            {
                return BadRequest(new { success = false, message = "Dữ liệu không hợp lệ." });
            }

            // 2. VALIDATION NGÀY HẸN TRẢ
            DateOnly ngayHienTai = DateOnly.FromDateTime(DateTime.Now);
            DateOnly hanTra = DateOnly.FromDateTime(request.NgayHenTra);

            if (hanTra <= ngayHienTai)
            {
                return BadRequest(new { success = false, message = "Ngày hẹn trả phải sau ngày hôm nay." });
            }

            // (Tùy chọn) Giới hạn mượn tối đa 30 ngày
            if (hanTra > ngayHienTai.AddDays(30))
            {
                return BadRequest(new { success = false, message = "Chỉ được mượn tối đa 30 ngày." });
            }

            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    var sinhVien = await _context.Sinhviens.FirstOrDefaultAsync(sv => sv.Mataikhoan == request.MaTaiKhoan);
                    if (sinhVien == null) return NotFound(new { success = false, message = "Không tìm thấy thông tin sinh viên." });

                    // 3. KIỂM TRA TỒN KHO & TRỪ KHO
                    // (Logic: Trừ kho ngay khi tạo phiếu Chờ duyệt để giữ chỗ)
                    foreach (var item in request.SachMuon)
                    {
                        var sach = await _context.Saches.FindAsync(item.MaSach);
                        if (sach == null)
                        {
                            throw new Exception($"Sách có mã {item.MaSach} không tồn tại.");
                        }

                        if (sach.Soluongton < item.SoLuong)
                        {
                            throw new Exception($"Sách '{sach.Tensach}' không đủ số lượng (Còn: {sach.Soluongton}, Muốn mượn: {item.SoLuong}).");
                        }

                        // Trừ kho tạm thời
                        sach.Soluongton -= item.SoLuong;
                        if (sach.Soluongton == 0) sach.Trangthai = "Đã hết";
                    }

                    // 4. TẠO PHIẾU MƯỢN
                    var defaultThuThu = await _context.Thuthus.FirstOrDefaultAsync();
                    var newPhieuMuon = new Phieumuon
                    {
                        Masv = sinhVien.Masv,
                        Matt = defaultThuThu?.Matt ?? 1, // Gán tạm thủ thư quản lý
                        Ngaylapphieumuon = ngayHienTai,
                        Hantra = hanTra, // <--- DÙNG NGÀY NGƯỜI DÙNG CHỌN
                        Trangthai = "Chờ duyệt"
                    };

                    _context.Phieumuons.Add(newPhieuMuon);
                    await _context.SaveChangesAsync(); // Lưu để lấy Mapm

                    // 5. TẠO CHI TIẾT PHIẾU MƯỢN
                    foreach (var item in request.SachMuon)
                    {
                        var chiTiet = new Chitietphieumuon
                        {
                            Mapm = newPhieuMuon.Mapm,
                            Masach = item.MaSach,
                            Soluong = item.SoLuong
                        };
                        _context.Chitietphieumuons.Add(chiTiet);
                    }

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    // 6. TRẢ VỀ KẾT QUẢ THÀNH CÔNG + MÃ PHIẾU (Để in hóa đơn)
                    return Ok(new
                    {
                        success = true,
                        message = "Gửi yêu cầu mượn sách thành công.",
                        maPhieuMuon = newPhieuMuon.Mapm
                    });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    // Trả về lỗi JSON chuẩn để Flutter hiển thị
                    return BadRequest(new { success = false, message = ex.Message });
                }
            }
        }

        // --- ENDPOINT 2: Thủ thư duyệt yêu cầu (Đã chỉnh sửa để không reset ngày trả) ---
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

                    // Cập nhật trạng thái
                    phieuMuon.Trangthai = "Đang mượn";
                    phieuMuon.Matt = maThuThuDuyet;

                    // LƯU Ý: Không reset Hantra = DateTime.Now.AddDays(7) nữa 
                    // để tôn trọng ngày hẹn trả mà sinh viên đã chọn.

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

        // DTO cho lịch sử
        public class LichSuMuonDto
        {
            public int MaPhieu { get; set; }
            public int MaSach { get; set; }
            public string TenSach { get; set; }
            public string HinhAnh { get; set; }
            public decimal GiaMuon { get; set; }
            public DateTime NgayMuon { get; set; }
            public DateTime HanTra { get; set; }
            public string TrangThai { get; set; }
            public double TienPhat { get; set; }
        }

        // --- ENDPOINT 3: Lịch sử mượn ---
        [HttpGet("History/{maTaiKhoan}")]
        public async Task<IActionResult> GetLichSuMuon(int maTaiKhoan)
        {
            // 1. Tìm sinh viên
            var sv = await _context.Sinhviens.FirstOrDefaultAsync(s => s.Mataikhoan == maTaiKhoan);
            if (sv == null) return NotFound("Không tìm thấy sinh viên");

            // 2. Lấy danh sách phiếu mượn (Bỏ Include Phieutras đi cho nhẹ)
            var listPhieuMuon = await _context.Phieumuons
                .Include(pm => pm.Chitietphieumuons)
                    .ThenInclude(ct => ct.MasachNavigation)
                .Where(pm => pm.Masv == sv.Masv)
                .OrderByDescending(pm => pm.Ngaylapphieumuon)
                .ToListAsync();

            var result = new List<LichSuMuonDto>();

            foreach (var pm in listPhieuMuon)
            {
                // --- KHẮC PHỤC: TRUY VẤN TRỰC TIẾP BẢNG PHIEUTRA ---
                // Tìm phiếu trả tương ứng với phiếu mượn này
                var phieuTra = await _context.Phieutras
                             .Where(pt => pt.Mapm == pm.Mapm)
                             .OrderByDescending(pt => pt.Mapt) // Lấy phiếu trả mới nhất nếu có nhiều lần trả
                             .FirstOrDefaultAsync();

                // Lấy tiền phạt (Nếu không có phiếu trả thì là 0)
                double tienPhatDB = phieuTra != null ? (double)(phieuTra.Tongtienphat ?? 0) : 0;
                // ---------------------------------------------------

                foreach (var ct in pm.Chitietphieumuons)
                {
                    result.Add(new LichSuMuonDto
                    {
                        MaPhieu = pm.Mapm,
                        MaSach = ct.MasachNavigation.Masach,
                        TenSach = ct.MasachNavigation.Tensach,
                        HinhAnh = ct.MasachNavigation.Hinhanh,
                        GiaMuon = ct.MasachNavigation.Giamuon,
                        NgayMuon = pm.Ngaylapphieumuon.ToDateTime(TimeOnly.MinValue),
                        HanTra = pm.Hantra.ToDateTime(TimeOnly.MinValue),
                        TrangThai = pm.Trangthai,

                        // Gán giá trị vừa tìm được vào đây
                        TienPhat = tienPhatDB
                    });
                }
            }

            return Ok(result);
        }
    }
}