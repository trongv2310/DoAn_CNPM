using Microsoft.AspNetCore.Mvc;

namespace API_ThuVien.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class UploadController : ControllerBase
    {
        private readonly IWebHostEnvironment _env;

        public UploadController(IWebHostEnvironment env)
        {
            _env = env;
        }

        // POST: api/Upload/book-image
        // multipart/form-data: file=<image>
        [HttpPost("book-image")]
        [RequestSizeLimit(20_000_000)] // 20MB, bạn có thể chỉnh
        public async Task<IActionResult> UploadBookImage(IFormFile file)
        {
            if (file == null || file.Length == 0)
                return BadRequest(new { message = "File rỗng" });

            // Chỉ cho phép ảnh
            var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
            var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
            if (!allowed.Contains(ext))
                return BadRequest(new { message = "Chỉ hỗ trợ jpg, jpeg, png, webp" });

            var imagesDir = Path.Combine(_env.ContentRootPath, "images");
            if (!Directory.Exists(imagesDir))
                Directory.CreateDirectory(imagesDir);

            // Tạo tên file tránh trùng
            var safeFileName = $"{Guid.NewGuid():N}{ext}";
            var savePath = Path.Combine(imagesDir, safeFileName);

            using (var stream = System.IO.File.Create(savePath))
            {
                await file.CopyToAsync(stream);
            }

            // Trả về tên file để Flutter lưu vào DB
            return Ok(new
            {
                fileName = safeFileName,
                url = $"{Request.Scheme}://{Request.Host}/images/{safeFileName}"
            });
        }
    }
}