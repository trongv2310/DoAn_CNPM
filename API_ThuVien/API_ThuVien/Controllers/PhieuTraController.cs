// File: Controllers/PhieuTraController.cs
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

        public PhieuTraController(ThuVienDbContext context) { _context = context; }

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
                    // 1. Lấy phiếu & Chi tiết
                    var pm = await _context.Phieumuons.FindAsync(request.MaPhieuMuon);
                    var ctMuon = await _context.Chitietphieumuons.FirstOrDefaultAsync(ct => ct.Mapm == request.MaPhieuMuon && ct.Masach == request.MaSach);
                    if (pm == null || ctMuon == null) return BadRequest(new { message = "Dữ liệu không hợp lệ" });

                    var ngayTra = DateOnly.FromDateTime(DateTime.Now);
                    DateOnly hanTraChuan = ctMuon.Hantra ?? pm.Hantra;
                    bool isQuaHan = ngayTra > hanTraChuan;

                    // 2. BẬT CỜ QUÁ HẠN ĐỂ TRIGGER HOẠT ĐỘNG
                    if (isQuaHan)
                    {
                        pm.Trangthai = "Quá hạn";
                        _context.Phieumuons.Update(pm);
                        await _context.SaveChangesAsync();
                    }

                    // 3. TẠO PHIẾU TRẢ
                    var phieuTra = new Phieutra
                    {
                        Mapm = request.MaPhieuMuon,
                        Matt = 1, // ID Thủ thư demo
                        Ngaylapphieutra = ngayTra,
                        Songayquahan = isQuaHan ? (ngayTra.DayNumber - hanTraChuan.DayNumber) : 0,
                        Tongtienphat = 0
                    };
                    _context.Phieutras.Add(phieuTra);
                    await _context.SaveChangesAsync(); // Có Mapt

                    // 4. TẠO CHI TIẾT TRẢ -> TRIGGER TÍNH TIỀN CHẠY Ở ĐÂY
                    var chiTietTra = new Chitietphieutra
                    {
                        Mapt = phieuTra.Mapt,
                        Masach = request.MaSach,
                        Soluongtra = ctMuon.Soluong,
                        Ngaytra = ngayTra
                    };
                    _context.Chitietphieutras.Add(chiTietTra);
                    await _context.SaveChangesAsync();

                    // 5. CẬP NHẬT TRẠNG THÁI CUỐI CÙNG CỦA PHIẾU
                    // Logic: Nếu còn sách nào chưa trả mà đã quá hạn -> Giữ "Quá hạn". Nếu trả hết -> "Đã trả".

                    var allBooks = await _context.Chitietphieumuons.Where(x => x.Mapm == request.MaPhieuMuon).ToListAsync();
                    bool conSachChuaTra = false;
                    bool conSachQuaHan = false;

                    foreach (var book in allBooks)
                    {
                        var slTra = await _context.Chitietphieutras
                            .Include(x => x.MaptNavigation)
                            .Where(x => x.MaptNavigation.Mapm == request.MaPhieuMuon && x.Masach == book.Masach)
                            .SumAsync(x => x.Soluongtra ?? 0);

                        if (slTra < (book.Soluong ?? 0))
                        {
                            conSachChuaTra = true;
                            if ((book.Hantra ?? pm.Hantra) < DateOnly.FromDateTime(DateTime.Now)) conSachQuaHan = true;
                        }
                    }

                    if (!conSachChuaTra) pm.Trangthai = "Đã trả";
                    else if (conSachQuaHan) pm.Trangthai = "Quá hạn";
                    else pm.Trangthai = "Đang mượn";

                    _context.Phieumuons.Update(pm);
                    await _context.SaveChangesAsync();
                    await transaction.CommitAsync();

                    // Lấy kết quả tiền phạt trả về
                    _context.ChangeTracker.Clear();
                    var ptFinal = await _context.Phieutras.FindAsync(phieuTra.Mapt);

                    return Ok(new { success = true, message = "Trả sách thành công!", tienPhat = ptFinal?.Tongtienphat ?? 0 });
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