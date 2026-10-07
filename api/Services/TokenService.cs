using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using WebBanHang.Api.Models;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Services;

public class TokenService(IConfiguration config) : ITokenService
{
    public string GenerateToken(User user)
    {
        var secretKey = config["Jwt:Key"] ?? "WebBanHang_Super_Secret_Jwt_Security_Key_For_Authentication_2026_SGU_841065";
        var issuer = config["Jwt:Issuer"] ?? "WebBanHang_API";
        var audience = config["Jwt:Audience"] ?? "WebBanHang_Client";
        var expireMinutes = double.TryParse(config["Jwt:ExpireMinutes"], out var mins) ? mins : 60; // Mặc định 60 phút

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new Claim(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new Claim(ClaimTypes.Name, user.Username),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim("fullName", user.FullName)
        };

        // Gán tất cả vai trò của tài khoản vào claims (ASP.NET Core RBAC hỗ trợ nhiều ClaimTypes.Role)
        var roles = user.UserRoles?.Select(ur => ur.RoleId.ToString()).Distinct().ToList() ?? new List<string>();
        if (roles.Count == 0)
        {
            roles.Add(WebBanHang.Api.Enums.UserRoleTypeExtensions.User);
        }

        foreach (var r in roles)
        {
            claims.Add(new Claim(ClaimTypes.Role, r));
        }

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(claims),
            Expires = DateTime.UtcNow.AddMinutes(expireMinutes),
            Issuer = issuer,
            Audience = audience,
            SigningCredentials = creds
        };

        var tokenHandler = new JwtSecurityTokenHandler();
        var token = tokenHandler.CreateToken(tokenDescriptor);

        return tokenHandler.WriteToken(token);
    }

    public string GenerateRefreshToken()
    {
        var randomNumber = new byte[64];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(randomNumber);
        return Convert.ToBase64String(randomNumber);
    }
}
