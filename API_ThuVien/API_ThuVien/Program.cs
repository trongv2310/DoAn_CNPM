using API_ThuVien.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using System.Text.Json.Serialization; // Thư viện xử lý vòng lặp JSON

var builder = WebApplication.CreateBuilder(args);

// 1. ĐĂNG KÝ DATABASE
builder.Services.AddDbContext<ThuVienDbContext>(options =>
    options.UseSqlServer(builder.Configuration.GetConnectionString("ThuVienDB")));


builder.Services.AddControllers().AddJsonOptions(x =>
    x.JsonSerializerOptions.ReferenceHandler = ReferenceHandler.IgnoreCycles);

builder.Services.AddEndpointsApiExplorer();


builder.Services.AddSwaggerGen(c =>
{
    // Dòng này giúp Swagger phân biệt được các class cùng tên nằm ở thư mục khác nhau
    c.CustomSchemaIds(type => type.ToString());
});

var app = builder.Build();

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseHttpsRedirection();
app.UseAuthorization();

// Cấu hình hiển thị ảnh
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(
        Path.Combine(builder.Environment.ContentRootPath, "images")),
    RequestPath = "/images"
});

app.MapControllers();

app.Run();