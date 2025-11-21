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
                    TenTacGia = s.MatgNavigation.Tentg // Lấy tên tác giả
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
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPut("{id}")]
        public async Task<IActionResult> PutSach(int id, Sach sach)
        {
            if (id != sach.Masach)
            {
                return BadRequest();
            }

            _context.Entry(sach).State = EntityState.Modified;

            try
            {
                await _context.SaveChangesAsync();
            }
            catch (DbUpdateConcurrencyException)
            {
                if (!SachExists(id))
                {
                    return NotFound();
                }
                else
                {
                    throw;
                }
            }

            return NoContent();
        }

        // POST: api/Sach
        // To protect from overposting attacks, see https://go.microsoft.com/fwlink/?linkid=2123754
        [HttpPost]
        public async Task<ActionResult<Sach>> PostSach(Sach sach)
        {
            _context.Saches.Add(sach);
            await _context.SaveChangesAsync();

            return CreatedAtAction("GetSach", new { id = sach.Masach }, sach);
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
