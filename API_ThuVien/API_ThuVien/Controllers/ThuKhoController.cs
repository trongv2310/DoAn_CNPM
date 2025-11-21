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

        // API MỚI: Thanh lý sách
        [HttpPost("thanh-ly")]
        public async Task<IActionResult> ThanhLy([FromBody] PhieuThanhLyRequest request)
        {
            if (request.ChiTiet == null || request.ChiTiet.Count == 0)
                return BadRequest("Chưa chọn sách để thanh lý");

            // 1. Kiểm tra tồn kho trước khi thanh lý (Logic nghiệp vụ an toàn)
            foreach (var item in request.ChiTiet)
            {
                var sach = await _context.Saches.FindAsync(item.MaSach);
                if (sach == null) return BadRequest($"Sách ID {item.MaSach} không tồn tại");
                if (sach.Soluongton < item.SoLuong)
                    return BadRequest($"Sách '{sach.Tensach}' chỉ còn {sach.Soluongton}, không đủ để thanh lý {item.SoLuong}");
            }

            // 2. Tạo Phiếu Thanh Lý
            var phieuTL = new Thanhly
            {
                Matk = request.MaThuKho,
                Ngaylap = DateOnly.FromDateTime(DateTime.Now),
                Tongtien = 0 // Trigger sẽ tự tính hoặc tính sau
            };

            _context.Thanhlies.Add(phieuTL);
            await _context.SaveChangesAsync();

            // 3. Tạo Chi Tiết
            foreach (var item in request.ChiTiet)
            {
                var chiTiet = new Chitietthanhly
                {
                    Matl = phieuTL.Matl,
                    Masach = item.MaSach,
                    Soluong = item.SoLuong,
                    Dongia = item.DonGia
                };
                _context.Chitietthanhlies.Add(chiTiet);
            }

            // Lưu thay đổi -> Trigger SQL sẽ chạy để trừ tồn kho
            await _context.SaveChangesAsync();

            return Ok(new { Message = "Thanh lý thành công", MaPhieu = phieuTL.Matl });
        }

        // API: Xem lịch sử nhập hàng của Thủ kho
        [HttpGet("lich-su-nhap/{maThuKho}")]
        public async Task<IActionResult> GetLichSuNhap(int maThuKho)
        {
            var list = await _context.Phieunhaps
                .Where(p => p.Matk == maThuKho)
                .OrderByDescending(p => p.Mapn) // Lấy phiếu mới nhất lên đầu
                .Select(p => new
                {
                    p.Mapn,
                    NgayNhap = p.Ngaynhap.ToString("dd/MM/yyyy"),
                    p.Tongtien,
                    // Lấy luôn chi tiết sách để hiển thị
                    ChiTiet = p.Chitietphieunhaps.Select(ct => new
                    {
                        TenSach = ct.MasachNavigation.Tensach,
                        ct.Soluong,
                        ct.Gianhap,
                        ThanhTien = ct.Thanhtien
                    }).ToList()
                })
                .ToListAsync();

            return Ok(list);
        }

        // --- API MỚI: THỐNG KÊ TÀI CHÍNH (BÁO CÁO) ---
        [HttpGet("thong-ke/{nam}")]
        public async Task<IActionResult> GetThongKeTaiChinh(int nam)
        {
            // 1. Lấy dữ liệu Nhập hàng (Chi tiền)
            var chiPhiNhap = await _context.Phieunhaps
                .Where(p => p.Ngaynhap.Year == nam)
                .GroupBy(p => p.Ngaynhap.Month)
                .Select(g => new { Thang = g.Key, TongTien = g.Sum(x => x.Tongtien) })
                .ToListAsync();

            // 2. Lấy dữ liệu Thanh lý (Thu tiền)
            var thuNhapThanhLy = await _context.Thanhlies
                .Where(p => p.Ngaylap.Year == nam)
                .GroupBy(p => p.Ngaylap.Month)
                .Select(g => new { Thang = g.Key, TongTien = g.Sum(x => x.Tongtien) })
                .ToListAsync();

            // 3. Gộp dữ liệu cho 12 tháng
            var ketQua = new List<object>();
            for (int i = 1; i <= 12; i++)
            {
                decimal chi = chiPhiNhap.FirstOrDefault(x => x.Thang == i)?.TongTien ?? 0;
                decimal thu = thuNhapThanhLy.FirstOrDefault(x => x.Thang == i)?.TongTien ?? 0;

                // Chỉ thêm tháng nào có dữ liệu để báo cáo gọn hơn, hoặc trả về hết
                if (chi > 0 || thu > 0)
                {
                    ketQua.Add(new
                    {
                        Thang = i,
                        TongChi = chi,
                        TongThu = thu,
                        LoiNhuan = thu - chi
                    });
                }
            }

            return Ok(ketQua);
        }
    }
}