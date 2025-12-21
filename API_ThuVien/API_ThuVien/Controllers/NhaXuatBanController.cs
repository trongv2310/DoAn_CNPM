using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using API_ThuVien.Models;

namespace API_ThuVien.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class NhaXuatBanController : ControllerBase
    {
        private readonly ThuVienDbContext _context;
        public NhaXuatBanController(ThuVienDbContext context) { _context = context; }

        [HttpGet]
        public async Task<IActionResult> GetNXBs()
        {
            // Trả về danh sách NXB gồm Manxb và Tennxb
            return Ok(await _context.Nhaxuatbans.Select(n => new { n.Manxb, n.Tennxb }).ToListAsync());
        }
    }
}