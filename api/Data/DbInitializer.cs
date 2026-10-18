using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
using WebBanHang.Api.Common;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.Data;

public static class DbInitializer
{
    private class AccountSeedDto
    {
        public string Username { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string? Phone { get; set; }
        public string? Role { get; set; }
        public List<string>? Roles { get; set; }
    }

    private class PromotionSeedDto
    {
        public string Name { get; set; } = string.Empty;
        public string? Description { get; set; }
        public string DiscountType { get; set; } = "PERCENTAGE";
        public decimal DiscountValue { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public bool IsActive { get; set; } = true;
        public List<int>? VariantIds { get; set; }
    }

    private class VoucherSeedDto
    {
        public string Code { get; set; } = string.Empty;
        public string Title { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DiscountType DiscountType { get; set; } = DiscountType.PERCENTAGE;
        public decimal DiscountValue { get; set; }
        public decimal MinOrderValue { get; set; }
        public decimal? MaxDiscountAmount { get; set; }
        public int? UsageLimit { get; set; }
        public int LimitPerUser { get; set; } = 1;
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public bool IsActive { get; set; } = true;
        public bool IsPublic { get; set; } = true;
    }

    private class FullDummyData
    {
        public List<AccountSeedDto>? Accounts { get; set; }
        public List<Supplier>? Suppliers { get; set; }
        public List<Category>? Categories { get; set; }
        public List<Product>? Products { get; set; }
        public List<ProductVariant>? ProductVariants { get; set; }
        public List<PromotionSeedDto>? Promotions { get; set; }
        public List<VoucherSeedDto>? Vouchers { get; set; }
    }

