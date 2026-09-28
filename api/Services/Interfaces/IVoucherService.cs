using WebBanHang.Api.Common;
using WebBanHang.Api.DTOs.Vouchers;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.Services.Interfaces;

public interface IVoucherService
{
    /// <summary>
    /// Lấy danh sách voucher toàn hệ thống cho Quản trị viên (hỗ trợ bộ lọc và phân trang)
    /// </summary>
    Task<PagedResult<VoucherBaseDto>> GetAllVouchersAsync(VoucherQueryFilter? filter = null);

    /// <summary>
    /// Lấy danh sách voucher công khai đang có hiệu lực để khách hàng thu thập hoặc áp dụng
    /// </summary>
    Task<IEnumerable<VoucherBaseDto>> GetAvailableVouchersAsync();

    /// <summary>
    /// Lấy thông tin chi tiết một voucher theo ID
    /// </summary>
    Task<VoucherDetailDto?> GetVoucherByIdAsync(int id);

    /// <summary>
    /// Tạo mới một chiến dịch voucher (Admin)
    /// </summary>
    Task<VoucherDetailDto> CreateVoucherAsync(VoucherUpsertRequestDto request);

    /// <summary>
    /// Cập nhật chiến dịch voucher có kiểm soát vòng đời (Admin)
    /// </summary>
    Task<VoucherDetailDto?> UpdateVoucherAsync(int id, VoucherUpsertRequestDto request);

    /// <summary>
    /// Bật / Tắt kích hoạt nhanh voucher (Admin)
    /// </summary>
    Task<bool?> ToggleActiveAsync(int id);

    /// <summary>
    /// Xóa voucher chưa diễn ra (Admin)
    /// </summary>
    Task<bool> DeleteVoucherAsync(int id);

    /// <summary>
    /// Kiểm tra tính hợp lệ và tính toán số tiền giảm giá khi áp dụng mã voucher cho giỏ hàng
    /// </summary>
    Task<ApplyVoucherResponseDto> ApplyVoucherAsync(ApplyVoucherRequestDto request, int? userId = null);

    /// <summary>
    /// Lấy danh sách voucher trong ví cá nhân của khách hàng (có thể lọc theo trạng thái USABLE, USED, EXPIRED)
    /// </summary>
    Task<IEnumerable<UserVoucherItemDto>> GetMyVouchersAsync(int userId, UserVoucherWalletStatus? status = null);

    /// <summary>
    /// Khách hàng thu thập / lưu một voucher công khai vào ví cá nhân của mình
    /// </summary>
    Task<UserVoucherItemDto> ClaimVoucherAsync(int voucherId, int userId);
}

