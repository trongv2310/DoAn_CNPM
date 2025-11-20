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

                    // --- Logic cập nhật trạng thái để tính phạt ---
                    var ngayTraThucTe = DateOnly.FromDateTime(DateTime.Now);

                    // Lưu ý: Nên lấy Hantra từ bảng ChiTietPhieuMuon nếu đã tách hạn trả riêng
                    // Nhưng ở đây tạm thời dùng logic cũ của bạn để tránh lỗi biên dịch nếu chưa update model
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
                    // Trigger TG_CAPNHATSLTONCUASACH_CTPT cũng sẽ chạy tại đây để cộng lại số lượng sách
                    await _context.SaveChangesAsync();

                    // 4. Cập nhật lại trạng thái cuối cùng (Nếu cần)
                    if (isQuaHan)
                    {
                        pm.Trangthai = "Đã trả";
                        _context.Phieumuons.Update(pm);
                    }

                    // --- ĐÃ XÓA: PHẦN CẬP NHẬT TỒN KHO SÁCH ---
                    // Lý do: Trigger TG_CAPNHATSLTONCUASACH_CTPT trong SQL Server đã tự động cộng lại số lượng tồn
                    // khi insert vào bảng CHITIETPHIEUTRA. Nếu để lại code C# này sẽ bị cộng 2 lần.

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