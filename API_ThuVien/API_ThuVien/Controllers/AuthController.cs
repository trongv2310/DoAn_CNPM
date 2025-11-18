using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
// LƯU Ý: Kiểm tra namespace này. Nếu project bạn tên khác thì sửa lại (VD: ThuVienAPI.Models)
using API_ThuVien.Models;

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

            // 2. Tìm họ tên người dùng dựa trên quyền
            string hoVaTen = "Người dùng";
            int entityId = 0;
            // Nếu là Độc giả (Mã quyền 4 - Dựa theo DB của bạn)
            if (user.Maquyen == 4)
            {
                var sv = await _context.Sinhviens.FirstOrDefaultAsync(s => s.Mataikhoan == user.Mataikhoan);
                if (sv != null) hoVaTen = sv.Hovaten;
            }
            // Nếu là Thủ thư (Mã quyền 2)
            else if (user.Maquyen == 2)
            {
                var tt = await _context.Thuthus.FirstOrDefaultAsync(t => t.Mataikhoan == user.Mataikhoan);
                if (tt != null) hoVaTen = tt.Hovaten;
            }
            //Nếu là Thủ kho (Mã quyền 3
            else if (user.Maquyen == 3)
            {
                var tk = await _context.Thukhos.FirstOrDefaultAsync(k => k.Mataikhoan == user.Mataikhoan);
                if (tk != null) { hoVaTen = tk.Hovaten; entityId = tk.Matk; }
            }
            // Nếu là Admin (Mã quyền 1) hoặc Thủ kho (Mã quyền 3) - Tạm thời để tên mặc định hoặc thêm logic tìm bảng NhanVien nếu có

            // 3. Trả về kết quả JSON
            return Ok(new
            {
                maTaiKhoan = user.Mataikhoan,
                tenDangNhap = user.Tendangnhap.Trim(),
                hoVaTen = hoVaTen,
                maQuyen = user.Maquyen,
                entityId = entityId
            });
        }
    }
}