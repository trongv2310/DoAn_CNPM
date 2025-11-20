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
            public List<SachMuonDto> SachMuon { get; set; }
            public DateTime NgayHenTra { get; set; }
        }
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
        public class ExtendRequestDto
        {
            public int MaSach { get; set; }
            public DateTime NgayHenTraMoi { get; set; }
        }

        // --- ENDPOINT 1: Độc giả gửi yêu cầu mượn ---
        [HttpPost]
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
                        Matt = defaultThuThu?.Matt ?? 1,
                        Ngaylapphieumuon = ngayHienTai,
                        Hantra = hanTra,
                        Trangthai = "Chờ duyệt"
                    };

                    _context.Phieumuons.Add(newPhieuMuon);
                    await _context.SaveChangesAsync();

                    // 5. TẠO CHI TIẾT PHIẾU MƯỢN
                    foreach (var item in request.SachMuon)
                    {
                        var chiTiet = new Chitietphieumuon
                        {
                            Mapm = newPhieuMuon.Mapm,
                            Masach = item.MaSach,
                            Soluong = item.SoLuong,
                            // Gán mặc định hạn trả của sách bằng hạn trả của phiếu
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
                        message = "Gửi yêu cầu mượn sách thành công.",
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

                    // Cập nhật trạng thái
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

        // --- ENDPOINT 3: Lịch sử mượn (Xử lý trả riêng & gia hạn riêng) ---
        [HttpGet("History/{maTaiKhoan}")]
        public async Task<IActionResult> GetLichSuMuon(int maTaiKhoan)
        {
            // 1. Tìm sinh viên
            var sv = await _context.Sinhviens.FirstOrDefaultAsync(s => s.Mataikhoan == maTaiKhoan);
            if (sv == null) return NotFound("Không tìm thấy sinh viên");

            // 2. Lấy danh sách phiếu mượn
            var listPhieuMuon = await _context.Phieumuons
                .Include(pm => pm.Chitietphieumuons)
                    .ThenInclude(ct => ct.MasachNavigation)
                .Include(pm => pm.Phieutras)
                    .ThenInclude(pt => pt.Chitietphieutras)
                .Where(pm => pm.Masv == sv.Masv)
                .OrderByDescending(pm => pm.Ngaylapphieumuon)
                .ToListAsync();

            var result = new List<LichSuMuonDto>();

            foreach (var pm in listPhieuMuon)
            {
                // Tính tổng tiền phạt của cả phiếu
                double tienPhatPhieu = pm.Phieutras.Sum(pt => pt.Tongtienphat ?? 0);

                foreach (var ct in pm.Chitietphieumuons)
                {
                    // --- XÁC ĐỊNH HẠN TRẢ CỤ THỂ CỦA SÁCH ---
                    // Nếu cột Hantra trong ChiTiet là null thì lấy Hantra của Phiếu Mượn
                    DateOnly hanTraSach = ct.Hantra ?? pm.Hantra;

                    // --- TÍNH TRẠNG THÁI RIÊNG ---
                    // 1. Tính tổng số lượng ĐÃ TRẢ của đầu sách này
                    int soLuongDaTra = pm.Phieutras
                        .SelectMany(pt => pt.Chitietphieutras)
                        .Where(ctpt => ctpt.Masach == ct.Masach)
                        .Sum(ctpt => ctpt.Soluongtra ?? 0);

                    // 2. Lấy số lượng ĐÃ MƯỢN
                    int soLuongMuon = ct.Soluong ?? 0;

                    // 3. Xác định trạng thái hiển thị
                    string trangThaiHienThi;

                    if (soLuongDaTra >= soLuongMuon)
                    {
                        trangThaiHienThi = "Đã trả";
                    }
                    else
                    {
                        // So sánh hạn trả RIÊNG của sách với ngày hiện tại
                        if (hanTraSach < DateOnly.FromDateTime(DateTime.Now))
                        {
                            trangThaiHienThi = "Quá hạn";
                        }
                        else
                        {
                            // Nếu phiếu cha là "Chờ duyệt" thì sách con cũng là "Chờ duyệt"
                            // Nếu phiếu cha là "Đang mượn" hoặc "Thiếu" thì sách con là "Đang mượn"
                            if (pm.Trangthai == "Chờ duyệt")
                                trangThaiHienThi = "Chờ duyệt";
                            else
                                trangThaiHienThi = "Đang mượn";
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

                        // QUAN TRỌNG: Trả về hạn trả riêng của từng cuốn sách
                        HanTra = hanTraSach.ToDateTime(TimeOnly.MinValue),

                        TrangThai = trangThaiHienThi,
                        TienPhat = tienPhatPhieu
                    });
                }
            }

            return Ok(result);
        }

        // --- ENDPOINT 4: Gia hạn sách (Cập nhật Hạn trả riêng cho từng sách) ---
        [HttpPost("Extend/{mapm}")]
        public async Task<IActionResult> ExtendLoan(int mapm, [FromBody] ExtendRequestDto request)
        {
            // 1. Tìm chi tiết phiếu mượn cụ thể
            var chiTiet = await _context.Chitietphieumuons
                .Include(ct => ct.MapmNavigation)
                .FirstOrDefaultAsync(ct => ct.Mapm == mapm && ct.Masach == request.MaSach);

            if (chiTiet == null) return NotFound(new { success = false, message = "Không tìm thấy sách này trong phiếu mượn." });

            // 2. Kiểm tra hạn trả hiện tại của CUỐN SÁCH ĐÓ
            DateOnly hanTraCu = chiTiet.Hantra ?? chiTiet.MapmNavigation.Hantra;
            DateOnly hanTraMoi = DateOnly.FromDateTime(request.NgayHenTraMoi);

            // Kiểm tra quá khứ
            if (hanTraMoi <= hanTraCu)
                return BadRequest(new { success = false, message = "Ngày gia hạn phải sau ngày hạn trả hiện tại." });

            // Kiểm tra giới hạn 30 ngày
            if (hanTraMoi > hanTraCu.AddDays(30))
                return BadRequest(new { success = false, message = "Chỉ được gia hạn tối đa thêm 30 ngày." });

            // 3. Kiểm tra số lần gia hạn riêng của sách
            int soLanDaGiaHan = chiTiet.Solangiahan ?? 0;
            if (soLanDaGiaHan >= 2)
                return BadRequest(new { success = false, message = "Sách này đã hết lượt gia hạn (Tối đa 2 lần)." });

            // 4. Cập nhật
            chiTiet.Hantra = hanTraMoi;
            chiTiet.Solangiahan = soLanDaGiaHan + 1;

            _context.Chitietphieumuons.Update(chiTiet);
            await _context.SaveChangesAsync();

            return Ok(new { success = true, message = $"Gia hạn sách thành công đến ngày {chiTiet.Hantra:dd/MM/yyyy}!" });
        }
    }
}