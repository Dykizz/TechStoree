using WebBanHang.Api.Models;

namespace WebBanHang.Api.Services.Interfaces;

public interface ITokenService
{
    string GenerateToken(User user);
    string GenerateRefreshToken();
}
