using Microsoft.EntityFrameworkCore;
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

        // 4. Seed dữ liệu mặc định cho Role (ADMIN và USER)
        modelBuilder.Entity<Role>().HasData(
            new Role { RoleId = "ADMIN", RoleName = "Quản trị viên" },
            new Role { RoleId = "USER", RoleName = "Người dùng" }
        );

        // 5. Seed dữ liệu mẫu cho Suppliers
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
    }
}
