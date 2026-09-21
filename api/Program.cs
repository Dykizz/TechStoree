using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Data;

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

// 5. Tự động khởi tạo CSDL và nạp dữ liệu mẫu khi khởi động
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

// 6. Kích hoạt Swagger UI
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "WebBanHang API v1");
    c.RoutePrefix = "swagger";
});

app.UseCors("AllowClientApps");

app.UseAuthorization();

app.MapControllers();

app.MapGet("/", () => Results.Ok(new
{
    message = "WebBanHang API (.NET 10) is running!",
    swagger = "/swagger"
}));

app.Run();
