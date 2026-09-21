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

        // 3. Seed dữ liệu mặc định cho Role (ADMIN và USER)
        modelBuilder.Entity<Role>().HasData(
            new Role { RoleId = "ADMIN", RoleName = "Quản trị viên" },
            new Role { RoleId = "USER", RoleName = "Người dùng" }
        );
    }
}
