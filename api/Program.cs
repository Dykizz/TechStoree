using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Diagnostics;
using Microsoft.IdentityModel.Tokens;
using WebBanHang.Api.Data;
using WebBanHang.Api.Middlewares;
using WebBanHang.Api.Services;
using WebBanHang.Api.Services.Interfaces;
using Microsoft.OpenApi;

// 0. Tự động nạp file .env (nếu có) vào Environment Variables khi chạy local dev
var currentDir = Directory.GetCurrentDirectory();
var candidateEnvPaths = new[]
{
    Path.Combine(currentDir, ".env"),
    Path.Combine(currentDir, "..", ".env"),
    Path.Combine(AppContext.BaseDirectory, ".env"),
    Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "..", ".env")
};

foreach (var envPath in candidateEnvPaths)
{
    if (File.Exists(envPath))
    {
        foreach (var line in File.ReadAllLines(envPath))
        {
            var trimmed = line.Trim();
            if (string.IsNullOrWhiteSpace(trimmed) || trimmed.StartsWith('#')) continue;
            var parts = trimmed.Split('=', 2);
            if (parts.Length == 2)
            {
                var key = parts[0].Trim();
                var val = parts[1].Trim().Trim('"').Trim('\'');
                Environment.SetEnvironmentVariable(key, val);
            }
        }
        break;
    }
}

var builder = WebApplication.CreateBuilder(args);

// 1. Cấu hình DbContext với PostgreSQL Npgsql
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
builder.Services.AddDbContext<AppDbContext>(options =>
{
    options.UseNpgsql(connectionString);
    options.ConfigureWarnings(w => w.Ignore(RelationalEventId.PendingModelChangesWarning));
});

// 2. Đăng ký các Services tầng nghiệp vụ (Dependency Injection)
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<ISupplierService, SupplierService>();
builder.Services.AddScoped<ICategoryService, CategoryService>();
builder.Services.AddScoped<IProductService, ProductService>();
builder.Services.AddScoped<IPurchaseOrderService, PurchaseOrderService>();
builder.Services.AddScoped<ICartService, CartService>();
builder.Services.AddScoped<IPromotionService, PromotionService>();
builder.Services.AddScoped<IVoucherService, VoucherService>();
builder.Services.AddScoped<IOrderService, OrderService>();
builder.Services.AddScoped<ISurveyService, SurveyService>();
builder.Services.AddScoped<ICloudinaryService, CloudinaryService>();



// 3. Cấu hình JSON serializer theo định dạng camelCase & Chuẩn hóa URL route chữ thường
builder.Services.Configure<RouteOptions>(options =>
{
    options.LowercaseUrls = true;
});

builder.Services.AddControllers()
    .AddJsonOptions(options =>
    {
        options.JsonSerializerOptions.PropertyNamingPolicy = JsonNamingPolicy.CamelCase;
    });

// 4. Cấu hình CORS đọc từ biến cấu hình / biến môi trường (ENV: Cors__AllowedOrigins)
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

// 5. Cấu hình JWT Bearer Authentication & Phân quyền RBAC
var jwtSecretKey = builder.Configuration["Jwt:Key"] ?? "WebBanHang_Super_Secret_Jwt_Security_Key_For_Authentication_2026_SGU_841065";
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = builder.Configuration["Jwt:Issuer"] ?? "WebBanHang_API",
            ValidAudience = builder.Configuration["Jwt:Audience"] ?? "WebBanHang_Client",
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSecretKey))
        };
    });

builder.Services.AddAuthorization();

// 6. Cấu hình Swagger / OpenAPI kèm XML Documentation & JWT Bearer Authentication
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    var xmlFilename = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFilename);
    if (File.Exists(xmlPath))
    {
        options.IncludeXmlComments(xmlPath);
    }


    // Cấu hình định nghĩa bảo mật JWT Bearer cho Swagger
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Nhập Access Token vào đây (Swagger sẽ tự thêm tiền tố 'Bearer '):"
    });

    // Tự động gắn icon ổ khóa 🔒 và yêu cầu Bearer token cho các endpoint có [Authorize]
    options.OperationFilter<WebBanHang.Api.Common.AuthorizeCheckOperationFilter>();

    // Loại bỏ khối Example/Schema rác ở các mã lỗi 4xx, 5xx
    options.OperationFilter<WebBanHang.Api.Common.RemoveErrorSchemasFilter>();
});

var app = builder.Build();

// 7. Kích hoạt Global Exception Handling Middleware đầu tiên trong pipeline
app.UseMiddleware<GlobalExceptionMiddleware>();

// 8. Tự động kiểm tra và thực thi Migration CSDL khi khởi động
using (var scope = app.Services.CreateScope())
{
    var dbContext = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    try
    {
        dbContext.Database.Migrate();
    }
    catch (Exception ex)
    {
        app.Logger.LogWarning(ex, "Chưa thể kết nối hoặc migrate CSDL khi khởi động: {Message}", ex.Message);
    }
}

// 9. Kích hoạt Swagger UI
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "WebBanHang API v1");
    c.RoutePrefix = "swagger";
});

app.UseCors("AllowClientApps");

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();

app.Run();
