using System.Text.Json;
using System.Text.Json.Serialization;
using Microsoft.EntityFrameworkCore;
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
        public string Role { get; set; } = "USER";
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
    public static async Task SeedAsync(AppDbContext context, ILogger logger)
    {
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

                if (Enum.TryParse<UserRoleType>(acc.Role, true, out var roleType))
                {
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

                        newUser.UserRoles.Add(new UserRole
                        {
                            RoleId = roleType,
                            AssignedAt = DateTime.UtcNow
                        });

                        context.Users.Add(newUser);
                        await context.SaveChangesAsync();
                        logger.LogInformation("✅ [DbInitializer] Đã tạo tài khoản {Role}: {Email} (Mật khẩu: {Password})", roleType, acc.Email, acc.Password);
                    }
                    else if (!exists.UserRoles.Any(ur => ur.RoleId == roleType))
                    {
                        exists.UserRoles.Add(new UserRole
                        {
                            UserId = exists.UserId,
                            RoleId = roleType,
                            AssignedAt = DateTime.UtcNow
                        });
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
}

