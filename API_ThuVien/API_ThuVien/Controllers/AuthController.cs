// LƯU Ý: Kiểm tra namespace này. Nếu project bạn tên khác thì sửa lại (VD: ThuVienAPI.Models)
using API_ThuVien.Models;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace API_ThuVien.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class AuthController : ControllerBase
    {
        private readonly ThuVienDbContext _context;

        public AuthController(ThuVienDbContext context)
        {
            _context = context;
        }

        // Class nhận dữ liệu từ Flutter gửi lên
        public class LoginRequest
        {
            public string Username { get; set; }
            public string Password { get; set; }
        }

        [HttpPost("login")]
        public async Task<IActionResult> Login([FromBody] LoginRequest request)
        {
            if (request == null || string.IsNullOrEmpty(request.Username) || string.IsNullOrEmpty(request.Password))
            {
                return BadRequest("Vui lòng nhập đầy đủ thông tin!");
            }

            // 1. Lấy danh sách tài khoản để xử lý lỗi khoảng trắng (Trim)
            // SQL dùng CHAR(30) nên thường bị thừa dấu cách cuối
            var allUsers = await _context.Taikhoans.ToListAsync();

            var user = allUsers.FirstOrDefault(u =>
                u.Tendangnhap.Trim() == request.Username.Trim() &&
                u.Matkhau.Trim() == request.Password.Trim()
            );

            if (user == null)
            {
                return Unauthorized(new { message = "Sai tên đăng nhập hoặc mật khẩu!" });
            }

            // Kiểm tra nếu tài khoản bị khóa (Ngừng hoạt động)
            if (user.Trangthai == "Ngừng hoạt động")
            {
                return BadRequest(new { message = "Tài khoản của bạn đã bị khóa! Vui lòng liên hệ đến dịch vụ CSKH" });
            }

            if (user != null)
            {
                var log = new Nhatkyhoatdong
                {
                    Mataikhoan = user.Mataikhoan,
                    Hanhdong = $"User {user.Tendangnhap} đăng nhập", // Ghi rõ ai đăng nhập
                    Thoigian = DateTime.Now,
                    Ghichu = "Đăng nhập từ App Mobile"
                };

                _context.Nhatkyhoatdongs.Add(log);

                await _context.SaveChangesAsync();
            }
            // 2. Tìm họ tên người dùng dựa trên quyền
            string hoVaTen = "Người dùng";
            int entityId = 0;
            // Nếu là Độc giả (Mã quyền 4)
            if (user.Maquyen == 4)
            {
                var sv = await _context.Sinhviens.FirstOrDefaultAsync(s => s.Mataikhoan == user.Mataikhoan);
                if (sv != null) { hoVaTen = sv.Hovaten; entityId = sv.Masv; }
            }
            // Nếu là Thủ thư (Mã quyền 2)
            else if (user.Maquyen == 2)
            {
                var tt = await _context.Thuthus.FirstOrDefaultAsync(t => t.Mataikhoan == user.Mataikhoan);
                if (tt != null) { hoVaTen = tt.Hovaten; entityId = tt.Matt; }
            }
            //Nếu là Thủ kho (Mã quyền 3)
            else if (user.Maquyen == 3)
            {
                var tk = await _context.Thukhos.FirstOrDefaultAsync(k => k.Mataikhoan == user.Mataikhoan);
                if (tk != null) { hoVaTen = tk.Hovaten; entityId = tk.Matk; }
            }

            // 3. Trả về kết quả JSON
            return Ok(new
            {
                MaTaiKhoan = user.Mataikhoan, // Viết Hoa chữ cái đầu
                TenDangNhap = user.Tendangnhap.Trim(),
                HoVaTen = hoVaTen,
                MaQuyen = user.Maquyen,
                EntityId = entityId
            });
        }

        // Model hứng dữ liệu đổi pass  
        public class ChangePasswordRequest
        {
            public int MaTaiKhoan { get; set; }
            public string MatKhauCu { get; set; }
            public string MatKhauMoi { get; set; }
        }

        // API: Đổi mật khẩu
        [HttpPost("doi-mat-khau")]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
        {
            var user = await _context.Taikhoans.FindAsync(request.MaTaiKhoan);
            if (user == null) return NotFound("Tài khoản không tồn tại");

            // Kiểm tra pass cũ (Cần Trim để xóa khoảng trắng thừa của SQL CHAR)
            if (user.Matkhau.Trim() != request.MatKhauCu.Trim())
            {
                return BadRequest("Mật khẩu cũ không chính xác");
            }

            user.Matkhau = request.MatKhauMoi; // Nên mã hóa MD5/BCrypt ở thực tế
            await _context.SaveChangesAsync();

            return Ok(new { message = "Đổi mật khẩu thành công" });
        }

        public class RegisterRequest
        {
            public string TenDangNhap { get; set; } = null!;
            public string MatKhau { get; set; } = null!;
            public string HoVaTen { get; set; } = null!;
            public string GioiTinh { get; set; } = null!;
            public DateTime NgaySinh { get; set; }
            public string Sdt { get; set; } = null!;
            public string Email { get; set; } = null!;
        }

        [HttpPost("register")]
        public async Task<IActionResult> Register([FromBody] RegisterRequest request)
        {
            // Mặc định đăng ký mới sẽ là Độc giả (MaQuyen = 4)
            int defaultRole = 4;

            var parameters = new[]
            {
            new SqlParameter("@TenDangNhap", request.TenDangNhap),
            new SqlParameter("@MatKhau", request.MatKhau),
            new SqlParameter("@MaQuyen", defaultRole),
            new SqlParameter("@HoVaTen", request.HoVaTen),
            new SqlParameter("@GioiTinh", request.GioiTinh),
            new SqlParameter("@NgaySinh", request.NgaySinh.ToString("yyyy-MM-dd")),
            new SqlParameter("@Sdt", request.Sdt),
            new SqlParameter("@Email", request.Email)
        };

            try
            {
                // Gọi lại Stored Procedure có sẵn của Admin nhưng dùng cho Public
                var result = await _context.Database.SqlQueryRaw<int>(
                    "EXEC SP_ADMIN_THEM_TAIKHOAN @TenDangNhap, @MatKhau, @MaQuyen, @HoVaTen, @GioiTinh, @NgaySinh, @Sdt, @Email",
                    parameters
                ).ToListAsync();

                if (result.Any())
                {
                    return Ok(new { success = true, message = "Đăng ký thành công! Vui lòng đăng nhập." });
                }
                return BadRequest(new { success = false, message = "Lỗi không xác định khi tạo tài khoản." });
            }
            catch (Exception ex)
            {
                // Lỗi thường gặp: Trùng tên đăng nhập hoặc trùng Email (do ràng buộc Unique trong DB)
                return BadRequest(new { success = false, message = "Tên đăng nhập hoặc Email đã tồn tại!" });
            }

        }
    }
}