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
                    if (pm == null) return NotFound(new { message = "Phiếu không tồn tại" });

                    var ngayTra = DateOnly.FromDateTime(DateTime.Now);
                    bool isQuaHan = ngayTra > pm.Hantra;

                    // --- BƯỚC QUAN TRỌNG CHO TRIGGER ---
                    // Nếu quá hạn, phải set trạng thái thành "Quá hạn" TRƯỚC KHI thêm chi tiết trả
                    // để Trigger tính tiền phạt (vì trigger check trạng thái PM.TRANGTHAI)
                    if (isQuaHan)
                    {
                        pm.Trangthai = "Quá hạn";
                        _context.Phieumuons.Update(pm);
                        await _context.SaveChangesAsync(); // Lưu ngay để DB nhận diện
                    }

                    // 2. Tạo Phiếu Trả
                    var phieuTra = new Phieutra
                    {
                        Mapm = request.MaPhieuMuon,
                        Matt = 1,
                        Ngaylapphieutra = ngayTra,
                        Songayquahan = isQuaHan ? (ngayTra.DayNumber - pm.Hantra.DayNumber) : 0,
                        Tongtienphat = 0 // Để 0, Trigger sẽ tự tính và update lại
                    };
                    _context.Phieutras.Add(phieuTra);
                    await _context.SaveChangesAsync();

                    // 3. Tạo Chi Tiết Trả
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

                    // --- KÍCH HOẠT TRIGGER ---
                    // Khi lưu dòng này, Trigger TG_CAPNHATTIENPHAT_PT sẽ chạy
                    // Nó sẽ thấy PM.TRANGTHAI = "Quá hạn" -> Tính tiền -> Update vào PHIEUTRA
                    await _context.SaveChangesAsync();

                    // 4. Cập nhật trạng thái cuối cùng (Nếu cần)
                    // Nếu trả hết sách, chuyển thành "Đã trả".
                    // Ở đây ta đơn giản hóa: Cứ trả là coi như xong -> "Đã trả"
                    pm.Trangthai = "Đã trả";
                    _context.Phieumuons.Update(pm);

                    // 5. Cộng tồn kho (Thủ công vì bạn đã xóa trigger kho)
                    var sach = await _context.Saches.FindAsync(request.MaSach);
                    if (sach != null)
                    {
                        sach.Soluongton += (ctMuon.Soluong ?? 0);
                        // Trigger TG_TRANGTHAI_SACH sẽ lo việc set "Có sẵn"
                        _context.Saches.Update(sach);
                    }

                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    // 6. Lấy lại tiền phạt từ DB để trả về App
                    await _context.Entry(phieuTra).ReloadAsync();

                    return Ok(new
                    {
                        success = true,
                        message = "Trả sách thành công!",
                        ngayTra = phieuTra.Ngaylapphieutra,
                        tienPhat = phieuTra.Tongtienphat // Số tiền do trigger tính
                    });
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