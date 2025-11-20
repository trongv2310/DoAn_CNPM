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
                    // 1. Lấy phiếu mượn
                    var pm = await _context.Phieumuons.FindAsync(request.MaPhieuMuon);
                    if (pm == null) return NotFound(new { message = "Không tìm thấy phiếu mượn" });

                    // --- Logic cập nhật trạng thái để tính phạt (Giữ nguyên) ---
                    var ngayTraThucTe = DateOnly.FromDateTime(DateTime.Now);
                    bool isQuaHan = ngayTraThucTe > pm.Hantra;

                    if (isQuaHan)
                    {
                        pm.Trangthai = "Quá hạn";
                    }
                    else
                    {
                        pm.Trangthai = "Đã trả";
                    }
                    _context.Phieumuons.Update(pm);
                    await _context.SaveChangesAsync();
                    // -----------------------------------------------------------

                    // 2. Tạo Phiếu Trả
                    var phieuTra = new Phieutra
                    {
                        Mapm = request.MaPhieuMuon,
                        Matt = 1,
                        Ngaylapphieutra = ngayTraThucTe,
                        Songayquahan = isQuaHan ? (ngayTraThucTe.DayNumber - pm.Hantra.DayNumber) : 0
                    };
                    _context.Phieutras.Add(phieuTra);
                    await _context.SaveChangesAsync();

                    // 3. Tạo Chi Tiết Trả
                    var ctMuon = await _context.Chitietphieumuons
                        .FirstOrDefaultAsync(ct => ct.Mapm == request.MaPhieuMuon && ct.Masach == request.MaSach);

                    if (ctMuon == null) return BadRequest(new { message = "Sách này không có trong phiếu." });

                    var chiTietTra = new Chitietphieutra
                    {
                        Mapt = phieuTra.Mapt,
                        Masach = request.MaSach,
                        Soluongtra = ctMuon.Soluong,
                        Ngaytra = ngayTraThucTe
                    };
                    _context.Chitietphieutras.Add(chiTietTra);

                    // Trigger tính tiền phạt sẽ chạy tại đây
                    await _context.SaveChangesAsync();

                    // 4. Cập nhật lại trạng thái cuối cùng (Nếu cần)
                    if (isQuaHan)
                    {
                        pm.Trangthai = "Đã trả";
                        _context.Phieumuons.Update(pm);
                    }

                    // 5. Cập nhật tồn kho sách
                    var sach = await _context.Saches.FindAsync(request.MaSach);
                    if (sach != null)
                    {
                        // A. CHỈ CẦN CỘNG SỐ LƯỢNG
                        sach.Soluongton += (ctMuon.Soluong ?? 0);

                        // B. KHÔNG CẦN SET 'Trangthai' THỦ CÔNG NỮA
                        // Trigger TG_TRANGTHAI_SACH sẽ tự động làm việc này:
                        // Nếu Soluongton > 0 -> Nó tự set thành 'Có sẵn'
                        // Nếu Soluongton = 0 -> Nó tự set thành 'Đã hết'

                        _context.Saches.Update(sach);
                    }

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    return Ok(new { success = true, message = isQuaHan ? "Đã trả sách (Có phí phạt quá hạn)." : "Trả sách thành công!" });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    return BadRequest(new { success = false, message = ex.Message });
                }
            }
        }
    }
}