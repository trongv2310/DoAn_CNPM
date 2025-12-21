using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using API_ThuVien.Models;

namespace API_ThuVien.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class TacGiaController : ControllerBase
    {
        private readonly ThuVienDbContext _context;
        public TacGiaController(ThuVienDbContext context) { _context = context; }

        [HttpGet]
        public async Task<IActionResult> GetTacGias()
        {
            // Trả về danh sách tác giả gồm Matg và Tentg
            return Ok(await _context.Tacgia.Select(t => new { t.Matg, t.Tentg }).ToListAsync());
        }
    }
}