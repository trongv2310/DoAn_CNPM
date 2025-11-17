using API_ThuVien.Models; // Đảm bảo tên này đúng với namespace project của bạn
using Microsoft.EntityFrameworkCore;

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
app.MapControllers();

app.Run();