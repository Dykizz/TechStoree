using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace WebBanHang.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddCostPriceTracking : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Dùng ADD COLUMN IF NOT EXISTS để an toàn cả trên DB cài mới lẫn DB đã đồng bộ từ SQL script
            migrationBuilder.Sql("""
                ALTER TABLE surveys ADD COLUMN IF NOT EXISTS expired_at timestamp with time zone NULL;
                ALTER TABLE surveys ADD COLUMN IF NOT EXISTS start_at timestamp with time zone NULL;
                ALTER TABLE survey_assignments ADD COLUMN IF NOT EXISTS is_notified boolean NOT NULL DEFAULT false;
                ALTER TABLE survey_assignments ADD COLUMN IF NOT EXISTS notified_at timestamp with time zone NULL;
                ALTER TABLE "Suppliers" ADD COLUMN IF NOT EXISTS "IsActive" boolean NOT NULL DEFAULT true;
                ALTER TABLE product_variants ADD COLUMN IF NOT EXISTS cost_price numeric(12,0) NOT NULL DEFAULT 0;
                ALTER TABLE order_items ADD COLUMN IF NOT EXISTS cost_price numeric(12,0) NOT NULL DEFAULT 0;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "cost_price",
                table: "product_variants");

            migrationBuilder.DropColumn(
                name: "cost_price",
                table: "order_items");
        }
    }
}
