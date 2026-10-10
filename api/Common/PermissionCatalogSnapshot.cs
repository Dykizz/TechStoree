namespace WebBanHang.Api.Common;

/// <summary>
/// Ảnh chụp danh mục quyền hạn được quét trực tiếp từ các endpoint lúc khởi động.
/// Bất biến sau khi tạo và được dùng xuyên suốt vòng đời ứng dụng.
/// </summary>
public sealed class PermissionCatalogSnapshot
{
    public PermissionCatalogSnapshot(
        IReadOnlyList<PermissionMeta> catalog,
        IReadOnlyDictionary<string, IReadOnlyList<string>> endpointsByPermission,
        IReadOnlyList<string> authOnlyEndpoints,
        int scannedEndpointCount,
        int controllerCount)
    {
        Catalog = catalog;
        EndpointsByPermission = endpointsByPermission;
        AuthOnlyEndpoints = authOnlyEndpoints;
        ScannedEndpointCount = scannedEndpointCount;
        ControllerCount = controllerCount;
        ActiveIds = new HashSet<string>(endpointsByPermission.Keys, StringComparer.OrdinalIgnoreCase);
    }

    /// <summary>Danh mục chuẩn khai báo trong code (nguồn sự thật).</summary>
    public IReadOnlyList<PermissionMeta> Catalog { get; }

    /// <summary>Ánh xạ mã quyền → danh sách endpoint đang thực sự yêu cầu quyền đó.</summary>
    public IReadOnlyDictionary<string, IReadOnlyList<string>> EndpointsByPermission { get; }

    /// <summary>Các endpoint chỉ yêu cầu đăng nhập, không phân quyền chi tiết (phục vụ rà soát bảo mật).</summary>
    public IReadOnlyList<string> AuthOnlyEndpoints { get; }

    /// <summary>Tập quyền đang được ít nhất một endpoint sử dụng.</summary>
    public IReadOnlySet<string> ActiveIds { get; }

    /// <summary>
    /// Số endpoint phân biệt có gắn alias phân quyền. Một method khai báo nhiều attribute HTTP
    /// (ví dụ vừa PUT vừa POST) được tính là MỘT endpoint, nên con số này luôn khớp với
    /// tổng số endpoint liệt kê trong <see cref="EndpointsByPermission"/>.
    /// </summary>
    public int ScannedEndpointCount { get; }

    /// <summary>Số controller có action được phân quyền.</summary>
    public int ControllerCount { get; }

    public IReadOnlyList<string> EndpointsOf(string permissionId) =>
        EndpointsByPermission.TryGetValue(permissionId, out var list) ? list : Array.Empty<string>();

    public int EndpointCount(string permissionId) => EndpointsOf(permissionId).Count;

    /// <summary>Quyền đã khai báo nhưng chủ ý chưa gắn vào endpoint nào.</summary>
    public bool IsReserved(string permissionId) =>
        AppPermissions.ById.TryGetValue(permissionId, out var meta) && meta.Reserved;
}

/// <summary>
/// Holder singleton giữ snapshot danh mục quyền hạn đã quét lúc khởi động,
/// để tầng nghiệp vụ (RoleService) tra cứu mà không cần quét lại.
/// </summary>
public sealed class PermissionCatalogState
{
    public PermissionCatalogSnapshot? Snapshot { get; private set; }

    public void Initialize(PermissionCatalogSnapshot snapshot) => Snapshot = snapshot;
}
