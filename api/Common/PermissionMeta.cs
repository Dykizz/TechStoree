namespace WebBanHang.Api.Common;

/// <summary>
/// Metadata mô tả một quyền hạn (Permission) trong danh mục chuẩn của hệ thống.
/// Danh mục này được khai báo trong <see cref="AppPermissions.Catalog"/> và là nguồn sự thật
/// duy nhất cho sự tồn tại của quyền — Quản trị viên KHÔNG thể tự thêm quyền mới.
/// </summary>
/// <param name="Id">Mã định danh quyền theo quy ước Module.Action (vd: Products.Create).</param>
/// <param name="Module">Phân hệ quản lý dùng để gom nhóm khi hiển thị cho Quản trị viên.</param>
/// <param name="Name">Tên hiển thị tiếng Việt của quyền.</param>
/// <param name="Description">Mô tả chi tiết chức năng mà quyền bảo vệ.</param>
/// <param name="Reserved">
/// Đánh dấu quyền đã được khai báo nhưng CHỦ Ý chưa gắn vào endpoint nào
/// (dành cho tính năng sẽ bổ sung sau). Quyền <c>Reserved = false</c> bắt buộc phải
/// được ít nhất một endpoint sử dụng, nếu không ứng dụng sẽ từ chối khởi động.
/// </param>
public sealed record PermissionMeta(
    string Id,
    string Module,
    string Name,
    string? Description = null,
    bool Reserved = false);
