using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Promotions;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Exceptions;
using WebBanHang.Api.Services.Interfaces;

namespace WebBanHang.Api.Controllers;

/// <summary>
/// Quản lý các chương trình khuyến mãi giảm giá trực tiếp theo biến thể sản phẩm (Flash Sale / Campaign)
/// </summary>
[Route("api/promotions")]
[Tags("Promotions")]
public class PromotionsController(IPromotionService promotionService) : BaseApiController
{
    /// <summary>
    /// Lấy danh sách tất cả các chương trình khuyến mãi (Hỗ trợ lọc theo khoảng thời gian, chiến dịch đang chạy, trạng thái bật/tắt)
    /// </summary>
    /// <param name="filter">Bộ lọc: status (UPCOMING, ACTIVE, EXPIRED), isActive (bật/tắt của Admin), fromDate, toDate, search</param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<IEnumerable<PromotionBaseDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAllPromotions([FromQuery] PromotionQueryFilter filter)
    {
        var result = await promotionService.GetAllPromotionsAsync(filter);
        return Success(result, "Lấy danh sách chương trình khuyến mãi thành công.");
    }

    /// <summary>
    /// Lấy thông tin chi tiết một chương trình khuyến mãi kèm danh sách đầy đủ sản phẩm tham gia
    /// </summary>
    /// <param name="id">Mã ID khuyến mãi</param>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<PromotionDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPromotionById([FromRoute] int id)
    {
        var result = await promotionService.GetPromotionByIdAsync(id)
            ?? throw new NotFoundException($"Không tìm thấy chương trình khuyến mãi có mã ID = {id}.");

        return Success(result, "Lấy chi tiết chương trình khuyến mãi thành công.");
    }

    /// <summary>
    /// Tạo mới một chương trình khuyến mãi (Yêu cầu quyền Quản trị viên)
    /// </summary>
    [HttpPost]
    [HasPermission(AppPermissions.Promotions.Create)]
    [ProducesResponseType(typeof(ApiResponse<PromotionDetailDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> CreatePromotion([FromBody] PromotionUpsertRequestDto dto)
    {
        var result = await promotionService.CreatePromotionAsync(dto);
        return CreatedSuccess(result, "Tạo mới chương trình khuyến mãi thành công.");
    }

    /// <summary>
    /// Cập nhật thông tin chương trình khuyến mãi (Yêu cầu quyền Quản trị viên)
    /// </summary>
    /// <param name="id">Mã ID khuyến mãi</param>
    /// <param name="dto">Dữ liệu cập nhật</param>
    [HttpPut("{id:int}")]
    [HasPermission(AppPermissions.Promotions.Update)]
    [ProducesResponseType(typeof(ApiResponse<PromotionDetailDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdatePromotion([FromRoute] int id, [FromBody] PromotionUpsertRequestDto dto)
    {
        var result = await promotionService.UpdatePromotionAsync(id, dto)
            ?? throw new NotFoundException($"Không tìm thấy chương trình khuyến mãi có mã ID = {id}.");

        return Success(result, "Cập nhật chương trình khuyến mãi thành công.");
    }

    /// <summary>
    /// Xóa một chương trình khuyến mãi (Yêu cầu quyền Quản trị viên)
    /// </summary>
    /// <param name="id">Mã ID khuyến mãi</param>
    [HttpDelete("{id:int}")]
    [HasPermission(AppPermissions.Promotions.Delete)]
    [ProducesResponseType(typeof(ApiResponse<object?>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> DeletePromotion([FromRoute] int id)
    {
        var deleted = await promotionService.DeletePromotionAsync(id);
        if (!deleted)
        {
            throw new NotFoundException($"Không tìm thấy chương trình khuyến mãi có mã ID = {id}.");
        }
        return Success<object?>(null, "Xóa chương trình khuyến mãi thành công.");
    }

    /// <summary>
    /// Bật/Tắt trạng thái kích hoạt của chương trình khuyến mãi (Yêu cầu quyền Quản trị viên)
    /// </summary>
    /// <param name="id">Mã ID khuyến mãi</param>
    [HttpPatch("{id:int}/toggle-active")]
    [HasPermission(AppPermissions.Promotions.Update)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ToggleActive([FromRoute] int id)
    {
        var activeState = await promotionService.ToggleActiveAsync(id);
        if (activeState == null)
        {
            throw new NotFoundException($"Không tìm thấy chương trình khuyến mãi có mã ID = {id}.");
        }
        var statusText = activeState.Value ? "Kích hoạt" : "Hủy kích hoạt";
        return Success(new { isActive = activeState.Value }, $"{statusText} chương trình khuyến mãi thành công.");
    }
}
