using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc.Controllers;
using Microsoft.AspNetCore.Mvc.Infrastructure;
using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Data;

namespace WebBanHang.Api.Common;

/// <summary>
/// Kết quả đồng bộ danh mục quyền hạn xuống CSDL.
/// </summary>
/// <param name="Inserted">Mã các quyền mới được thêm.</param>
/// <param name="Updated">Mã các quyền có metadata thay đổi.</param>
/// <param name="Legacy">Mã các quyền còn trong CSDL nhưng đã bị xoá khỏi danh mục chuẩn.</param>
/// <param name="ExistingCountBefore">Số quyền đã có trong CSDL TRƯỚC khi đồng bộ (0 nghĩa là CSDL trắng).</param>
public sealed record PermissionSyncResult(
    IReadOnlyList<string> Inserted,
    IReadOnlyList<string> Updated,
    IReadOnlyList<string> Legacy,
    int ExistingCountBefore);

/// <summary>
/// Quét alias <see cref="HasPermissionAttribute"/> trên toàn bộ endpoint để xây dựng danh mục
/// quyền hạn chuẩn, kiểm tra tính nhất quán với <see cref="AppPermissions.Catalog"/> và
/// đồng bộ xuống bảng <c>permissions</c>.
/// <para>
/// Nguyên tắc: mã nguồn là nguồn sự thật duy nhất. Builder chỉ ghi theo hướng code → CSDL,
/// KHÔNG bao giờ xoá quyền (khoá ngoại <c>role_permissions</c> là Cascade, xoá sẽ làm mất
/// cấu hình phân quyền của Quản trị viên).
/// </para>
/// </summary>
public sealed class PermissionCatalogBuilder(
    AppDbContext context,
    IActionDescriptorCollectionProvider actionDescriptors,
    ILogger<PermissionCatalogBuilder> logger)
{
    /// <summary>
    /// Upsert nguyên tử, an toàn khi nhiều instance API khởi động cùng lúc.
    /// Mệnh đề WHERE giúp lần chạy thứ hai không ghi gì (tránh phình WAL).
    /// </summary>
    private const string UpsertSql = """
        INSERT INTO permissions (permission_id, permission_name, module, description)
        VALUES ({0}, {1}, {2}, {3})
        ON CONFLICT (permission_id) DO UPDATE
        SET permission_name = EXCLUDED.permission_name,
            module          = EXCLUDED.module,
            description     = EXCLUDED.description
        WHERE permissions.permission_name IS DISTINCT FROM EXCLUDED.permission_name
           OR permissions.module          IS DISTINCT FROM EXCLUDED.module
           OR permissions.description     IS DISTINCT FROM EXCLUDED.description;
        """;

    /// <summary>
    /// Quét endpoint và kiểm tra tính nhất quán. KHÔNG truy cập CSDL nên có thể chạy
    /// trước bước migration — cấu hình sai sẽ làm ứng dụng dừng ngay thay vì lỗi 403 âm thầm.
    /// </summary>
    /// <exception cref="InvalidOperationException">Danh mục và alias không khớp nhau.</exception>
    public PermissionCatalogSnapshot DiscoverAndValidate()
    {
        var endpointsByPermission = new Dictionary<string, List<string>>(StringComparer.OrdinalIgnoreCase);
        var authOnlyEndpoints = new List<string>();
        var controllers = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        // Một method có nhiều attribute HTTP (vd [HttpPut] + [HttpPost]) sinh nhiều
        // ActionDescriptor nhưng vẫn là MỘT endpoint.
        var scannedEndpoints = new HashSet<string>(StringComparer.OrdinalIgnoreCase);

        foreach (var action in actionDescriptors.ActionDescriptors.Items.OfType<ControllerActionDescriptor>())
        {
            var metadata = action.EndpointMetadata;

            // [AllowAnonymous] thắng [HasPermission] ở runtime => bỏ qua y hệt để báo cáo khớp thực tế
            if (metadata.OfType<IAllowAnonymous>().Any())
            {
                continue;
            }

            var endpointKey = $"{action.ControllerName}.{action.ActionName}";
            var aliases = metadata.OfType<HasPermissionAttribute>().ToList();

            if (aliases.Count == 0)
            {
                if (metadata.OfType<IAuthorizeData>().Any())
                {
                    authOnlyEndpoints.Add(endpointKey);
                }

                continue;
            }

            scannedEndpoints.Add(endpointKey);
            controllers.Add(action.ControllerName);

            foreach (var alias in aliases)
            {
                if (!endpointsByPermission.TryGetValue(alias.Permission, out var list))
                {
                    endpointsByPermission[alias.Permission] = list = new List<string>();
                }

                if (!list.Contains(endpointKey, StringComparer.OrdinalIgnoreCase))
                {
                    list.Add(endpointKey);
                }
            }
        }

        // --- Kiểm tra 1: alias trỏ tới quyền chưa khai báo trong Catalog ---
        var undeclared = endpointsByPermission.Keys
            .Where(id => !AppPermissions.ById.ContainsKey(id))
            .OrderBy(id => id, StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (undeclared.Count > 0)
        {
            throw new InvalidOperationException(
                "[PermissionCatalog] Alias [HasPermission] đang dùng quyền chưa khai báo trong AppPermissions.Catalog: " +
                string.Join(", ", undeclared) +
                ". Hãy thêm hằng số và dòng tương ứng vào AppPermissions.Catalog.");
        }

        // --- Kiểm tra 2: quyền đã khai báo nhưng không endpoint nào sử dụng ---
        var unused = AppPermissions.Catalog
            .Where(m => !m.Reserved && !endpointsByPermission.ContainsKey(m.Id))
            .Select(m => m.Id)
            .OrderBy(id => id, StringComparer.OrdinalIgnoreCase)
            .ToList();

        if (unused.Count > 0)
        {
            throw new InvalidOperationException(
                "[PermissionCatalog] Quyền đã khai báo nhưng không endpoint nào sử dụng: " +
                string.Join(", ", unused) +
                ". Hãy gắn alias [HasPermission] cho endpoint tương ứng, hoặc đặt Reserved: true nếu chủ ý chưa dùng.");
        }

        var snapshot = new PermissionCatalogSnapshot(
            AppPermissions.Catalog,
            endpointsByPermission.ToDictionary(
                kv => kv.Key,
                kv => (IReadOnlyList<string>)kv.Value.AsReadOnly(),
                StringComparer.OrdinalIgnoreCase),
            authOnlyEndpoints.OrderBy(x => x, StringComparer.OrdinalIgnoreCase).ToList(),
            scannedEndpoints.Count,
            controllers.Count);

        LogDiscoveryReport(snapshot);
        return snapshot;
    }

    /// <summary>
    /// Đồng bộ danh mục chuẩn xuống bảng <c>permissions</c>. Chỉ INSERT quyền mới và
    /// UPDATE metadata thay đổi — tuyệt đối không xoá quyền đã ngừng sử dụng.
    /// </summary>
    public async Task<PermissionSyncResult> SyncToDatabaseAsync(
        PermissionCatalogSnapshot snapshot,
        CancellationToken cancellationToken = default)
    {
        var existing = await context.Permissions
            .AsNoTracking()
            .ToDictionaryAsync(p => p.PermissionId, StringComparer.OrdinalIgnoreCase, cancellationToken);

        var inserted = new List<string>();
        var updated = new List<string>();
        var toWrite = new List<PermissionMeta>();

        foreach (var meta in snapshot.Catalog)
        {
            if (!existing.TryGetValue(meta.Id, out var current))
            {
                inserted.Add(meta.Id);
                toWrite.Add(meta);
                continue;
            }

            var metadataChanged =
                !string.Equals(current.PermissionName, meta.Name, StringComparison.Ordinal) ||
                !string.Equals(current.Module, meta.Module, StringComparison.Ordinal) ||
                !string.Equals(current.Description, meta.Description, StringComparison.Ordinal);

            if (metadataChanged)
            {
                updated.Add(meta.Id);
                toWrite.Add(meta);
            }
        }

        if (toWrite.Count > 0)
        {
            await using var transaction = await context.Database.BeginTransactionAsync(cancellationToken);

            foreach (var meta in toWrite)
            {
                var parameters = new object[]
                {
                    meta.Id,
                    meta.Name,
                    meta.Module,
                    (object?)meta.Description ?? DBNull.Value
                };

                await context.Database.ExecuteSqlRawAsync(UpsertSql, parameters, cancellationToken);
            }

            await transaction.CommitAsync(cancellationToken);
        }

        // Quyền mồ côi: còn trong CSDL nhưng không còn trong danh mục chuẩn.
        // KHÔNG BAO GIỜ tự xoá — khoá ngoại role_permissions là Cascade.
        var legacy = existing.Keys
            .Where(id => !AppPermissions.ById.ContainsKey(id))
            .OrderBy(id => id, StringComparer.OrdinalIgnoreCase)
            .ToList();

        logger.LogInformation(
            "[PermissionCatalog] Đồng bộ CSDL: +{Inserted} thêm mới | ~{Updated} cập nhật | ={Unchanged} không đổi.",
            inserted.Count,
            updated.Count,
            snapshot.Catalog.Count - inserted.Count - updated.Count);

        if (legacy.Count > 0)
        {
            logger.LogWarning(
                "[PermissionCatalog] {Count} quyền đã ngừng sử dụng (còn trong CSDL, không còn trong danh mục chuẩn): {Legacy}. " +
                "Giữ nguyên để bảo toàn cấu hình vai trò — không thể gán cho vai trò mới.",
                legacy.Count,
                string.Join(", ", legacy));
        }

        return new PermissionSyncResult(inserted, updated, legacy, existing.Count);
    }

    private void LogDiscoveryReport(PermissionCatalogSnapshot snapshot)
    {
        var reserved = snapshot.Catalog
            .Where(m => m.Reserved)
            .Select(m => m.Id)
            .ToList();

        logger.LogInformation(
            "[PermissionCatalog] Đã quét {Controllers} controller / {Endpoints} endpoint có alias phân quyền.",
            snapshot.ControllerCount,
            snapshot.ScannedEndpointCount);

        logger.LogInformation(
            "[PermissionCatalog] Danh mục chuẩn: {Total} quyền ({Active} đang gắn endpoint, {Reserved} Reserved chủ ý chưa dùng).",
            snapshot.Catalog.Count,
            snapshot.ActiveIds.Count,
            reserved.Count);

        if (reserved.Count > 0)
        {
            logger.LogInformation(
                "[PermissionCatalog] Reserved (chưa gắn endpoint nào): {Reserved}",
                string.Join(", ", reserved));
        }

        if (snapshot.AuthOnlyEndpoints.Count > 0)
        {
            logger.LogInformation(
                "[PermissionCatalog] {Count} endpoint chỉ yêu cầu đăng nhập, không phân quyền chi tiết — cần rà soát: {Endpoints}",
                snapshot.AuthOnlyEndpoints.Count,
                string.Join(", ", snapshot.AuthOnlyEndpoints));
        }
    }
}
