namespace WebBanHang.Api.DTOs.Roles;

public class PermissionDto
{
    /// <summary>
    /// Mã định danh quyền hạn (Module.Action)
    /// </summary>
    /// <example>Products.Create</example>
    public string PermissionId { get; set; } = string.Empty;

    /// <summary>
    /// Tên hiển thị quyền hạn
    /// </summary>
    /// <example>Thêm mới sản phẩm</example>
    public string PermissionName { get; set; } = string.Empty;

    /// <summary>
    /// Phân hệ / Module quản lý
    /// </summary>
    /// <example>Quản lý sản phẩm</example>
    public string Module { get; set; } = string.Empty;

    /// <summary>
    /// Mô tả chi tiết chức năng của quyền hạn
    /// </summary>
    /// <example>Cho phép thêm mới sản phẩm và thiết lập các biến thể</example>
    public string? Description { get; set; }

    /// <summary>
    /// Quyền đã được khai báo trong danh mục chuẩn nhưng CHỦ Ý chưa gắn vào endpoint nào
    /// (dành cho tính năng sẽ bổ sung sau). Giao diện nên hiển thị cảnh báo cho Quản trị viên.
    /// </summary>
    /// <example>false</example>
    public bool IsReserved { get; set; }

    /// <summary>
    /// Số lượng endpoint đang thực sự yêu cầu quyền này
    /// </summary>
    /// <example>2</example>
    public int EndpointCount { get; set; }

    /// <summary>
    /// Danh sách endpoint đang được quyền này bảo vệ (Controller.Action)
    /// </summary>
    /// <example>["Products.CreateProduct", "Products.UpdateProduct"]</example>
    public List<string> Endpoints { get; set; } = new();
}

public class ModulePermissionsDto
{
    /// <summary>
    /// Tên phân hệ / Module quản lý
    /// </summary>
    /// <example>Quản lý sản phẩm</example>
    public string Module { get; set; } = string.Empty;

    /// <summary>
    /// Danh sách các quyền hạn thuộc phân hệ
    /// </summary>
    public List<PermissionDto> Permissions { get; set; } = new();
}
