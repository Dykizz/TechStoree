using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Data;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Middlewares;

var builder = WebApplication.CreateBuilder(args);

// 1. Cấu hình DbContext với PostgreSQL Npgsql
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

// 2. Cấu hình JSON serializer theo định dạng camelCase
builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    });

// 3. Cấu hình CORS đọc từ biến cấu hình / biến môi trường (ENV: Cors__AllowedOrigins)
var corsOriginsConfig = builder.Configuration["Cors:AllowedOrigins"] ?? "http://localhost:3000,http://localhost:30001,http://localhost:3001";
var allowedOrigins = corsOriginsConfig
    .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowClientApps", policy =>
    {
        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// 4. Cấu hình Swagger / OpenAPI
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen();

var app = builder.Build();

// 5. Kích hoạt Global Exception Handling Middleware đầu tiên trong pipeline
app.UseMiddleware<GlobalExceptionMiddleware>();

// 6. Tự động kiểm tra và khởi tạo CSDL khi khởi động
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    try
    {
        dbContext.Database.EnsureCreated();
    }
    catch (Exception ex)
    {
        app.Logger.LogWarning(ex, "Chưa thể kết nối CSDL khi khởi động, kiểm tra lại container PostgreSQL.");
    }
}

// 7. Kích hoạt Swagger UI
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "WebBanHang API v1");
    c.RoutePrefix = "swagger";
});

app.UseCors("AllowClientApps");

app.UseAuthorization();

app.MapControllers();

// 8. Root endpoint trả về ApiResponse chuẩn
app.MapGet("/", () => Results.Ok(ApiResponse.SuccessResult(new
{
    name = "WebBanHang API",
    version = "1.0",
    runtime = ".NET 10.0",
    swagger = "/swagger"
}, "WebBanHang API (.NET 10) đang hoạt động ổn định!")));

// 9. Endpoint kiểm thử Global Error Handling (có thể xóa khi deploy)
app.MapGet("/api/test-error", () =>
{
    throw new BadRequestException("Thử nghiệm lỗi nghiệp vụ bắt bởi GlobalExceptionMiddleware!", new[]
    {
        "Trường email không đúng định dạng.",
        "Mật khẩu phải có độ dài tối thiểu 6 ký tự."
    });
});

app.Run();
