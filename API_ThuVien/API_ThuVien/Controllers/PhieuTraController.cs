using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using API_ThuVien.Models;

namespace API_ThuVien.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class PhieuTraController : ControllerBase
    {
        private readonly ThuVienDbContext _context;

        public PhieuTraController(ThuVienDbContext context)
        {
            _context = context;
        }

        public class TraSachDto
        {
            public int MaPhieuMuon { get; set; }
            public int MaSach { get; set; }
        }

        [HttpPost]
        public async Task<IActionResult> TraSach([FromBody] TraSachDto request)
        {
            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    // 1. Lấy phiếu mượn và chi tiết sách cần trả
                    var pm = await _context.Phieumuons.FindAsync(request.MaPhieuMuon);
                    if (pm == null) return NotFound(new { message = "Phiếu không tồn tại" });

                    var ctMuon = await _context.Chitietphieumuons
                        .FirstOrDefaultAsync(ct => ct.Mapm == request.MaPhieuMuon && ct.Masach == request.MaSach);

                    if (ctMuon == null) return BadRequest(new { message = "Sách không có trong phiếu này." });

                    var ngayTra = DateOnly.FromDateTime(DateTime.Now);
                    DateOnly hanTraChuan = ctMuon.Hantra ?? pm.Hantra;
                    bool isQuaHan = ngayTra > hanTraChuan;

                    // --- BƯỚC 1: BẬT CỜ "QUÁ HẠN" ĐỂ TRIGGER TÍNH TIỀN ---
                    // Trigger của bạn: WHEN PM.TRANGTHAI LIKE N'%Quá hạn%' -> Tính tiền
                    if (isQuaHan)
                    {
                        if (pm.Trangthai != "Quá hạn")
                        {
                            pm.Trangthai = "Quá hạn";
                            _context.Phieumuons.Update(pm);
                            await _context.SaveChangesAsync(); // Lưu ngay để DB cập nhật trạng thái
                        }
                    }

                    // --- BƯỚC 2: TẠO PHIẾU TRẢ (HEADER) ---
                    var phieuTra = new Phieutra
                    {
                        Mapm = request.MaPhieuMuon,
                        Matt = 1, // ID Thủ thư (nên lấy từ Token)
                        Ngaylapphieutra = ngayTra,
                        Songayquahan = isQuaHan ? (ngayTra.DayNumber - hanTraChuan.DayNumber) : 0,
                        Tongtienphat = 0 // Để 0, Trigger sẽ tự update sau
                    };
                    _context.Phieutras.Add(phieuTra);
                    await _context.SaveChangesAsync(); // Lưu để có Mapt

                    // --- BƯỚC 3: TẠO CHI TIẾT TRẢ (DETAIL) ---
                    var chiTietTra = new Chitietphieutra
                    {
                        Mapt = phieuTra.Mapt,
                        Masach = request.MaSach,
                        Soluongtra = ctMuon.Soluong,
                        Ngaytra = ngayTra
                    };
                    _context.Chitietphieutras.Add(chiTietTra);

                    // KHI LƯU DÒNG NÀY: Trigger TG_CAPNHATTIENPHAT_PT sẽ chạy
                    // Nó thấy PM.TRANGTHAI="Quá hạn" => Tính tiền và Update vào PHIEUTRA
                    await _context.SaveChangesAsync();

                    // --- BƯỚC 4: CẬP NHẬT TRẠNG THÁI CUỐI CÙNG ---

                    // Tính tổng sách đã mượn
                    var tongSoLuongMuon = await _context.Chitietphieumuons
                        .Where(ct => ct.Mapm == request.MaPhieuMuon)
                        .SumAsync(ct => ct.Soluong ?? 0);

                    // Tính tổng sách đã trả (bao gồm lần này)
                    var tongSoLuongDaTra = await _context.Chitietphieutras
                        .Include(ct => ct.MaptNavigation)
                        .Where(ct => ct.MaptNavigation.Mapm == request.MaPhieuMuon)
                        .SumAsync(ct => ct.Soluongtra ?? 0);

                    // Nếu đã trả đủ => Set "Đã trả"
                    if (tongSoLuongDaTra >= tongSoLuongMuon)
                    {
                        pm.Trangthai = "Đã trả";
                    }
                    else
                    {
                        // Nếu chưa trả hết:
                        // Reset về "Đang mượn" để giao diện không bị đỏ lòm nếu người dùng muốn trả sách khác
                        // Lần trả sau sẽ tự động check lại Quá hạn ở Bước 1 nếu cần
                        pm.Trangthai = "Đang mượn";
                    }

                    _context.Phieumuons.Update(pm);
                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    // Reload để lấy số tiền phạt chính xác từ Trigger
                    _context.ChangeTracker.Clear();
                    var phieuTraFinal = await _context.Phieutras.FindAsync(phieuTra.Mapt);

                    return Ok(new
                    {
                        success = true,
                        message = isQuaHan
                            ? $"Trả sách thành công (Quá hạn {phieuTra.Songayquahan} ngày). Phạt: {phieuTraFinal?.Tongtienphat ?? 0}đ"
                            : "Trả sách thành công!",
                        tienPhat = phieuTraFinal?.Tongtienphat ?? 0,
                        trangThaiPhieu = pm.Trangthai
                    });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    return BadRequest(new { success = false, message = "Lỗi: " + ex.Message });
                }
            }
        }
    }
}