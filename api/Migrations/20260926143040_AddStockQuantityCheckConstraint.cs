using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace WebBanHang.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddStockQuantityCheckConstraint : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddCheckConstraint(
                name: "chk_product_variants_stock_quantity",
                table: "product_variants",
                sql: "stock_quantity >= 0");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropCheckConstraint(
                name: "chk_product_variants_stock_quantity",
                table: "product_variants");
        }
    }
}