    /// <summary>
    /// Tự động nạp toàn bộ dữ liệu mẫu (Dummy Data) từ Data/dummy_data.json khi hệ thống khởi động.
    /// Bao gồm: Tài khoản nhân viên/Admin, Vouchers, Khuyến mãi, và Sản phẩm mở rộng.
    /// </summary>
    /// <remarks>
    /// Danh mục quyền hạn KHÔNG còn được đọc từ file JSON. Nó được PermissionCatalogBuilder
    /// quét trực tiếp từ alias [HasPermission] trên endpoint và đồng bộ xuống CSDL trước khi
    /// hàm này được gọi (xem Program.cs bước 8.1 và 8.2).
    /// </remarks>
    /// <param name="context">DbContext đang thao tác.</param>
    /// <param name="logger">Logger ghi nhận tiến trình seed.</param>
    /// <param name="isFirstInstall">
    /// True nếu đây là lần khởi động đầu tiên trên một CSDL trắng. Chỉ khi đó hệ thống mới áp
    /// bộ quyền mặc định cho các vai trò hệ thống; những lần sau sẽ tôn trọng cấu hình mà
    /// Quản trị viên đã thiết lập qua giao diện.
    /// </param>
    public static async Task SeedAsync(AppDbContext context, ILogger logger, bool isFirstInstall = false)
    {
        // 0. Luôn luôn đồng bộ Vai trò hệ thống trước tiên
        await SeedPermissionsAndRolesAsync(context, logger, isFirstInstall);
        await EnsureDefaultAdminAccountAsync(context, logger);

        var candidatePaths = new[]
        {
            Path.Combine(AppContext.BaseDirectory, "Data", "dummy_data.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "Data", "dummy_data.json"),
            Path.Combine(Directory.GetCurrentDirectory(), "api", "Data", "dummy_data.json"),
            Path.Combine(AppContext.BaseDirectory, "..", "..", "..", "Data", "dummy_data.json")
        };

        string? jsonPath = candidatePaths.FirstOrDefault(File.Exists);
        if (jsonPath == null)
        {
            return;
        }

        FullDummyData? data;
        try
        {
            var json = await File.ReadAllTextAsync(jsonPath);
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };
            options.Converters.Add(new JsonStringEnumConverter());
            data = JsonSerializer.Deserialize<FullDummyData>(json, options);
        }
        catch (Exception ex)
        {
            logger.LogWarning(ex, "[DbInitializer] Không thể đọc file dummy_data.json: {Message}", ex.Message);
            return;
        }

        if (data == null) return;

        // 1. Seed danh sách tài khoản mẫu (Admin, Kho, Bán hàng, Khảo sát, Khách hàng)
        if (data.Accounts != null && data.Accounts.Count > 0)
        {
            foreach (var acc in data.Accounts)
            {
                var emailTrimmed = acc.Email.Trim().ToLower();
                var exists = await context.Users
                    .Include(u => u.UserRoles)
                    .FirstOrDefaultAsync(u => u.Email.ToLower() == emailTrimmed);

                var rolesToAssign = new List<string>();
                if (acc.Roles != null && acc.Roles.Count > 0)
                {
                    rolesToAssign.AddRange(acc.Roles.Select(r => r.Trim().ToUpper()));
                }
                else if (!string.IsNullOrWhiteSpace(acc.Role))
                {
                    rolesToAssign.Add(acc.Role.Trim().ToUpper());
                }
                else
                {
                    rolesToAssign.Add("USER");
                }
                rolesToAssign = rolesToAssign.Distinct().ToList();

                if (exists == null)
                {
                    var username = acc.Username.Trim();
                    if (await context.Users.AnyAsync(u => u.Username.ToLower() == username.ToLower()))
                    {
                        username = $"{username}_{Guid.NewGuid().ToString("N")[..4]}";
                    }

                    var newUser = new User
                    {
                        Username = username,
                        Email = emailTrimmed,
                        FullName = acc.FullName.Trim(),
                        PasswordHash = BCrypt.Net.BCrypt.HashPassword(acc.Password),
                        Phone = acc.Phone?.Trim(),
                        IsLocked = false,
                        CreatedAt = DateTime.UtcNow
                    };

                    foreach (var roleId in rolesToAssign)
                    {
                        newUser.UserRoles.Add(new UserRole
                        {
                            RoleId = roleId,
                            AssignedAt = DateTime.UtcNow
                        });
                    }

                    context.Users.Add(newUser);
                    await context.SaveChangesAsync();
                    logger.LogInformation("✅ [DbInitializer] Đã tạo tài khoản [{Roles}]: {Email} (Mật khẩu: {Password})", string.Join(", ", rolesToAssign), acc.Email, acc.Password);
                }
                else
                {
                    var hasNewRole = false;
                    foreach (var roleId in rolesToAssign)
                    {
                        if (!exists.UserRoles.Any(ur => ur.RoleId == roleId))
                        {
                            exists.UserRoles.Add(new UserRole
                            {
                                UserId = exists.UserId,
                                RoleId = roleId,
                                AssignedAt = DateTime.UtcNow
                            });
                            hasNewRole = true;
                        }
                    }
                    if (hasNewRole)
                    {
                        await context.SaveChangesAsync();
                    }
                }
            }
        }

        // 2. Seed Nhà cung cấp mở rộng
        if (data.Suppliers != null)
        {
            try
            {
                foreach (var s in data.Suppliers)
                {
                    if (!await context.Suppliers.IgnoreQueryFilters().AnyAsync(existing => existing.SupplierId == s.SupplierId || existing.SupplierName == s.SupplierName))
                    {
                        context.Suppliers.Add(new Supplier
                        {
                            SupplierId = s.SupplierId,
                            SupplierName = s.SupplierName,
                            Phone = s.Phone,
                            Email = s.Email,
                            Address = s.Address,
                            CreatedAt = s.CreatedAt
                        });
                    }
                }
                await context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "[DbInitializer] Không thể nạp toàn bộ Nhà cung cấp: {Message}", ex.Message);
            }
        }

        // 3. Seed Danh mục mở rộng
        if (data.Categories != null)
        {
            try
            {
                foreach (var c in data.Categories)
                {
                    if (!await context.Categories.AnyAsync(existing => existing.CategoryId == c.CategoryId || existing.CategoryName == c.CategoryName))
                    {
                        context.Categories.Add(new Category
                        {
                            CategoryId = c.CategoryId,
                            CategoryName = c.CategoryName,
                            CreatedAt = c.CreatedAt
                        });
                    }
                }
                await context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "[DbInitializer] Không thể nạp toàn bộ Danh mục: {Message}", ex.Message);
            }
        }

        // 4. Seed Sản phẩm mở rộng
        if (data.Products != null)
        {
            try
            {
                foreach (var p in data.Products)
                {
                    if (!await context.Products.AnyAsync(existing => existing.ProductId == p.ProductId))
                    {
                        context.Products.Add(new Product
                        {
                            ProductId = p.ProductId,
                            ProductName = p.ProductName,
                            CategoryId = p.CategoryId,
                            Description = p.Description,
                            ImageUrl = p.ImageUrl,
                            VariantAttributes = p.VariantAttributes ?? new List<string>(),
                            IsActive = p.IsActive,
                            CreatedAt = p.CreatedAt
                        });
                    }
                }
                await context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "[DbInitializer] Không thể nạp toàn bộ Sản phẩm: {Message}", ex.Message);
            }
        }

