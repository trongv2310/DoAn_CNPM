using API_ThuVien.Models; // Đảm bảo tên này đúng với namespace project của bạn
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders; // <-- 1. THÊM THƯ VIỆN NÀY
using System.IO; // <-- 2. THÊM THƯ VIỆN NÀY

var builder = WebApplication.CreateBuilder(args);

// ==================================================================
// 1. ĐĂNG KÝ KẾT NỐI DATABASE (PHẦN BẠN ĐANG THIẾU)
// ==================================================================
builder.Services.AddDbContext<ThuVienDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("ThuVienDB")));

// Add services to the container.
builder.Services.AddControllers();

// 2. Cấu hình Swagger (để hiện giao diện test màu xanh)
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();
// ==================================================================
// 3. CẤU HÌNH ĐỂ DÙNG THƯ MỤC 'images' THAY VÌ 'wwwroot'
// ==================================================================
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(
        Path.Combine(builder.Environment.ContentRootPath, "images")), // Trỏ đến thư mục "images" ở gốc
    RequestPath = "/images" // Đường dẫn truy cập sẽ là: http://.../images/ten_anh.jpg
});
// ==================================================================
app.MapControllers();

app.Run();