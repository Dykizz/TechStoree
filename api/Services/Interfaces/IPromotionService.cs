using WebBanHang.Api.DTOs.Promotions;

namespace WebBanHang.Api.Services.Interfaces;

public interface IPromotionService
{
    Task<IEnumerable<PromotionBaseDto>> GetAllPromotionsAsync(PromotionQueryFilter? filter = null);
    Task<PromotionDetailDto?> GetPromotionByIdAsync(int id);
    Task<PromotionDetailDto> CreatePromotionAsync(PromotionUpsertRequestDto request);
    Task<PromotionDetailDto?> UpdatePromotionAsync(int id, PromotionUpsertRequestDto request);
    Task<bool> DeletePromotionAsync(int id);
    Task<bool?> ToggleActiveAsync(int id);
}
