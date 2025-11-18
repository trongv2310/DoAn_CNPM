using Microsoft.AspNetCore.Mvc;
using API_ThuVien.Models;
using API_ThuVien.DTO; // Nhớ using DTO
using Microsoft.EntityFrameworkCore;

namespace API_ThuVien.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class ThuKhoController : ControllerBase
    {
        private readonly ThuVienDbContext _context;

        public ThuKhoController(ThuVienDbContext context)
        {
            _context = context;
        }

        // API: Nhập hàng
        [HttpPost("nhap-hang")]
        public async Task<IActionResult> NhapHang([FromBody] PhieuNhapRequest request)
        {
            if (request.ChiTiet == null || request.ChiTiet.Count == 0)
                return BadRequest("Chưa chọn sách để nhập");

            // 1. Tạo Phiếu Nhập (Master)
            var phieuNhap = new Phieunhap
            {
                Matk = request.MaThuKho,
                Ngaynhap = DateOnly.FromDateTime(DateTime.Now),
                Tongtien = 0 // Trigger SQL sẽ tự tính lại sau
            };

            _context.Phieunhaps.Add(phieuNhap);
            await _context.SaveChangesAsync(); // Lưu để lấy Mapn (ID tự tăng)

            // 2. Tạo Chi Tiết Phiếu Nhập (Detail)
            foreach (var item in request.ChiTiet)
            {
                var chiTiet = new Chitietphieunhap
                {
                    Mapn = phieuNhap.Mapn,
                    Masach = item.MaSach,
                    Soluong = item.SoLuong,
                    Gianhap = item.GiaNhap
                };
                _context.Chitietphieunhaps.Add(chiTiet);
            }

            await _context.SaveChangesAsync();
            return Ok(new { Message = "Nhập hàng thành công", MaPhieu = phieuNhap.Mapn });
        }
    }
}