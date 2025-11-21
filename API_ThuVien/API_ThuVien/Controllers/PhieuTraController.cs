using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using API_ThuVien.Models;
using API_ThuVien.DTO;

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

        [HttpPost]
        public async Task<IActionResult> TraSach([FromBody] TraSachDto request)
        {
            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    var pm = await _context.Phieumuons.FindAsync(request.MaPhieuMuon);
                    if (pm == null) return NotFound(new { message = "Phiếu mượn không tồn tại" });

                    var ngayTra = DateOnly.FromDateTime(DateTime.Now);
                    bool isQuaHan = ngayTra > pm.Hantra;

                    // 1. Tạo Phiếu Trả
                    var phieuTra = new Phieutra
                    {
                        Mapm = request.MaPhieuMuon,
                        Matt = 1, // Mặc định thủ thư ID 1 nhận
                        Ngaylapphieutra = ngayTra,
                        Songayquahan = isQuaHan ? (ngayTra.DayNumber - pm.Hantra.DayNumber) : 0
                    };
                    _context.Phieutras.Add(phieuTra);
                    await _context.SaveChangesAsync();

                    // 2. Tạo Chi Tiết Trả
                    var ctMuon = await _context.Chitietphieumuons
                        .FirstOrDefaultAsync(ct => ct.Mapm == request.MaPhieuMuon && ct.Masach == request.MaSach);

                    if (ctMuon == null) return BadRequest(new { message = "Sách không có trong phiếu." });

                    var chiTietTra = new Chitietphieutra
                    {
                        Mapt = phieuTra.Mapt,
                        Masach = request.MaSach,
                        Soluongtra = ctMuon.Soluong,
                        Ngaytra = ngayTra
                    };
                    _context.Chitietphieutras.Add(chiTietTra);

                    // Cập nhật trạng thái phiếu mượn nếu cần
                    if (isQuaHan)
                    {
                        pm.Trangthai = "Đã trả"; // Hoặc Logic xử lý quá hạn
                        _context.Phieumuons.Update(pm);
                    }

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    // Trigger SQL sẽ tự động tính tiền phạt và cộng lại tồn kho

                    return Ok(new { success = true, message = "Trả sách thành công!" });
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