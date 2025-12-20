using API_ThuVien.DTO;
using API_ThuVien.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Build.Tasks;
using Microsoft.EntityFrameworkCore;

namespace API_ThuVien.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TuongTacController : ControllerBase
    {
        private readonly ThuVienDbContext _context;

        public TuongTacController(ThuVienDbContext context)
        {
            _context = context;
        }

        // ================== 1. HỎI ĐÁP ==================

        // Gửi câu hỏi mới
        [HttpPost("gui-cau-hoi")]
        public async Task<IActionResult> GuiCauHoi([FromBody] HoiDapRequest req)
        {
            var hd = new Hoidap
            {
                Masv = req.MaSinhVien,
                Cauhoi = req.CauHoi,
                Trangthai = "Chờ trả lời",
                Thoigianhoi = DateTime.Now
            };
            _context.Hoidaps.Add(hd);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Đã gửi câu hỏi thành công!" });
        }

        // Xem lịch sử hỏi đáp của sinh viên đó
        [HttpGet("lich-su-hoi-dap/{maSV}")]
        public async Task<IActionResult> GetLichSuHoiDap(int maSV)
        {
            var list = await _context.Hoidaps
                .Where(h => h.Masv == maSV)
                .OrderByDescending(h => h.Thoigianhoi)
                .Select(h => new {
                    h.Cauhoi,
                    h.Traloi,
                    h.Trangthai,
                    ThoiGian = h.Thoigianhoi.HasValue ? h.Thoigianhoi.Value.ToString("dd/MM/yyyy HH:mm") : ""
                })
                .ToListAsync();
            return Ok(list);
        }

        // --- MỚI: API CHO THỦ THƯ TRẢ LỜI CÂU HỎI ---

        // [GET] Lấy tất cả câu hỏi (Cho Thủ thư xem để trả lời)
        [HttpGet("all-questions")]
        public async Task<IActionResult> GetAllQuestions()
        {
            var list = await _context.Hoidaps
                .Include(h => h.MasvNavigation) // Join để lấy tên sinh viên
                .OrderByDescending(h => h.Thoigianhoi)
                .Select(h => new
                {
                    h.Mahoidap,
                    TenSinhVien = h.MasvNavigation.Hovaten,
                    h.Cauhoi,
                    h.Traloi,
                    h.Trangthai,
                    ThoiGian = h.Thoigianhoi.HasValue ? h.Thoigianhoi.Value.ToString("dd/MM/yyyy HH:mm") : ""
                })
                .ToListAsync();
            return Ok(list);
        }

        // Class DTO nhận dữ liệu trả lời
        public class TraLoiRequest
        {
            public int MaHoiDap { get; set; }
            public int MaThuThu { get; set; }
            public string NoiDungTraLoi { get; set; }
        }

        // [POST] Thủ thư gửi câu trả lời
        [HttpPost("tra-loi")]
        public async Task<IActionResult> TraLoiCauHoi([FromBody] TraLoiRequest req)
        {
            var hd = await _context.Hoidaps.FindAsync(req.MaHoiDap);
            if (hd == null) return NotFound("Không tìm thấy câu hỏi");

            hd.Traloi = req.NoiDungTraLoi;
            hd.Matt = req.MaThuThu; // Lưu ID thủ thư đã trả lời
            hd.Thoigiantraloi = DateTime.Now;
            hd.Trangthai = "Đã trả lời";

            await _context.SaveChangesAsync();
            return Ok(new { Message = "Đã gửi câu trả lời thành công" });
        }

        // ====================================================


        // ================== 2. GÓP Ý ==================

        // Gửi góp ý
        [HttpPost("gui-gop-y")]
        public async Task<IActionResult> GuiGopY([FromBody] GopYRequest req)
        {
            var gy = new Gopy
            {
                Masv = req.MaSinhVien,
                Noidung = req.NoiDung,
                Loaigopy = req.LoaiGopY,
                Trangthai = "Mới tiếp nhận",
                Thoigiangui = DateTime.Now
            };
            _context.Gopies.Add(gy);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Cảm ơn bạn đã góp ý!" });
        }

        // ================== 3. ĐÁNH GIÁ SÁCH ==================

        // Xem các đánh giá gần đây (của tất cả mọi người - Community Feed)
        [HttpGet("danh-gia-moi")]
        public async Task<IActionResult> GetDanhGiaMoi()
        {
            var list = await _context.Danhgiasaches
                .Include(d => d.MasachNavigation) // Join bảng Sách
                .Include(d => d.MasvNavigation)   // Join bảng Sinh viên
                .OrderByDescending(d => d.Thoigian)
                .Take(20) // Lấy 20 cái mới nhất
                .Select(d => new DanhGiaHienThiDto
                {
                    TenSach = d.MasachNavigation.Tensach,
                    TenSinhVien = d.MasvNavigation.Hovaten,
                    Diem = d.Diem,
                    NhanXet = d.Nhanxet,
                    NgayDanhGia = d.Thoigian.HasValue ? d.Thoigian.Value.ToString("dd/MM/yyyy") : ""
                })
                .ToListAsync();

            return Ok(list);
        }
        // [POST] Gửi đánh giá cho một cuốn sách
        [HttpPost("gui-danh-gia")]
        public async Task<IActionResult> GuiDanhGia([FromBody] DanhGiaRequest req)
        {
            // Kiểm tra xem sinh viên đã đánh giá sách này chưa (nếu muốn mỗi người chỉ đánh giá 1 lần)
            var exist = await _context.Danhgiasaches
                .FirstOrDefaultAsync(d => d.Masv == req.MaSinhVien && d.Masach == req.MaSach);

            if (exist != null)
            {
                // Nếu đã có thì cập nhật lại
                exist.Diem = req.Diem;
                exist.Nhanxet = req.NhanXet;
                exist.Thoigian = DateTime.Now;
                _context.Danhgiasaches.Update(exist);
                await _context.SaveChangesAsync();
                return Ok(new { Message = "Đã cập nhật đánh giá của bạn!" });
            }

            // Nếu chưa có thì tạo mới
            var dg = new Danhgiasach
            {
                Masach = req.MaSach,
                Masv = req.MaSinhVien,
                Diem = req.Diem,
                Nhanxet = req.NhanXet,
                Thoigian = DateTime.Now
            };

            _context.Danhgiasaches.Add(dg);
            await _context.SaveChangesAsync();
            return Ok(new { Message = "Cảm ơn bạn đã đánh giá sách!" });
        }
        // ================== QUẢN LÝ ĐÁNH GIÁ (CHO THỦ THƯ) ==================

        // [GET] Lấy tất cả đánh giá (Mới nhất lên đầu)
        [HttpGet("quan-ly-danh-gia")]
        public async Task<IActionResult> GetAllDanhGia()
        {
            var list = await _context.Danhgiasaches
                .Include(d => d.MasachNavigation)
                .Include(d => d.MasvNavigation)
                .OrderByDescending(d => d.Thoigian)
                .Select(d => new DanhGiaHienThiDto
                {
                    MaDanhGia = d.Madanhgia, // Map ID vào đây
                    TenSach = d.MasachNavigation.Tensach,
                    TenSinhVien = d.MasvNavigation.Hovaten,
                    Diem = d.Diem,
                    NhanXet = d.Nhanxet,
                    NgayDanhGia = d.Thoigian.HasValue ? d.Thoigian.Value.ToString("dd/MM/yyyy HH:mm") : ""
                })
                .ToListAsync();

            return Ok(list);
        }

        // [DELETE] Xóa một đánh giá vi phạm
        [HttpDelete("xoa-danh-gia/{id}")]
        public async Task<IActionResult> DeleteDanhGia(int id)
        {
            var dg = await _context.Danhgiasaches.FindAsync(id);
            if (dg == null) return NotFound(new { Message = "Không tìm thấy đánh giá này" });

            _context.Danhgiasaches.Remove(dg);
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Đã xóa đánh giá thành công" });
        }

        // Thêm vào trong class TuongTacController

        // [GET] Lấy danh sách đánh giá của một cuốn sách cụ thể
        [HttpGet("danh-gia-sach/{maSach}")]
        public async Task<IActionResult> GetDanhGiaTheoSach(int maSach)
        {
            var list = await _context.Danhgiasaches
                .Where(d => d.Masach == maSach) // Lọc theo mã sách
                .Include(d => d.MasvNavigation) // Join lấy tên SV
                .OrderByDescending(d => d.Thoigian) // Mới nhất lên đầu
                .Select(d => new DanhGiaHienThiDto
                {
                    MaDanhGia = d.Madanhgia,
                    TenSach = d.MasachNavigation.Tensach,
                    TenSinhVien = d.MasvNavigation.Hovaten,
                    Diem = d.Diem,
                    NhanXet = d.Nhanxet,
                    NgayDanhGia = d.Thoigian.HasValue ? d.Thoigian.Value.ToString("dd/MM/yyyy") : ""
                })
                .ToListAsync();

            return Ok(list);
        }
    }
}