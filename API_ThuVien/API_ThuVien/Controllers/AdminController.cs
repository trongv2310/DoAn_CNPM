using API_ThuVien.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient; // Để dùng cho Stored Procedure
using Microsoft.EntityFrameworkCore;
using System.Data;

namespace API_ThuVien.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    // CHÚ Ý: CẦN CÓ FILTER/GUARD ĐỂ ĐẢM BẢO CHỈ ADMIN (MAQUYEN=1) MỚI GỌI ĐƯỢC
    public class AdminController : ControllerBase
    {
        private readonly ThuVienDbContext _context;

        public AdminController(ThuVienDbContext context)
        {
            _context = context;
        }

        // DTO: Request cho việc thêm tài khoản
        public class AddUserRequest
        {
            public string TenDangNhap { get; set; } = null!;
            public string MatKhau { get; set; } = null!;
            public int MaQuyen { get; set; }
            public string HoVaTen { get; set; } = null!;
            public string GioiTinh { get; set; } = null!;
            public DateTime NgaySinh { get; set; }
            public string Sdt { get; set; } = null!;
            public string Email { get; set; } = null!;
        }

        // 1. Lấy danh sách tài khoản (dùng cho chức năng Kiểm tra Hệ thống & Quản lý Tài khoản)
        [HttpGet("users")]
        public async Task<IActionResult> GetAllUsers()
        {
            var users = await _context.Taikhoans
                .Include(t => t.MaquyenNavigation)
                .Select(t => new
                {
                    t.Mataikhoan,
                    t.Tendangnhap,
                    t.Maquyen,
                    TenQuyen = t.MaquyenNavigation.Tenquyen,
                    t.Trangthai
                })
                .ToListAsync();
            return Ok(users);
        }

        // 2. Thêm Tài khoản mới (Dùng Stored Procedure)
        [HttpPost("add-user")]
        public async Task<IActionResult> AddUser([FromBody] AddUserRequest request)
        {
            // Định nghĩa tham số cho Stored Procedure
            var parameters = new[]
            {
                    new SqlParameter("@TenDangNhap", request.TenDangNhap),
                    new SqlParameter("@MatKhau", request.MatKhau),
                    new SqlParameter("@MaQuyen", request.MaQuyen),
                    new SqlParameter("@HoVaTen", request.HoVaTen),
                    new SqlParameter("@GioiTinh", request.GioiTinh),
                    new SqlParameter("@NgaySinh", request.NgaySinh.ToString("yyyy-MM-dd")), // Chuyển Date về format SQL
                    new SqlParameter("@Sdt", request.Sdt),
                    new SqlParameter("@Email", request.Email)
                };

            try
            {
                // Thực thi Stored Procedure
                var result = await _context.Database.SqlQueryRaw<int>(
                    "EXEC SP_ADMIN_THEM_TAIKHOAN @TenDangNhap, @MatKhau, @MaQuyen, @HoVaTen, @GioiTinh, @NgaySinh, @Sdt, @Email",
                    parameters
                ).ToListAsync();

                if (result.Any())
                {
                    return Ok(new { success = true, maTaiKhoan = result.First(), message = "Thêm tài khoản thành công." });
                }
                return BadRequest(new { success = false, message = "Lỗi không xác định khi thêm tài khoản." });
            }
            catch (Exception ex)
            {
                // Xử lý lỗi trùng tên đăng nhập/email
                return BadRequest(new { success = false, message = $"Thêm thất bại: {ex.Message}" });
            }
        }

        // 3. Cập nhật trạng thái (Khóa/Cấp lại)
        [HttpPost("update-status/{id}")]
        public async Task<IActionResult> UpdateUserStatus(int id, [FromQuery] string status)
        {
            if (status != "Hoạt động" && status != "Ngừng hoạt động")
                return BadRequest("Trạng thái không hợp lệ.");

            // Dùng Stored Procedure
            var maTKParam = new SqlParameter("@MaTaiKhoan", id);
            var statusParam = new SqlParameter("@TrangThaiMoi", status);

            var result = await _context.Database.SqlQueryRaw<int>(
                "EXEC SP_ADMIN_CAPNHAT_TRANGTHAI @MaTaiKhoan, @TrangThaiMoi",
                maTKParam,
                statusParam
            ).ToListAsync();

            if (result.Any() && result.First() == 1)
            {
                return Ok(new { message = $"Cập nhật trạng thái thành công thành {status}" });
            }
            return NotFound("Không tìm thấy tài khoản.");
        }

        // 4. Xóa Tài khoản
        // Việc xóa tài khoản phải tuân thủ Foreign Key, nên cần xóa các bảng con trước
        // Đây là chức năng phức tạp và rủi ro, cần được Admin xác nhận kỹ.
        [HttpDelete("delete-user/{id}")]
        public async Task<IActionResult> DeleteUser(int id)
        {
            using (var transaction = await _context.Database.BeginTransactionAsync())
            {
                try
                {
                    var user = await _context.Taikhoans.Include(t => t.MaquyenNavigation).FirstOrDefaultAsync(t => t.Mataikhoan == id);
                    if (user == null) return NotFound("Tài khoản không tồn tại.");

                    // Lấy mã quyền để xóa ở bảng con
                    int maQuyen = user.Maquyen;

                    // Xóa các bản ghi ở bảng con trước
                    if (maQuyen == 4) // Độc giả (SINHVIEN)
                    {
                        var sv = await _context.Sinhviens.FirstOrDefaultAsync(s => s.Mataikhoan == id);
                        if (sv != null) _context.Sinhviens.Remove(sv);
                    }
                    else if (maQuyen == 2) // Thủ thư (THUTHU)
                    {
                        var tt = await _context.Thuthus.FirstOrDefaultAsync(t => t.Mataikhoan == id);
                        if (tt != null) _context.Thuthus.Remove(tt);
                    }
                    else if (maQuyen == 3) // Thủ kho (THUKHO)
                    {
                        var tk = await _context.Thukhos.FirstOrDefaultAsync(k => k.Mataikhoan == id);
                        if (tk != null) _context.Thukhos.Remove(tk);
                    }

                    await _context.SaveChangesAsync();

                    // Sau đó xóa ở bảng TAIKHOAN
                    _context.Taikhoans.Remove(user);
                    await _context.SaveChangesAsync();

                    await transaction.CommitAsync();

                    return Ok(new { message = $"Đã xóa tài khoản {user.Tendangnhap}" });
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    // Lỗi phổ biến: Tài khoản đang có khóa ngoại với các bảng khác (Phiếu mượn/trả/nhập...)
                    return BadRequest($"Xóa thất bại: Tài khoản này đang có giao dịch phát sinh. Chi tiết: {ex.Message}");
                }
            }
        }
        // =========================================================
        // NHÓM 1: KIỂM TRA NHẬT KÝ HỆ THỐNG
        // =========================================================

        // 1.1 Nhật ký đăng nhập/hoạt động
        [HttpGet("logs-system")]
        public async Task<IActionResult> GetSystemLogs()
        {
            var logs = await _context.Nhatkyhoatdongs
                .Include(n => n.MataikhoanNavigation)
                .OrderByDescending(n => n.Thoigian)
                .Take(50) // Lấy 50 dòng mới nhất
                .Select(n => new {
                    n.Manhatky,
                    TenTaiKhoan = n.MataikhoanNavigation.Tendangnhap,
                    n.Hanhdong,
                    ThoiGian = n.Thoigian.HasValue ? n.Thoigian.Value.ToString("dd/MM/yyyy HH:mm:ss") : ""
                })
                .ToListAsync();
            return Ok(logs);
        }

        // 1.2 Nhật ký giao dịch (Hợp nhất Mượn/Trả/Nhập/Thanh lý)
        [HttpGet("logs-transaction")]
        public async Task<IActionResult> GetTransactionLogs()
        {
            // Lấy 20 giao dịch mỗi loại
            var muon = await _context.Phieumuons.OrderByDescending(x => x.Ngaylapphieumuon).Take(20)
                .Select(x => new { Loai = "Mượn Sách", MaPhieu = x.Mapm, Ngay = x.Ngaylapphieumuon.ToDateTime(TimeOnly.MinValue), ChiTiet = $"SV: {x.Masv}" }).ToListAsync();

            var tra = await _context.Phieutras.OrderByDescending(x => x.Ngaylapphieutra).Take(20)
                .Select(x => new { Loai = "Trả Sách", MaPhieu = x.Mapt, Ngay = x.Ngaylapphieutra.ToDateTime(TimeOnly.MinValue), ChiTiet = $"Phiếu mượn gốc: {x.Mapm}" }).ToListAsync();

            var nhap = await _context.Phieunhaps.OrderByDescending(x => x.Ngaynhap).Take(20)
                .Select(x => new { Loai = "Nhập Hàng", MaPhieu = x.Mapn, Ngay = x.Ngaynhap.ToDateTime(TimeOnly.MinValue), ChiTiet = $"Tổng tiền: {x.Tongtien}" }).ToListAsync();

            // Gộp và sắp xếp
            var result = muon.Concat(tra).Concat(nhap)
                .OrderByDescending(x => x.Ngay)
                .ToList();

            return Ok(result);
        }

        // 1.3 Nhật ký vi phạm (Trả quá hạn/thiếu)
        [HttpGet("logs-violation")]
        public async Task<IActionResult> GetViolationLogs()
        {
            var violations = await _context.Phieutras
                .Include(pt => pt.MapmNavigation).ThenInclude(pm => pm.MasvNavigation)
                .Where(pt => pt.Tongtienphat > 0)
                .OrderByDescending(pt => pt.Ngaylapphieutra)
                .Select(pt => new {
                    pt.Mapt,
                    TenSinhVien = pt.MapmNavigation.MasvNavigation.Hovaten,
                    NgayTra = pt.Ngaylapphieutra.ToString("dd/MM/yyyy"),
                    SoNgayQuaHan = pt.Songayquahan,
                    TienPhat = pt.Tongtienphat
                })
                .ToListAsync();
            return Ok(violations);
        }

        // =========================================================
        // NHÓM 2: BÁO CÁO THỐNG KÊ (Cho Admin xem)
        // =========================================================

        // 2.1 Báo cáo Thủ thư (Mượn/Trả theo tháng hiện tại)
        [HttpGet("report-librarian")]
        public async Task<IActionResult> GetLibrarianReport()
        {
            var currentMonth = DateOnly.FromDateTime(DateTime.Now).Month;
            var currentYear = DateOnly.FromDateTime(DateTime.Now).Year;

            var totalBorrows = await _context.Phieumuons
                .Where(p => p.Ngaylapphieumuon.Month == currentMonth && p.Ngaylapphieumuon.Year == currentYear)
                .CountAsync();

            var totalReturns = await _context.Phieutras
                .Where(p => p.Ngaylapphieutra.Month == currentMonth && p.Ngaylapphieutra.Year == currentYear)
                .CountAsync();

            var overdueCount = await _context.Phieumuons
                .Where(p => p.Trangthai.Contains("Quá hạn"))
                .CountAsync();

            return Ok(new
            {
                Thang = currentMonth,
                LuotMuon = totalBorrows,
                LuotTra = totalReturns,
                DangQuaHan = overdueCount
            });
        }


        // 2.2 Báo cáo Thủ kho (Thu/Chi tổng quát) - Tái sử dụng logic của ThuKhoController nhưng trả về tổng
        [HttpGet("report-storekeeper")]
        public async Task<IActionResult> GetStorekeeperReport()
        {
            var currentYear = DateTime.Now.Year;

            var tongChi = await _context.Chitietphieunhaps
                .Include(ct => ct.MapnNavigation)
                .Where(ct => ct.MapnNavigation.Ngaynhap.Year == currentYear)
                .SumAsync(ct => (ct.Soluong ?? 0) * ct.Gianhap);

            var tongThu = await _context.Chitietthanhlies
                .Include(ct => ct.MatlNavigation)
                .Where(ct => ct.MatlNavigation.Ngaylap.Year == currentYear)
                .SumAsync(ct => (ct.Soluong) * ct.Dongia);

            return Ok(new
            {
                Nam = currentYear,
                TongChiNhapSach = tongChi,
                TongThuThanhLy = tongThu,
                LoiNhuan = tongThu - tongChi
            });
        }

        // 2.3 Thống kê phân bổ thể loại (Biểu đồ tròn)
        [HttpGet("stats-category")]
        public async Task<IActionResult> GetCategoryStats()
        {
            var data = await _context.Saches
                .GroupBy(s => s.Theloai)
                .Select(g => new {
                    TheLoai = g.Key,
                    SoLuong = g.Count()
                })
                .ToListAsync();

            // Tính phần trăm
            int total = data.Sum(x => x.SoLuong);
            var result = data.Select(x => new {
                x.TheLoai,
                x.SoLuong,
                PhanTram = total > 0 ? Math.Round((double)x.SoLuong / total * 100, 2) : 0
            });

            return Ok(result);
        }

        // 2.4 Thống kê lượt mượn theo tháng trong năm nay (Biểu đồ cột)
        [HttpGet("stats-monthly-borrows")]
        public async Task<IActionResult> GetMonthlyBorrows()
        {
            var currentYear = DateTime.Now.Year;
            var data = await _context.Phieumuons
                .Where(p => p.Ngaylapphieumuon.Year == currentYear)
                .GroupBy(p => p.Ngaylapphieumuon.Month)
                .Select(g => new {
                    Thang = g.Key,
                    LuotMuon = g.Count()
                })
                .OrderBy(x => x.Thang)
                .ToListAsync();

            return Ok(data);
        }

        // 2.5 Top 5 sách được mượn nhiều nhất
        [HttpGet("stats-top-books")]
        public async Task<IActionResult> GetTopBooks()
        {
            var data = await _context.Chitietphieumuons
                .Include(ct => ct.MasachNavigation)
                .GroupBy(ct => new { ct.Masach, ct.MasachNavigation.Tensach, ct.MasachNavigation.Hinhanh })
                .Select(g => new {
                    MaSach = g.Key.Masach,
                    TenSach = g.Key.Tensach,
                    HinhAnh = g.Key.Hinhanh,
                    LuotMuon = g.Count()
                })
                .OrderByDescending(x => x.LuotMuon)
                .Take(5)
                .ToListAsync();

            return Ok(data);
        }

        // 2.6 Top 5 độc giả mượn sách nhiều nhất
        [HttpGet("stats-top-readers")]
        public async Task<IActionResult> GetTopReaders()
        {
            var data = await _context.Phieumuons
                .Include(p => p.MasvNavigation)
                .GroupBy(p => new { p.Masv, p.MasvNavigation.Hovaten })
                .Select(g => new {
                    MaSV = g.Key.Masv,
                    HoTen = g.Key.Hovaten,
                    SoLanMuon = g.Count()
                })
                .OrderByDescending(x => x.SoLanMuon)
                .Take(5)
                .ToListAsync();

            return Ok(data);
        }

        // 2.7 Lấy danh sách sách mới nhập (Tin tức)
        [HttpGet("news-new-books")]
        public async Task<IActionResult> GetNewBooksNews()
        {
            var sevenDaysAgo = DateOnly.FromDateTime(DateTime.Now.AddDays(-7));

            var data = await _context.Chitietphieunhaps
                .Include(ct => ct.MapnNavigation)
                .Include(ct => ct.MasachNavigation)
                .Where(ct => ct.MapnNavigation.Ngaynhap >= sevenDaysAgo)
                .OrderByDescending(ct => ct.MapnNavigation.Ngaynhap)
                .Select(ct => new {
                    TenSach = ct.MasachNavigation.Tensach,
                    HinhAnh = ct.MasachNavigation.Hinhanh,
                    NgayNhap = ct.MapnNavigation.Ngaynhap.ToString("dd/MM/yyyy"),
                    NoiDung = $"Sách '{ct.MasachNavigation.Tensach}' vừa cập bến thư viện! Mời bạn đến xem ngay."
                })
                .ToListAsync();

            return Ok(data);
        }
    }
}