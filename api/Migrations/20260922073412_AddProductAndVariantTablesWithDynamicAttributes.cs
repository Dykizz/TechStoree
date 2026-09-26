using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace WebBanHang.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddProductAndVariantTablesWithDynamicAttributes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "products",
                columns: table => new
                {
                    product_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    product_name = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    category_id = table.Column<int>(type: "integer", nullable: false),
                    description = table.Column<string>(type: "text", nullable: true),
                    image_url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    variant_attributes = table.Column<string>(type: "jsonb", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_products", x => x.product_id);
                    table.ForeignKey(
                        name: "FK_products_categories_category_id",
                        column: x => x.category_id,
                        principalTable: "categories",
                        principalColumn: "category_id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "product_variants",
                columns: table => new
                {
                    variant_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    product_id = table.Column<int>(type: "integer", nullable: false),
                    variant_name = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    price = table.Column<decimal>(type: "numeric(12,0)", nullable: false),
                    stock_quantity = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    image_url = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: true),
                    attributes = table.Column<string>(type: "jsonb", nullable: false),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_product_variants", x => x.variant_id);
                    table.ForeignKey(
                        name: "FK_product_variants_products_product_id",
                        column: x => x.product_id,
                        principalTable: "products",
                        principalColumn: "product_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "products",
                columns: new[] { "product_id", "category_id", "created_at", "description", "image_url", "product_name", "variant_attributes" },
                values: new object[,]
                {
                    { 1, 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Laptop mỏng nhẹ cao cấp màn hình OLED 120Hz, chip Intel Core Ultra thế hệ mới.", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/t/e/text_ng_n_4__2_70.png", "Laptop ASUS Zenbook 14 OLED UX3405", "[\"C\\u1EA5u h\\u00ECnh (RAM/SSD)\",\"M\\u00E0u s\\u1EAFc\"]" },
                    { 2, 1, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Laptop gaming hiệu năng cao card đồ họa RTX 4050, tản nhiệt buồng hơi kép.", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/a/c/acer-nitro-5.png", "Laptop Gaming Acer Nitro V 15", "[\"C\\u1EA5u h\\u00ECnh (RAM/SSD)\",\"M\\u00E0u s\\u1EAFc\"]" },
                    { 3, 2, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Tai nghe chống ồn chủ động đỉnh cao chống ồn tự động theo môi trường, pin 30h.", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/o/sony-wh-1000xm5.png", "Tai nghe chụp tai Sony WH-1000XM5", "[\"M\\u00E0u s\\u1EAFc\"]" },
                    { 4, 3, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Bàn phím cơ 3 mode kết nối gõ êm ái, switch custom hot-swap mạch xuôi.", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/f/l/fl-esports-gp75.png", "Bàn phím cơ không dây FL-Esports GP75", "[\"Lo\\u1EA1i Switch\"]" },
                    { 5, 4, new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "Màn hình trợ lý ảo tích hợp loa cảm ứng theo dõi giấc ngủ Radar Soli.", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/g/o/google-nest-hub-2.png", "Màn hình thông minh Google Nest Hub Gen 2", "[\"M\\u00E0u s\\u1EAFc\"]" }
                });

            migrationBuilder.InsertData(
                table: "product_variants",
                columns: new[] { "variant_id", "attributes", "created_at", "image_url", "price", "product_id", "stock_quantity", "variant_name" },
                values: new object[,]
                {
                    { 1, "{\"C\\u1EA5u h\\u00ECnh (RAM/SSD)\":\"16GB RAM / 512GB SSD\",\"M\\u00E0u s\\u1EAFc\":\"Xanh\"}", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, 24990000m, 1, 15, "16GB RAM / 512GB SSD - Xanh" },
                    { 2, "{\"C\\u1EA5u h\\u00ECnh (RAM/SSD)\":\"32GB RAM / 1TB SSD\",\"M\\u00E0u s\\u1EAFc\":\"Xanh\"}", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, 28990000m, 1, 10, "32GB RAM / 1TB SSD - Xanh" },
                    { 3, "{\"C\\u1EA5u h\\u00ECnh (RAM/SSD)\":\"16GB RAM / 512GB SSD\",\"M\\u00E0u s\\u1EAFc\":\"\\u0110en\"}", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, 21490000m, 2, 20, "16GB RAM / 512GB SSD - Đen" },
                    { 4, "{\"M\\u00E0u s\\u1EAFc\":\"M\\u00E0u \\u0110en (Midnight Black)\"}", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/o/sony-wh-1000xm5.png", 7490000m, 3, 25, "Màu Đen (Midnight Black)" },
                    { 5, "{\"M\\u00E0u s\\u1EAFc\":\"M\\u00E0u B\\u1EA1c (Silver Platinum)\"}", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/o/sony-wh-1000xm5.png", 7490000m, 3, 15, "Màu Bạc (Silver Platinum)" },
                    { 6, "{\"Lo\\u1EA1i Switch\":\"Taro Pink Switch\"}", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, 2190000m, 4, 18, "Taro Pink Switch" },
                    { 7, "{\"M\\u00E0u s\\u1EAFc\":\"M\\u00E0u Than Ch\\u00EC (Chalk)\"}", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, 1890000m, 5, 12, "Màu Than Chì (Chalk)" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_product_variants_product_id",
                table: "product_variants",
                column: "product_id");

            migrationBuilder.CreateIndex(
                name: "IX_products_category_id",
                table: "products",
                column: "category_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "product_variants");

            migrationBuilder.DropTable(
                name: "products");
        }
    }
}
