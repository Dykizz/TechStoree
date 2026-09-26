using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<Role> Roles => Set<Role>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Supplier> Suppliers => Set<Supplier>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<ProductVariant> ProductVariants => Set<ProductVariant>();
    public DbSet<PurchaseOrder> PurchaseOrders => Set<PurchaseOrder>();
    public DbSet<PurchaseOrderItem> PurchaseOrderItems => Set<PurchaseOrderItem>();
    public DbSet<Cart> Carts => Set<Cart>();
    public DbSet<CartItem> CartItems => Set<CartItem>();
    public DbSet<Promotion> Promotions => Set<Promotion>();


    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // 1. Cấu hình bảng Roles
        modelBuilder.Entity<Role>(entity =>
        {
            entity.HasKey(r => r.RoleId);
            entity.Property(r => r.RoleId).HasMaxLength(20);
            entity.Property(r => r.RoleName).IsRequired().HasMaxLength(50);
        });

        // 2. Cấu hình bảng Users
        modelBuilder.Entity<User>(entity =>
        {
            entity.HasKey(u => u.UserId);
            entity.HasIndex(u => u.Username).IsUnique();
            entity.HasIndex(u => u.Email).IsUnique();

            entity.HasOne(u => u.Role)
                  .WithMany(r => r.Users)
                  .HasForeignKey(u => u.RoleId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        // 3. Cấu hình bảng Suppliers
        modelBuilder.Entity<Supplier>(entity =>
        {
            entity.HasKey(s => s.SupplierId);
            entity.Property(s => s.SupplierName).IsRequired().HasMaxLength(150);
            entity.Property(s => s.Phone).IsRequired().HasMaxLength(20);
            entity.Property(s => s.Email).HasMaxLength(100);
            entity.Property(s => s.Address).HasMaxLength(255);
            entity.Property(s => s.CreatedAt).HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(s => s.DeletedAt);

            // Tự động bỏ qua các bản ghi đã bị xóa mềm
            entity.HasQueryFilter(s => s.DeletedAt == null);
        });

        // 4. Cấu hình bảng Categories (Không dùng Soft Delete - Áp dụng Cách 1)
        modelBuilder.Entity<Category>(entity =>
        {
            entity.ToTable("categories");
            entity.HasKey(c => c.CategoryId);
            entity.Property(c => c.CategoryId).HasColumnName("category_id");
            entity.Property(c => c.CategoryName).HasColumnName("category_name").IsRequired().HasMaxLength(100);
            entity.HasIndex(c => c.CategoryName).IsUnique();
            entity.Property(c => c.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("CURRENT_TIMESTAMP");
        });

        // 5. Cấu hình bảng Products
        modelBuilder.Entity<Product>(entity =>
        {
            entity.ToTable("products");
            entity.HasKey(p => p.ProductId);
            entity.Property(p => p.ProductId).HasColumnName("product_id");
            entity.Property(p => p.ProductName).HasColumnName("product_name").IsRequired().HasMaxLength(200);
            entity.Property(p => p.CategoryId).HasColumnName("category_id");
            entity.Property(p => p.Description).HasColumnName("description");
            entity.Property(p => p.ImageUrl).HasColumnName("image_url").HasMaxLength(500);
            var stringListComparer = new ValueComparer<List<string>>(
                (c1, c2) => (c1 == null && c2 == null) || (c1 != null && c2 != null && c1.SequenceEqual(c2)),
                c => c.Aggregate(0, (a, v) => HashCode.Combine(a, v.GetHashCode())),
                c => c.ToList()
            );

            entity.Property(p => p.VariantAttributes)
                  .HasColumnName("variant_attributes")
                  .HasColumnType("jsonb")
                  .HasConversion(
                      v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                      v => JsonSerializer.Deserialize<List<string>>(v, (JsonSerializerOptions?)null) ?? new List<string>()
                  )
                  .Metadata.SetValueComparer(stringListComparer);
            entity.Property(p => p.IsActive).HasColumnName("is_active").HasDefaultValue(true);
            entity.Property(p => p.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("CURRENT_TIMESTAMP");

            entity.HasOne(p => p.Category)
                  .WithMany(c => c.Products)
                  .HasForeignKey(p => p.CategoryId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        // 6. Cấu hình bảng ProductVariants
        modelBuilder.Entity<ProductVariant>(entity =>
        {
            entity.ToTable("product_variants");
            entity.HasKey(v => v.VariantId);
            entity.Property(v => v.VariantId).HasColumnName("variant_id");
            entity.Property(v => v.ProductId).HasColumnName("product_id");
            entity.Property(v => v.VariantName).HasColumnName("variant_name").IsRequired().HasMaxLength(150);
            entity.Property(v => v.Price).HasColumnName("price").HasColumnType("decimal(12,0)");
            entity.Property(v => v.StockQuantity).HasColumnName("stock_quantity").HasDefaultValue(0);
            entity.Property(v => v.ImageUrl).HasColumnName("image_url").HasMaxLength(500);

            var stringDictComparer = new ValueComparer<Dictionary<string, string>>(
                (d1, d2) => (d1 == null && d2 == null) || (d1 != null && d2 != null && d1.OrderBy(kv => kv.Key).SequenceEqual(d2.OrderBy(kv => kv.Key))),
                d => d.Aggregate(0, (a, p) => HashCode.Combine(a, p.Key.GetHashCode(), p.Value.GetHashCode())),
                d => new Dictionary<string, string>(d)
            );

            entity.Property(v => v.Attributes)
                  .HasColumnName("attributes")
                  .HasColumnType("jsonb")
                  .HasConversion(
                      v => JsonSerializer.Serialize(v, (JsonSerializerOptions?)null),
                      v => JsonSerializer.Deserialize<Dictionary<string, string>>(v, (JsonSerializerOptions?)null) ?? new Dictionary<string, string>()
                  )
                  .Metadata.SetValueComparer(stringDictComparer);
            entity.Property(v => v.IsActive).HasColumnName("is_active").HasDefaultValue(true);
            entity.Property(v => v.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("CURRENT_TIMESTAMP");

            entity.HasOne(v => v.Product)
                  .WithMany(p => p.Variants)
                  .HasForeignKey(v => v.ProductId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // 6.1. Cấu hình bảng PurchaseOrders
        modelBuilder.Entity<PurchaseOrder>(entity =>
        {
            entity.ToTable("purchase_orders");
            entity.HasKey(po => po.PurchaseOrderId);
            entity.Property(po => po.PurchaseOrderId).HasColumnName("purchase_order_id");
            entity.Property(po => po.PoCode).HasColumnName("po_code").IsRequired().HasMaxLength(30);
            entity.HasIndex(po => po.PoCode).IsUnique();
            entity.Property(po => po.SupplierId).HasColumnName("supplier_id");
            entity.Property(po => po.CreatedByUserId).HasColumnName("created_by_user_id");
            entity.Property(po => po.TotalCost).HasColumnName("total_cost").HasColumnType("decimal(12,0)");
            entity.Property(po => po.Status).HasColumnName("status").HasConversion<string>().HasMaxLength(30).HasDefaultValue(PurchaseOrderStatus.DRAFT);
            entity.Property(po => po.Note).HasColumnName("note");
            entity.Property(po => po.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("CURRENT_TIMESTAMP");

            entity.HasOne(po => po.Supplier)
                  .WithMany()
                  .HasForeignKey(po => po.SupplierId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(po => po.CreatedByUser)
                  .WithMany()
                  .HasForeignKey(po => po.CreatedByUserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasMany(po => po.Items)
                  .WithOne(poi => poi.PurchaseOrder)
                  .HasForeignKey(poi => poi.PurchaseOrderId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // 6.2. Cấu hình bảng PurchaseOrderItems
        modelBuilder.Entity<PurchaseOrderItem>(entity =>
        {
            entity.ToTable("purchase_order_items");
            entity.HasKey(poi => poi.PoItemId);
            entity.Property(poi => poi.PoItemId).HasColumnName("po_item_id");
            entity.Property(poi => poi.PurchaseOrderId).HasColumnName("purchase_order_id");
            entity.Property(poi => poi.VariantId).HasColumnName("variant_id");
            entity.Property(poi => poi.ImportPrice).HasColumnName("import_price").HasColumnType("decimal(12,0)");
            entity.Property(poi => poi.Quantity).HasColumnName("quantity");

            entity.HasOne(poi => poi.Variant)
                  .WithMany()
                  .HasForeignKey(poi => poi.VariantId)
                  .OnDelete(DeleteBehavior.Restrict);
        });

        // 7. Cấu hình bảng Carts
        modelBuilder.Entity<Cart>(entity =>
        {
            entity.ToTable("carts");
            entity.HasKey(c => c.CartId);
            entity.Property(c => c.CartId).HasColumnName("cart_id");
            entity.Property(c => c.UserId).HasColumnName("user_id");
            entity.Property(c => c.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(c => c.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("CURRENT_TIMESTAMP");

            entity.HasIndex(c => c.UserId).IsUnique();

            entity.HasOne(c => c.User)
                  .WithOne(u => u.Cart)
                  .HasForeignKey<Cart>(c => c.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // 8. Cấu hình bảng CartItems
        modelBuilder.Entity<CartItem>(entity =>
        {
            entity.ToTable("cart_items");
            entity.HasKey(ci => ci.CartItemId);
            entity.Property(ci => ci.CartItemId).HasColumnName("cart_item_id");
            entity.Property(ci => ci.CartId).HasColumnName("cart_id");
            entity.Property(ci => ci.VariantId).HasColumnName("variant_id");
            entity.Property(ci => ci.Quantity).HasColumnName("quantity");
            entity.Property(ci => ci.AddedAt).HasColumnName("added_at").HasDefaultValueSql("CURRENT_TIMESTAMP");

            entity.HasIndex(ci => new { ci.CartId, ci.VariantId }).IsUnique();

            entity.HasOne(ci => ci.Cart)
                  .WithMany(c => c.Items)
                  .HasForeignKey(ci => ci.CartId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(ci => ci.Variant)
                  .WithMany()
                  .HasForeignKey(ci => ci.VariantId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // 9. Cấu hình bảng Promotions và quan hệ Nhiều-Nhiều với ProductVariants
        modelBuilder.Entity<Promotion>(entity =>
        {
            entity.ToTable("promotions");
            entity.HasKey(p => p.PromotionId);
            entity.Property(p => p.PromotionId).HasColumnName("promotion_id");
            entity.Property(p => p.Name).HasColumnName("name").IsRequired().HasMaxLength(200);
            entity.Property(p => p.Description).HasColumnName("description");
            entity.Property(p => p.DiscountType).HasColumnName("discount_type").IsRequired().HasMaxLength(20);
            entity.Property(p => p.DiscountValue).HasColumnName("discount_value").HasPrecision(18, 2);
            entity.Property(p => p.StartDate).HasColumnName("start_date");
            entity.Property(p => p.EndDate).HasColumnName("end_date");
            entity.Property(p => p.IsActive).HasColumnName("is_active").HasDefaultValue(true);
            entity.Property(p => p.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("CURRENT_TIMESTAMP");

            entity.HasMany(p => p.Variants)
                  .WithMany(v => v.Promotions)
                  .UsingEntity<Dictionary<string, object>>(
                      "promotion_variants",
                      j => j.HasOne<ProductVariant>().WithMany().HasForeignKey("variant_id"),
                      j => j.HasOne<Promotion>().WithMany().HasForeignKey("promotion_id"),
                      j =>
                      {
                          j.ToTable("promotion_variants");
                          j.HasKey("promotion_id", "variant_id");
                          j.Property<int>("promotion_id").HasColumnName("promotion_id");
                          j.Property<int>("variant_id").HasColumnName("variant_id");
                      });
        });

        // 10. Seed dữ liệu mặc định cho Role (ADMIN và USER)
        modelBuilder.Entity<Role>().HasData(
            new Role { RoleId = "ADMIN", RoleName = "Quản trị viên" },
            new Role { RoleId = "USER", RoleName = "Người dùng" }
        );

        // 8. Seed dữ liệu mẫu cho Suppliers
        modelBuilder.Entity<Supplier>().HasData(
            new Supplier
            {
                SupplierId = 1,
                SupplierName = "Công ty TNHH ASUS Việt Nam",
                Phone = "18006588",
                Email = "support@asus.com.vn",
                Address = "Tầng 5, Tòa nhà Viettel, 285 Cách Mạng Tháng 8, Q.10, TP.HCM",
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new Supplier
            {
                SupplierId = 2,
                SupplierName = "Sony Electronics Việt Nam",
                Phone = "1800588885",
                Email = "contact@sony.com.vn",
                Address = "Tầng 6, Tòa nhà President Place, 93 Nguyễn Du, Q.1, TP.HCM",
                CreatedAt = new DateTime(2026, 1, 2, 0, 0, 0, DateTimeKind.Utc)
            },
            new Supplier
            {
                SupplierId = 3,
                SupplierName = "Apple Authorized Distributor (Synnex FPT)",
                Phone = "02873001010",
                Email = "apple-sales@synnexfpt.com.vn",
                Address = "Tòa nhà FPT Tân Thuận, Lô L.29B-31B-33B, Tân Thuận Đông, Q.7, TP.HCM",
                CreatedAt = new DateTime(2026, 1, 3, 0, 0, 0, DateTimeKind.Utc)
            }
        );

        // 9. Seed dữ liệu mẫu cho Categories (Laptop, Tai nghe, Phụ kiện, SmartHome)
        modelBuilder.Entity<Category>().HasData(
            new Category
            {
                CategoryId = 1,
                CategoryName = "Laptop",
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new Category
            {
                CategoryId = 2,
                CategoryName = "Tai nghe & Âm thanh",
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new Category
            {
                CategoryId = 3,
                CategoryName = "Phụ kiện máy tính",
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new Category
            {
                CategoryId = 4,
                CategoryName = "Nhà thông minh (SmartHome)",
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            }
        );

        // 10. Seed 5 Dòng Sản phẩm mẫu CellphoneS
        modelBuilder.Entity<Product>().HasData(
            new Product
            {
                ProductId = 1,
                ProductName = "Laptop ASUS Zenbook 14 OLED UX3405",
                CategoryId = 1,
                Description = "Laptop mỏng nhẹ cao cấp màn hình OLED 120Hz, chip Intel Core Ultra thế hệ mới.",
                ImageUrl = "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/t/e/text_ng_n_4__2_70.png",
                VariantAttributes = new List<string> { "Cấu hình (RAM/SSD)", "Màu sắc" },
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new Product
            {
                ProductId = 2,
                ProductName = "Laptop Gaming Acer Nitro V 15",
                CategoryId = 1,
                Description = "Laptop gaming hiệu năng cao card đồ họa RTX 4050, tản nhiệt buồng hơi kép.",
                ImageUrl = "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/a/c/acer-nitro-5.png",
                VariantAttributes = new List<string> { "Cấu hình (RAM/SSD)", "Màu sắc" },
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new Product
            {
                ProductId = 3,
                ProductName = "Tai nghe chụp tai Sony WH-1000XM5",
                CategoryId = 2,
                Description = "Tai nghe chống ồn chủ động đỉnh cao chống ồn tự động theo môi trường, pin 30h.",
                ImageUrl = "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/o/sony-wh-1000xm5.png",
                VariantAttributes = new List<string> { "Màu sắc" },
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new Product
            {
                ProductId = 4,
                ProductName = "Bàn phím cơ không dây FL-Esports GP75",
                CategoryId = 3,
                Description = "Bàn phím cơ 3 mode kết nối gõ êm ái, switch custom hot-swap mạch xuôi.",
                ImageUrl = "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/f/l/fl-esports-gp75.png",
                VariantAttributes = new List<string> { "Loại Switch" },
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new Product
            {
                ProductId = 5,
                ProductName = "Màn hình thông minh Google Nest Hub Gen 2",
                CategoryId = 4,
                Description = "Màn hình trợ lý ảo tích hợp loa cảm ứng theo dõi giấc ngủ Radar Soli.",
                ImageUrl = "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/g/o/google-nest-hub-2.png",
                VariantAttributes = new List<string> { "Màu sắc" },
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            }
        );

        // 11. Seed các Biến thể (ProductVariants) tương ứng
        modelBuilder.Entity<ProductVariant>().HasData(
            new ProductVariant
            {
                VariantId = 1,
                ProductId = 1,
                VariantName = "16GB RAM / 512GB SSD - Xanh",
                Price = 24990000,
                StockQuantity = 15,
                ImageUrl = null,
                Attributes = new Dictionary<string, string> { { "Cấu hình (RAM/SSD)", "16GB RAM / 512GB SSD" }, { "Màu sắc", "Xanh" } },
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new ProductVariant
            {
                VariantId = 2,
                ProductId = 1,
                VariantName = "32GB RAM / 1TB SSD - Xanh",
                Price = 28990000,
                StockQuantity = 10,
                ImageUrl = null,
                Attributes = new Dictionary<string, string> { { "Cấu hình (RAM/SSD)", "32GB RAM / 1TB SSD" }, { "Màu sắc", "Xanh" } },
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new ProductVariant
            {
                VariantId = 3,
                ProductId = 2,
                VariantName = "16GB RAM / 512GB SSD - Đen",
                Price = 21490000,
                StockQuantity = 20,
                ImageUrl = null,
                Attributes = new Dictionary<string, string> { { "Cấu hình (RAM/SSD)", "16GB RAM / 512GB SSD" }, { "Màu sắc", "Đen" } },
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new ProductVariant
            {
                VariantId = 4,
                ProductId = 3,
                VariantName = "Màu Đen (Midnight Black)",
                Price = 7490000,
                StockQuantity = 25,
                ImageUrl = "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/o/sony-wh-1000xm5.png",
                Attributes = new Dictionary<string, string> { { "Màu sắc", "Màu Đen (Midnight Black)" } },
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new ProductVariant
            {
                VariantId = 5,
                ProductId = 3,
                VariantName = "Màu Bạc (Silver Platinum)",
                Price = 7490000,
                StockQuantity = 15,
                ImageUrl = "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/o/sony-wh-1000xm5.png",
                Attributes = new Dictionary<string, string> { { "Màu sắc", "Màu Bạc (Silver Platinum)" } },
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new ProductVariant
            {
                VariantId = 6,
                ProductId = 4,
                VariantName = "Taro Pink Switch",
                Price = 2190000,
                StockQuantity = 18,
                ImageUrl = null,
                Attributes = new Dictionary<string, string> { { "Loại Switch", "Taro Pink Switch" } },
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            },
            new ProductVariant
            {
                VariantId = 7,
                ProductId = 5,
                VariantName = "Màu Than Chì (Chalk)",
                Price = 1890000,
                StockQuantity = 12,
                ImageUrl = null,
                Attributes = new Dictionary<string, string> { { "Màu sắc", "Màu Than Chì (Chalk)" } },
                IsActive = true,
                CreatedAt = new DateTime(2026, 1, 1, 0, 0, 0, DateTimeKind.Utc)
            }
        );
    }
}
