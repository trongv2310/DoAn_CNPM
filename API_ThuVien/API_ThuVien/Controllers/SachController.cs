using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using API_ThuVien.Models;

namespace API_ThuVien.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class SachController : ControllerBase
    {
        private readonly ThuVienDbContext _context;

        public SachController(ThuVienDbContext context)
        {
            _context = context;
        }

        // GET: api/Sach
        [HttpGet]
        public async Task<IActionResult> GetSaches()
        {
            // Dùng Select để chỉ lấy các trường cần thiết và lấy tên tác giả từ bảng liên kết
            var saches = await _context.Saches
                .Include(s => s.MatgNavigation) // Join bảng Tác giả
                .Select(s => new
                {
                    s.Masach,
                    s.Tensach,
                    s.Hinhanh,
                    s.Giamuon,
                    s.Soluongton,
                    s.Theloai, // Lấy thể loại
                    s.Mota,
                    s.Matg,
                    s.Manxb,
                    s.Trangthai,
                    TenTacGia = s.MatgNavigation.Tentg, // Lấy tên tác giả
                    TenNxb = s.ManxbNavigation.Tennxb
                })
                .ToListAsync();

            return Ok(saches);
        }

        // GET: api/Sach/5
        [HttpGet("{id}")]
        public async Task<ActionResult<Sach>> GetSach(int id)
        {
            var sach = await _context.Saches.FindAsync(id);

            if (sach == null)
            {
                return NotFound();
            }

            return sach;
        }

        // PUT: api/Sach/5
        [HttpPut("{id}")]
        public async Task<IActionResult> PutSach(int id, [FromForm] Sach sachInput, IFormFile? fileAnh)
        {
            // 1. Lấy sách cũ từ Database lên (Biến này ĐANG ĐƯỢC TRACKING)
            var existingSach = await _context.Saches.FindAsync(id);

            if (existingSach == null)
            {
                return NotFound();
            }

            // 2. Cập nhật thủ công các trường dữ liệu từ Client gửi lên vào sách cũ
            // (Làm cách này để tránh lỗi "Tracking" của Entity Framework)
            existingSach.Tensach = sachInput.Tensach;
            existingSach.Matg = sachInput.Matg;
            existingSach.Manxb = sachInput.Manxb;
            existingSach.Theloai = sachInput.Theloai;
            existingSach.Mota = sachInput.Mota;
            existingSach.Giamuon = sachInput.Giamuon;
            existingSach.Soluongton = sachInput.Soluongton;

            // Lưu ý: Nếu có trường TrangThai thì cập nhật luôn, ví dụ:
            // existingSach.Trangthai = sachInput.Trangthai;

            // 3. Xử lý file ảnh (Nếu có ảnh mới gửi lên)
            if (fileAnh != null && fileAnh.Length > 0)
            {
                // Tạo tên file mới
                var fileName = $"{Guid.NewGuid()}{Path.GetExtension(fileAnh.FileName)}";
                var uploadPath = Path.Combine(Directory.GetCurrentDirectory(), "images");

                if (!Directory.Exists(uploadPath)) Directory.CreateDirectory(uploadPath);

                var filePath = Path.Combine(uploadPath, fileName);
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await fileAnh.CopyToAsync(stream);
                }

                // Cập nhật tên ảnh vào sách cũ
                existingSach.Hinhanh = fileName;
            }
            // Nếu không gửi ảnh mới thì giữ nguyên ảnh cũ (không làm gì cả)

            // 4. Lưu thay đổi
            try
            {
                // Vì existingSach đã được track từ FindAsync, chỉ cần gọi SaveChanges
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!SachExists(id)) return NotFound();
                else throw;
            }

            return NoContent();
        }


        // POST: api/Sach
        [HttpPost]
        public async Task<ActionResult<Sach>> PostSach([FromForm] Sach sach, IFormFile? fileAnh)
        {
            // 1. Xử lý lưu file ảnh (Nếu có gửi kèm)
            if (fileAnh != null && fileAnh.Length > 0)
            {
                // Tạo tên file ngẫu nhiên để không bị trùng
                var fileName = $"{Guid.NewGuid()}{Path.GetExtension(fileAnh.FileName)}";

                // Đường dẫn: Root_Project/images (Khớp với cấu hình trong Program.cs của bạn)
                var uploadPath = Path.Combine(Directory.GetCurrentDirectory(), "images");

                // Tạo thư mục nếu chưa có (tránh lỗi crash)
                if (!Directory.Exists(uploadPath))
                    Directory.CreateDirectory(uploadPath);

                var filePath = Path.Combine(uploadPath, fileName);

                // Lưu file vật lý
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await fileAnh.CopyToAsync(stream);
                }

                // Cập nhật tên file vào database
                sach.Hinhanh = fileName;
            }

            // 2. Xử lý dữ liệu sách
            // Bỏ qua validate các bảng quan hệ (vì ta chỉ gửi ID như Matg, Manxb)
            ModelState.Remove("MatgNavigation");
            ModelState.Remove("ManxbNavigation");
            // Remove các collection quan hệ nếu có trong model
            ModelState.Remove("Chitietphieumuons");
            ModelState.Remove("Chitietphieunhaps");
            ModelState.Remove("Chitietphieutras");
            ModelState.Remove("Chitietthanhlies");

            if (!ModelState.IsValid)
            {
                return BadRequest(ModelState);
            }

            try
            {
                _context.Saches.Add(sach);
                await _context.SaveChangesAsync();

                return CreatedAtAction("GetSach", new { id = sach.Masach }, sach);
            }
            catch (Exception ex)
            {
                // Ghi log lỗi ra console để bạn dễ debug
                Console.WriteLine($"Lỗi lưu sách: {ex.Message}");
                if (ex.InnerException != null)
                    Console.WriteLine($"Inner Error: {ex.InnerException.Message}");

                return StatusCode(500, new { message = "Lỗi server: " + ex.Message });
            }
        }

        // DELETE: api/Sach/5
        [HttpDelete("{id}")]
        public async Task<IActionResult> DeleteSach(int id)
        {
            var sach = await _context.Saches.FindAsync(id);
            if (sach == null)
            {
                return NotFound();
            }

            _context.Saches.Remove(sach);
            await _context.SaveChangesAsync();

            return NoContent();
        }

        private bool SachExists(int id)
        {
            return _context.Saches.Any(e => e.Masach == id);
        }

        [HttpGet("timkiem")]
        public async Task<ActionResult<IEnumerable<Sach>>> SearchSach([FromQuery] string keyword)
        {
            if (string.IsNullOrEmpty(keyword))
            {
                return await _context.Saches.ToListAsync(); // Trả về hết nếu không có từ khóa
            }

            // Tìm kiếm gần đúng (chứa từ khóa) và không phân biệt hoa thường
            var result = await _context.Saches
                .Where(s => s.Tensach.ToLower().Contains(keyword.ToLower()))
                .ToListAsync();

            if (result == null || result.Count == 0)
            {
                return NotFound(new { message = "Không tìm thấy sách nào." });
            }

            return Ok(result);
        }

    }
}
