using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.ChangeTracking;
using WebBanHang.Api.Enums;
using WebBanHang.Api.Models;

namespace WebBanHang.Api.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options)
    {
    }

    public DbSet<Role> Roles => Set<Role>();
    public DbSet<User> Users => Set<User>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<Supplier> Suppliers => Set<Supplier>();
    public DbSet<Category> Categories => Set<Category>();
    public DbSet<Product> Products => Set<Product>();
    public DbSet<ProductVariant> ProductVariants => Set<ProductVariant>();
    public DbSet<PurchaseOrder> PurchaseOrders => Set<PurchaseOrder>();
    public DbSet<PurchaseOrderItem> PurchaseOrderItems => Set<PurchaseOrderItem>();
    public DbSet<Cart> Carts => Set<Cart>();
    public DbSet<CartItem> CartItems => Set<CartItem>();
    public DbSet<Promotion> Promotions => Set<Promotion>();
    public DbSet<Voucher> Vouchers => Set<Voucher>();
    public DbSet<UserVoucher> UserVouchers => Set<UserVoucher>();
    public DbSet<Order> Orders => Set<Order>();
    public DbSet<OrderItem> OrderItems => Set<OrderItem>();
    public DbSet<Survey> Surveys => Set<Survey>();
    public DbSet<SurveyQuestion> SurveyQuestions => Set<SurveyQuestion>();
    public DbSet<SurveyOption> SurveyOptions => Set<SurveyOption>();
    public DbSet<SurveyAssignment> SurveyAssignments => Set<SurveyAssignment>();
    public DbSet<SurveyAnswer> SurveyAnswers => Set<SurveyAnswer>();


    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // 1. Cấu hình bảng Roles
        modelBuilder.Entity<Role>(entity =>
        {
            entity.ToTable("roles");
            entity.HasKey(r => r.RoleId);
            entity.Property(r => r.RoleId)
                  .HasColumnName("role_id")
                  .HasConversion<string>()
                  .HasMaxLength(20);
            entity.Property(r => r.RoleName).HasColumnName("role_name").IsRequired().HasMaxLength(50);
        });

        // 2. Cấu hình bảng Users
        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("users");
            entity.HasKey(u => u.UserId);
            entity.HasIndex(u => u.Username).IsUnique();
            entity.HasIndex(u => u.Email).IsUnique();
            entity.Property(u => u.CreatedByUserId).HasColumnName("created_by_user_id");

            entity.HasOne(u => u.CreatedByUser)
                  .WithMany()
                  .HasForeignKey(u => u.CreatedByUserId)
                  .OnDelete(DeleteBehavior.SetNull);
        });

        // 2.1. Cấu hình bảng trung gian UserRoles (Many-to-Many RBAC)
        modelBuilder.Entity<UserRole>(entity =>
        {
            entity.ToTable("user_roles");
            entity.HasKey(ur => new { ur.UserId, ur.RoleId });

            entity.Property(ur => ur.UserId).HasColumnName("user_id");
            entity.Property(ur => ur.RoleId)
                  .HasColumnName("role_id")
                  .HasConversion<string>()
                  .HasMaxLength(20);
            entity.Property(ur => ur.AssignedAt).HasColumnName("assigned_at").HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(ur => ur.AssignedByUserId).HasColumnName("assigned_by_user_id");

            entity.HasOne(ur => ur.User)
                  .WithMany(u => u.UserRoles)
                  .HasForeignKey(ur => ur.UserId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(ur => ur.Role)
                  .WithMany(r => r.UserRoles)
                  .HasForeignKey(ur => ur.RoleId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(ur => ur.AssignedByUser)
                  .WithMany()
                  .HasForeignKey(ur => ur.AssignedByUserId)
                  .OnDelete(DeleteBehavior.SetNull);
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
            entity.ToTable("product_variants", t => t.HasCheckConstraint("chk_product_variants_stock_quantity", "stock_quantity >= 0"));
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

        // 10. Cấu hình bảng Vouchers
        modelBuilder.Entity<Voucher>(entity =>
        {
            entity.ToTable("vouchers");
            entity.HasKey(v => v.VoucherId);
            entity.Property(v => v.VoucherId).HasColumnName("voucher_id");
            entity.Property(v => v.Code).HasColumnName("code").IsRequired().HasMaxLength(50);
            entity.HasIndex(v => v.Code).IsUnique();
            entity.Property(v => v.Title).HasColumnName("title").IsRequired().HasMaxLength(200);
            entity.Property(v => v.Description).HasColumnName("description").HasMaxLength(1000);
            entity.Property(v => v.DiscountType).HasColumnName("discount_type").HasConversion<string>().IsRequired().HasMaxLength(20);
            entity.Property(v => v.DiscountValue).HasColumnName("discount_value").HasPrecision(18, 2);
            entity.Property(v => v.MinOrderValue).HasColumnName("min_order_value").HasPrecision(18, 2).HasDefaultValue(0);
            entity.Property(v => v.MaxDiscountAmount).HasColumnName("max_discount_amount").HasPrecision(18, 2);
            entity.Property(v => v.UsageLimit).HasColumnName("usage_limit");
            entity.Property(v => v.UsedCount).HasColumnName("used_count").HasDefaultValue(0);
            entity.Property(v => v.LimitPerUser).HasColumnName("limit_per_user").HasDefaultValue(1);
            entity.Property(v => v.StartDate).HasColumnName("start_date");
            entity.Property(v => v.EndDate).HasColumnName("end_date");
            entity.Property(v => v.IsActive).HasColumnName("is_active").HasDefaultValue(true);
            entity.Property(v => v.IsPublic).HasColumnName("is_public").HasDefaultValue(true);
            entity.Property(v => v.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("CURRENT_TIMESTAMP");
        });

        // 11. Cấu hình bảng UserVouchers (Ví voucher của khách hàng)
        modelBuilder.Entity<UserVoucher>(entity =>
        {
            entity.ToTable("user_vouchers");
            entity.HasKey(uv => uv.UserVoucherId);
            entity.Property(uv => uv.UserVoucherId).HasColumnName("user_voucher_id");
            entity.Property(uv => uv.UserId).HasColumnName("user_id");
            entity.Property(uv => uv.VoucherId).HasColumnName("voucher_id");
            entity.Property(uv => uv.AssignedType).HasColumnName("assigned_type").HasConversion<string>().IsRequired().HasMaxLength(50).HasDefaultValue(VoucherAssignedType.CLAIMED);
            entity.Property(uv => uv.AssignedAt).HasColumnName("assigned_at").HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(uv => uv.IsUsed).HasColumnName("is_used").HasDefaultValue(false);
            entity.Property(uv => uv.UsedAt).HasColumnName("used_at");
            entity.Property(uv => uv.OrderId).HasColumnName("order_id");

            entity.HasIndex(uv => new { uv.UserId, uv.VoucherId });

            entity.HasOne(uv => uv.User)
                  .WithMany()
                  .HasForeignKey(uv => uv.UserId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(uv => uv.Voucher)
                  .WithMany(v => v.UserVouchers)
                  .HasForeignKey(uv => uv.VoucherId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(uv => uv.Order)
                  .WithMany()
                  .HasForeignKey(uv => uv.OrderId)
                  .OnDelete(DeleteBehavior.SetNull);
        });

        // 12. Cấu hình bảng Orders (Đơn đặt hàng & Snapshot Voucher)
        modelBuilder.Entity<Order>(entity =>
        {
            entity.ToTable("orders");
            entity.HasKey(o => o.OrderId);
            entity.Property(o => o.OrderId).HasColumnName("order_id");
            entity.Property(o => o.OrderCode).HasColumnName("order_code").IsRequired().HasMaxLength(50);
            entity.HasIndex(o => o.OrderCode).IsUnique();

            entity.Property(o => o.UserId).HasColumnName("user_id");
            entity.HasIndex(o => o.UserId);

            entity.Property(o => o.ReceiverName).HasColumnName("receiver_name").IsRequired().HasMaxLength(100);
            entity.Property(o => o.ReceiverPhone).HasColumnName("receiver_phone").IsRequired().HasMaxLength(20);
            entity.Property(o => o.ShippingAddress).HasColumnName("shipping_address").IsRequired().HasMaxLength(500);
            entity.Property(o => o.Notes).HasColumnName("notes").HasMaxLength(500);

            entity.Property(o => o.OrderStatus)
                  .HasColumnName("order_status")
                  .HasConversion<string>()
                  .IsRequired()
                  .HasMaxLength(30)
                  .HasDefaultValue(OrderStatus.PENDING);
            entity.HasIndex(o => o.OrderStatus);

            entity.Property(o => o.PaymentMethod)
                  .HasColumnName("payment_method")
                  .HasConversion<string>()
                  .IsRequired()
                  .HasMaxLength(30)
                  .HasDefaultValue(PaymentMethod.COD);

            entity.Property(o => o.PaymentStatus)
                  .HasColumnName("payment_status")
                  .HasConversion<string>()
                  .IsRequired()
                  .HasMaxLength(30)
                  .HasDefaultValue(PaymentStatus.PENDING);

            entity.Property(o => o.SubtotalAmount).HasColumnName("subtotal_amount").HasPrecision(18, 2);
            entity.Property(o => o.VoucherId).HasColumnName("voucher_id");
            entity.Property(o => o.VoucherCode).HasColumnName("voucher_code").HasMaxLength(50);
            entity.Property(o => o.VoucherTitle).HasColumnName("voucher_title").HasMaxLength(200);
            entity.Property(o => o.VoucherDiscountAmount).HasColumnName("voucher_discount_amount").HasPrecision(18, 2).HasDefaultValue(0);
            entity.Property(o => o.TotalAmount).HasColumnName("total_amount").HasPrecision(18, 2);

            entity.Property(o => o.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(o => o.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(o => o.UpdatedByUserId).HasColumnName("updated_by_user_id");
            entity.Property(o => o.PaidAt).HasColumnName("paid_at");
            entity.Property(o => o.CancelledAt).HasColumnName("cancelled_at");
            entity.Property(o => o.CancellationReason).HasColumnName("cancellation_reason").HasMaxLength(500);

            entity.HasOne(o => o.User)
                  .WithMany()
                  .HasForeignKey(o => o.UserId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(o => o.UpdatedByUser)
                  .WithMany()
                  .HasForeignKey(o => o.UpdatedByUserId)
                  .OnDelete(DeleteBehavior.SetNull);

            entity.HasOne(o => o.Voucher)
                  .WithMany()
                  .HasForeignKey(o => o.VoucherId)
                  .OnDelete(DeleteBehavior.SetNull);
        });

        // 13. Cấu hình bảng OrderItems (Chi tiết đơn hàng & Snapshot Promotion)
        modelBuilder.Entity<OrderItem>(entity =>
        {
            entity.ToTable("order_items");
            entity.HasKey(oi => oi.OrderItemId);
            entity.Property(oi => oi.OrderItemId).HasColumnName("order_item_id");
            entity.Property(oi => oi.OrderId).HasColumnName("order_id");
            entity.Property(oi => oi.VariantId).HasColumnName("variant_id");

            entity.Property(oi => oi.ProductName).HasColumnName("product_name").IsRequired().HasMaxLength(200);
            entity.Property(oi => oi.VariantName).HasColumnName("variant_name").IsRequired().HasMaxLength(150);
            entity.Property(oi => oi.ImageUrl).HasColumnName("image_url").HasMaxLength(500);

            entity.Property(oi => oi.OriginalPrice).HasColumnName("original_price").HasPrecision(18, 2);
            entity.Property(oi => oi.UnitPrice).HasColumnName("unit_price").HasPrecision(18, 2);
            entity.Property(oi => oi.PromotionId).HasColumnName("promotion_id");
            entity.Property(oi => oi.PromotionName).HasColumnName("promotion_name").HasMaxLength(200);
            entity.Property(oi => oi.PromotionDiscount).HasColumnName("promotion_discount").HasPrecision(18, 2).HasDefaultValue(0);

            entity.Property(oi => oi.Quantity).HasColumnName("quantity");
            entity.Property(oi => oi.TotalPrice).HasColumnName("total_price").HasPrecision(18, 2);

            entity.HasOne(oi => oi.Order)
                  .WithMany(o => o.Items)
                  .HasForeignKey(oi => oi.OrderId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(oi => oi.Variant)
                  .WithMany()
                  .HasForeignKey(oi => oi.VariantId)
                  .OnDelete(DeleteBehavior.Restrict);

            entity.HasOne(oi => oi.Promotion)
                  .WithMany()
                  .HasForeignKey(oi => oi.PromotionId)
                  .OnDelete(DeleteBehavior.SetNull);
        });

        // 14. Cấu hình bảng Surveys (Khảo sát thị trường CRM)
        modelBuilder.Entity<Survey>(entity =>
        {
            entity.ToTable("surveys");
            entity.HasKey(s => s.SurveyId);
            entity.Property(s => s.SurveyId).HasColumnName("survey_id");
            entity.Property(s => s.Title).HasColumnName("title").IsRequired().HasMaxLength(255);
            entity.Property(s => s.Description).HasColumnName("description");
            entity.Property(s => s.RewardVoucherId).HasColumnName("reward_voucher_id");
            entity.Property(s => s.IsActive).HasColumnName("is_active").HasDefaultValue(true);
            entity.Property(s => s.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("CURRENT_TIMESTAMP");

            entity.HasOne(s => s.RewardVoucher)
                  .WithMany()
                  .HasForeignKey(s => s.RewardVoucherId)
                  .OnDelete(DeleteBehavior.SetNull);
        });

        // 15. Cấu hình bảng SurveyQuestions (Câu hỏi khảo sát)
        modelBuilder.Entity<SurveyQuestion>(entity =>
        {
            entity.ToTable("survey_questions");
            entity.HasKey(q => q.QuestionId);
            entity.Property(q => q.QuestionId).HasColumnName("question_id");
            entity.Property(q => q.SurveyId).HasColumnName("survey_id");
            entity.Property(q => q.QuestionText).HasColumnName("question_text").IsRequired();
            entity.Property(q => q.QuestionType)
                  .HasColumnName("question_type")
                  .HasConversion<string>()
                  .IsRequired()
                  .HasMaxLength(20)
                  .HasDefaultValue(Enums.SurveyQuestionType.SINGLE_CHOICE);
            entity.Property(q => q.IsRequired).HasColumnName("is_required").HasDefaultValue(true);
            entity.Property(q => q.OrderNum).HasColumnName("order_num").HasDefaultValue(1);

            entity.HasOne(q => q.Survey)
                  .WithMany(s => s.Questions)
                  .HasForeignKey(q => q.SurveyId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // 16. Cấu hình bảng SurveyOptions (Các đáp án trắc nghiệm)
        modelBuilder.Entity<SurveyOption>(entity =>
        {
            entity.ToTable("survey_options");
            entity.HasKey(o => o.OptionId);
            entity.Property(o => o.OptionId).HasColumnName("option_id");
            entity.Property(o => o.QuestionId).HasColumnName("question_id");
            entity.Property(o => o.OptionText).HasColumnName("option_text").IsRequired().HasMaxLength(255);
            entity.Property(o => o.OrderNum).HasColumnName("order_num").HasDefaultValue(1);

            entity.HasOne(o => o.Question)
                  .WithMany(q => q.Options)
                  .HasForeignKey(o => o.QuestionId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // 17. Cấu hình bảng SurveyAssignments (Phát bài khảo sát theo mục tiêu)
        modelBuilder.Entity<SurveyAssignment>(entity =>
        {
            entity.ToTable("survey_assignments");
            entity.HasKey(a => a.AssignmentId);
            entity.Property(a => a.AssignmentId).HasColumnName("assignment_id");
            entity.Property(a => a.SurveyId).HasColumnName("survey_id");
            entity.Property(a => a.UserId).HasColumnName("user_id");
            entity.Property(a => a.AssignedAt).HasColumnName("assigned_at").HasDefaultValueSql("CURRENT_TIMESTAMP");
            entity.Property(a => a.CompletedAt).HasColumnName("completed_at");

            // Ngăn chặn giao bài trùng lặp cho cùng một khách hàng
            entity.HasIndex(a => new { a.SurveyId, a.UserId }).IsUnique();

            entity.HasOne(a => a.Survey)
                  .WithMany(s => s.Assignments)
                  .HasForeignKey(a => a.SurveyId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(a => a.User)
                  .WithMany()
                  .HasForeignKey(a => a.UserId)
                  .OnDelete(DeleteBehavior.Cascade);
        });

        // 18. Cấu hình bảng SurveyAnswers (Câu trả lời khách hàng - Khóa chính phức hợp 3NF)
        modelBuilder.Entity<SurveyAnswer>(entity =>
        {
            entity.ToTable("survey_answers", t =>
                t.HasCheckConstraint("chk_survey_answer_content", "selected_option_id IS NOT NULL OR text_answer IS NOT NULL"));

            entity.HasKey(a => new { a.AssignmentId, a.QuestionId });
            entity.Property(a => a.AssignmentId).HasColumnName("assignment_id");
            entity.Property(a => a.QuestionId).HasColumnName("question_id");
            entity.Property(a => a.SelectedOptionId).HasColumnName("selected_option_id");
            entity.Property(a => a.TextAnswer).HasColumnName("text_answer");

            entity.HasOne(a => a.Assignment)
                  .WithMany(asg => asg.Answers)
                  .HasForeignKey(a => a.AssignmentId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(a => a.Question)
                  .WithMany(q => q.Answers)
                  .HasForeignKey(a => a.QuestionId)
                  .OnDelete(DeleteBehavior.Cascade);

            entity.HasOne(a => a.SelectedOption)
                  .WithMany(o => o.Answers)
                  .HasForeignKey(a => a.SelectedOptionId)
                  .OnDelete(DeleteBehavior.Cascade);
        });


        // 10. Seed dữ liệu mặc định cho Role (RBAC)
        modelBuilder.Entity<Role>().HasData(
            new Role { RoleId = UserRoleType.ADMIN, RoleName = "Quản trị viên" },
            new Role { RoleId = UserRoleType.WAREHOUSE_STAFF, RoleName = "Nhân viên quản lý kho" },
            new Role { RoleId = UserRoleType.SALES_STAFF, RoleName = "Nhân viên bán hàng" },
            new Role { RoleId = UserRoleType.SURVEY_STAFF, RoleName = "Nhân viên khảo sát & CRM" },
            new Role { RoleId = UserRoleType.USER, RoleName = "Khách hàng" }
        );

        // 11. Tách và nạp dữ liệu mẫu (Dummy Data) từ file Data/dummy_data.json
        modelBuilder.SeedDummyData();
    }
}