        // 5. Seed Biến thể sản phẩm mở rộng
        if (data.ProductVariants != null)
        {
            try
            {
                foreach (var v in data.ProductVariants)
                {
                    if (!await context.ProductVariants.AnyAsync(existing => existing.VariantId == v.VariantId))
                    {
                        context.ProductVariants.Add(new ProductVariant
                        {
                            VariantId = v.VariantId,
                            ProductId = v.ProductId,
                            VariantName = v.VariantName,
                            Price = v.Price,
                            StockQuantity = v.StockQuantity,
                            ImageUrl = v.ImageUrl,
                            Attributes = v.Attributes ?? new Dictionary<string, string>(),
                            IsActive = v.IsActive,
                            CreatedAt = v.CreatedAt
                        });
                    }
                }
                await context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "[DbInitializer] Không thể nạp toàn bộ Biến thể sản phẩm: {Message}", ex.Message);
            }
        }

        // 6. Seed Vouchers mẫu
        if (data.Vouchers != null && data.Vouchers.Count > 0)
        {
            try
            {
                foreach (var v in data.Vouchers)
                {
                    var codeUpper = v.Code.Trim().ToUpper();
                    if (!await context.Vouchers.AnyAsync(existing => existing.Code == codeUpper))
                    {
                        context.Vouchers.Add(new Voucher
                        {
                            Code = codeUpper,
                            Title = v.Title.Trim(),
                            Description = v.Description?.Trim(),
                            DiscountType = v.DiscountType,
                            DiscountValue = v.DiscountValue,
                            MinOrderValue = v.MinOrderValue,
                            MaxDiscountAmount = v.MaxDiscountAmount,
                            UsageLimit = v.UsageLimit,
                            UsedCount = 0,
                            LimitPerUser = v.LimitPerUser,
                            StartDate = v.StartDate,
                            EndDate = v.EndDate,
                            IsActive = v.IsActive,
                            IsPublic = v.IsPublic,
                            CreatedAt = DateTime.UtcNow
                        });
                        logger.LogInformation("🏷️ [DbInitializer] Đã nạp Voucher mẫu: {Code} ({Title})", codeUpper, v.Title);
                    }
                }
                await context.SaveChangesAsync();
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "[DbInitializer] Không thể nạp toàn bộ Voucher: {Message}", ex.Message);
            }
        }

        // 7. Seed Chương trình Khuyến mãi (Promotions) & gắn biến thể
        if (data.Promotions != null && data.Promotions.Count > 0)
        {
            try
            {
                foreach (var promoDto in data.Promotions)
                {
                    var promoName = promoDto.Name.Trim();
                    var promo = await context.Promotions
                        .Include(p => p.Variants)
                        .FirstOrDefaultAsync(p => p.Name == promoName);

                    if (promo == null)
                    {
                        promo = new Promotion
                        {
                            Name = promoName,
                            Description = promoDto.Description?.Trim(),
                            DiscountType = promoDto.DiscountType,
                            DiscountValue = promoDto.DiscountValue,
                            StartDate = promoDto.StartDate,
                            EndDate = promoDto.EndDate,
                            IsActive = promoDto.IsActive,
                            CreatedAt = DateTime.UtcNow
                        };

                        if (promoDto.VariantIds != null && promoDto.VariantIds.Count > 0)
                        {
                            var variantsToAttach = await context.ProductVariants
                                .Where(pv => promoDto.VariantIds.Contains(pv.VariantId))
                                .ToListAsync();

                            foreach (var v in variantsToAttach)
                            {
                                promo.Variants.Add(v);
                            }
                        }

                        context.Promotions.Add(promo);
                        await context.SaveChangesAsync();
                        logger.LogInformation("🔥 [DbInitializer] Đã nạp Khuyến mãi mẫu: {Name} ({Type}: {Value})", promo.Name, promo.DiscountType, promo.DiscountValue);
                    }
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "[DbInitializer] Không thể nạp toàn bộ Khuyến mãi: {Message}", ex.Message);
            }
        }

        // 8. Đồng bộ sequence ID trong PostgreSQL để tránh lỗi duplicate key sau này
        try
        {
            await context.Database.ExecuteSqlRawAsync(@"
                DO $$
                BEGIN
                    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'Suppliers') THEN
                        PERFORM setval(pg_get_serial_sequence('""Suppliers""', 'SupplierId'), COALESCE(MAX(""SupplierId""), 1)) FROM ""Suppliers"";
                    END IF;
                    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'categories') THEN
                        PERFORM setval(pg_get_serial_sequence('categories', 'category_id'), COALESCE(MAX(category_id), 1)) FROM categories;
                    END IF;
                    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'products') THEN
                        PERFORM setval(pg_get_serial_sequence('products', 'product_id'), COALESCE(MAX(product_id), 1)) FROM products;
                    END IF;
                    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'product_variants') THEN
                        PERFORM setval(pg_get_serial_sequence('product_variants', 'variant_id'), COALESCE(MAX(variant_id), 1)) FROM product_variants;
                    END IF;
                    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'vouchers') THEN
                        PERFORM setval(pg_get_serial_sequence('vouchers', 'voucher_id'), COALESCE(MAX(voucher_id), 1)) FROM vouchers;
                    END IF;
                    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'promotions') THEN
                        PERFORM setval(pg_get_serial_sequence('promotions', 'promotion_id'), COALESCE(MAX(promotion_id), 1)) FROM promotions;
                    END IF;
                END $$;
            ");
        }
        catch (Exception ex)
        {
            logger.LogDebug("[DbInitializer] Cập nhật PostgreSQL sequence: {Message}", ex.Message);
        }
    }

    private static async Task SeedPermissionsAndRolesAsync(AppDbContext context, ILogger logger, bool isFirstInstall)
    {
        // 1. Danh mục quyền hạn đã được PermissionCatalogBuilder đồng bộ xuống bảng permissions
        //    trước khi hàm này chạy; ở đây chỉ đọc lại để phân quyền cho các vai trò hệ thống.
        var allPermIds = await context.Permissions.Select(p => p.PermissionId).ToListAsync();
        if (allPermIds.Count == 0)
        {
            logger.LogWarning("[DbInitializer] Bảng permissions rỗng — bỏ qua bước phân quyền vai trò.");
            return;
        }

        var allPermSet = new HashSet<string>(allPermIds, StringComparer.OrdinalIgnoreCase);

        // 2. Đảm bảo các Vai trò chuẩn tồn tại.
        var systemRoles = new[]
        {
            new Role { RoleId = "ADMIN", RoleName = "Quản trị viên", IsSystem = true },
            new Role { RoleId = "WAREHOUSE_STAFF", RoleName = "Nhân viên quản lý kho", IsSystem = true },
            new Role { RoleId = "SALES_STAFF", RoleName = "Nhân viên bán hàng", IsSystem = true },
            new Role { RoleId = "SURVEY_STAFF", RoleName = "Nhân viên khảo sát & CRM", IsSystem = true },
            new Role { RoleId = "USER", RoleName = "Khách hàng", IsSystem = true }
        };

        var existingRoleIds = await context.Roles.Select(r => r.RoleId).ToListAsync();
        var existingRoleSet = new HashSet<string>(existingRoleIds, StringComparer.OrdinalIgnoreCase);
        var createdRoleIds = new List<string>();

        foreach (var sr in systemRoles)
        {
            if (existingRoleSet.Contains(sr.RoleId))
            {
                continue;
            }

            context.Roles.Add(sr);
            createdRoleIds.Add(sr.RoleId);
        }

        if (createdRoleIds.Count > 0)
        {
            await context.SaveChangesAsync();
        }

        // 3. Áp quyền mặc định: vai trò chuẩn đã được Migration seed sẵn nên không thể dựa vào
        //    "vừa tạo vai trò"; chỉ áp khi CSDL trắng hoặc vai trò mới bổ sung vào mã nguồn.
        var defaultTargets = systemRoles
            .Where(sr => !sr.RoleId.Equals("ADMIN", StringComparison.OrdinalIgnoreCase))
            .Where(sr => AppPermissions.DefaultRolePermissions.TryGetValue(sr.RoleId, out var d) && d.Count > 0)
            .Where(sr => isFirstInstall ||
                         createdRoleIds.Contains(sr.RoleId, StringComparer.OrdinalIgnoreCase))
            .Select(sr => sr.RoleId)
            .ToList();

        if (defaultTargets.Count > 0)
        {
            // Chốt an toàn: chỉ áp cho vai trò hiện chưa có BẤT KỲ quyền nào,
            // để không bao giờ chồng lên cấu hình đã có.
            var rolesWithPermissions = new HashSet<string>(
                await context.RolePermissions
                    .Where(rp => defaultTargets.Contains(rp.RoleId))
                    .Select(rp => rp.RoleId)
                    .Distinct()
                    .ToListAsync(),
                StringComparer.OrdinalIgnoreCase);

            var defaultAssignments = new List<RolePermission>();

            foreach (var roleId in defaultTargets.Where(id => !rolesWithPermissions.Contains(id)))
            {
                foreach (var pid in AppPermissions.DefaultRolePermissions[roleId])
                {
                    if (!allPermSet.Contains(pid))
                    {
                        logger.LogWarning(
                            "[DbInitializer] Quyền mặc định '{Permission}' của vai trò {Role} không tồn tại trong CSDL — đã bỏ qua.",
                            pid,
                            roleId);
                        continue;
                    }

                    defaultAssignments.Add(new RolePermission
                    {
                        RoleId = roleId,
                        PermissionId = pid,
                        AssignedAt = DateTime.UtcNow
                    });
                }
            }

            if (defaultAssignments.Count > 0)
            {
                context.RolePermissions.AddRange(defaultAssignments);
                await context.SaveChangesAsync();
            }

            logger.LogInformation(
                "✅ [DbInitializer] Đã áp {PermCount} quyền mặc định cho {RoleCount} vai trò hệ thống: {Roles}",
                defaultAssignments.Count,
                defaultTargets.Count,
                string.Join(", ", defaultTargets));
        }

        // 4. ADMIN luôn được cấp toàn quyền trên mọi quyền hiện có, kể cả quyền mới bổ sung sau này.
        //    Đây là chủ ý thiết kế: ADMIN là vai trò siêu quản trị, không phụ thuộc cấu hình thủ công.
        var adminExistingPerms = await context.RolePermissions
            .Where(rp => rp.RoleId == "ADMIN")
            .Select(rp => rp.PermissionId)
            .ToListAsync();
        var adminPermSet = new HashSet<string>(adminExistingPerms, StringComparer.OrdinalIgnoreCase);

        var adminNewRolePerms = allPermIds
            .Where(pid => !adminPermSet.Contains(pid))
            .Select(pid => new RolePermission
            {
                RoleId = "ADMIN",
                PermissionId = pid,
                AssignedAt = DateTime.UtcNow
            })
            .ToList();

        if (adminNewRolePerms.Count > 0)
        {
            context.RolePermissions.AddRange(adminNewRolePerms);
            await context.SaveChangesAsync();
            logger.LogInformation(
                "✅ [DbInitializer] Đã cấp thêm {Count} quyền mới cho vai trò ADMIN.",
                adminNewRolePerms.Count);
        }

        logger.LogInformation("✅ [DbInitializer] Hoàn tất đồng bộ vai trò và quyền hạn hệ thống.");
    }

    private static async Task EnsureDefaultAdminAccountAsync(AppDbContext context, ILogger logger)
    {
        var hasAdmin = await context.UserRoles.AnyAsync(ur => ur.RoleId == "ADMIN");
        if (!hasAdmin)
        {
            var adminEmail = "admin@techstoree.vn";
            var existingUser = await context.Users
                .Include(u => u.UserRoles)
                .FirstOrDefaultAsync(u => u.Email.ToLower() == adminEmail);

            if (existingUser != null)
            {
                if (!existingUser.UserRoles.Any(ur => ur.RoleId == "ADMIN"))
                {
                    existingUser.UserRoles.Add(new UserRole
                    {
                        RoleId = "ADMIN",
                        AssignedAt = DateTime.UtcNow
                    });
                    await context.SaveChangesAsync();
                    logger.LogInformation("✅ [DbInitializer] Đã gán vai trò ADMIN cho tài khoản {Email}", adminEmail);
                }
            }
            else
            {
                var adminUser = new User
                {
                    Username = "admin",
                    Email = adminEmail,
                    FullName = "Quản Trị Viên Hệ Thống",
                    PasswordHash = BCrypt.Net.BCrypt.HashPassword("admin123"),
                    Phone = "0900000001",
                    IsLocked = false,
                    CreatedAt = DateTime.UtcNow
                };
                adminUser.UserRoles.Add(new UserRole
                {
                    RoleId = "ADMIN",
                    AssignedAt = DateTime.UtcNow
                });
                context.Users.Add(adminUser);
                await context.SaveChangesAsync();
                logger.LogInformation("✅ [DbInitializer] Đã khởi tạo tài khoản ADMIN mặc định: {Email} (Mật khẩu: admin123)", adminEmail);
            }
        }
    }
}

