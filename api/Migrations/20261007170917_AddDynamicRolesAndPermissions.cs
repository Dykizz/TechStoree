using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace WebBanHang.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddDynamicRolesAndPermissions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "role_id",
                table: "user_roles",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(20)",
                oldMaxLength: 20);

            migrationBuilder.AlterColumn<string>(
                name: "role_name",
                table: "roles",
                type: "character varying(100)",
                maxLength: 100,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "role_id",
                table: "roles",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(20)",
                oldMaxLength: 20);

            migrationBuilder.AddColumn<string>(
                name: "description",
                table: "roles",
                type: "character varying(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "is_system",
                table: "roles",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateTable(
                name: "permissions",
                columns: table => new
                {
                    permission_id = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    permission_name = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    module = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    description = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_permissions", x => x.permission_id);
                });

            migrationBuilder.CreateTable(
                name: "role_permissions",
                columns: table => new
                {
                    role_id = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    permission_id = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    assigned_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_role_permissions", x => new { x.role_id, x.permission_id });
                    table.ForeignKey(
                        name: "FK_role_permissions_permissions_permission_id",
                        column: x => x.permission_id,
                        principalTable: "permissions",
                        principalColumn: "permission_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_role_permissions_roles_role_id",
                        column: x => x.role_id,
                        principalTable: "roles",
                        principalColumn: "role_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.UpdateData(
                table: "categories",
                keyColumn: "category_id",
                keyValue: 1,
                column: "category_name",
                value: "Laptop & Máy tính xách tay");

            migrationBuilder.UpdateData(
                table: "categories",
                keyColumn: "category_id",
                keyValue: 3,
                column: "category_name",
                value: "Bàn phím cơ & Chuột Gaming");

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 1,
                columns: new[] { "attributes", "image_url", "stock_quantity", "variant_name" },
                values: new object[] { "{\"C\\u1EA5u h\\u00ECnh (RAM/SSD)\":\"Ultra 5 - 16GB / 512GB\",\"M\\u00E0u s\\u1EAFc\":\"Xanh Ponder Blue\"}", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/t/e/text_ng_n_4__2_70.png", 25, "Intel Core Ultra 5 / 16GB RAM / 512GB SSD / Xanh Ponder Blue" });

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 2,
                columns: new[] { "attributes", "image_url", "price", "stock_quantity", "variant_name" },
                values: new object[] { "{\"C\\u1EA5u h\\u00ECnh (RAM/SSD)\":\"Ultra 7 - 32GB / 1TB\",\"M\\u00E0u s\\u1EAFc\":\"B\\u1EA1c Foggy Silver\"}", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/t/e/text_ng_n_4__2_70.png", 31990000m, 15, "Intel Core Ultra 7 / 32GB RAM / 1TB SSD / Bạc Foggy Silver" });

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 3,
                columns: new[] { "attributes", "image_url", "stock_quantity", "variant_name" },
                values: new object[] { "{\"C\\u1EA5u h\\u00ECnh (RAM/SSD)\":\"i5-13420H - 16GB / 512GB\",\"M\\u00E0u s\\u1EAFc\":\"\\u0110en Obsidian\"}", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/a/c/acer-nitro-5.png", 30, "Core i5-13420H / RTX 4050 6GB / 16GB / 512GB / Đen Obsidian" });

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 4,
                columns: new[] { "attributes", "price", "stock_quantity", "variant_name" },
                values: new object[] { "{\"M\\u00E0u s\\u1EAFc\":\"\\u0110en Nh\\u00E1m Midnight Black\"}", 6990000m, 50, "Đen Nhám Midnight Black" });

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 5,
                columns: new[] { "attributes", "image_url", "price", "stock_quantity", "variant_name" },
                values: new object[] { "{\"M\\u00E0u s\\u1EAFc\":\"B\\u1EA1c \\u00C1nh Kim Platinum Silver\"}", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/o/sony-wh-1000xm5-silver.png", 6990000m, 35, "Bạc Ánh Kim Platinum Silver" });

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 6,
                columns: new[] { "attributes", "image_url", "price", "stock_quantity", "variant_name" },
                values: new object[] { "{\"M\\u00E0u s\\u1EAFc\":\"Polar White\",\"Switch\":\"Gateron Pro Yellow\"}", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/b/a/ban-phim-co-fl-esports-gp75.png", 1850000m, 40, "Polar White / Switch Gateron Pro Yellow / 3 Mode" });

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 7,
                columns: new[] { "attributes", "image_url", "price", "product_id", "stock_quantity", "variant_name" },
                values: new object[] { "{\"M\\u00E0u s\\u1EAFc\":\"Taro Purple\",\"Switch\":\"Kailh Box Jellyfish\"}", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/b/a/ban-phim-co-fl-esports-gp75-taro.png", 2190000m, 4, 20, "Taro Purple / Switch Kailh Box Jellyfish / 3 Mode" });

            migrationBuilder.UpdateData(
                table: "products",
                keyColumn: "product_id",
                keyValue: 1,
                column: "description",
                value: "Laptop mỏng nhẹ cao cấp màn hình OLED 120Hz, chip Intel Core Ultra thế hệ mới tích hợp NPU AI.");

            migrationBuilder.UpdateData(
                table: "products",
                keyColumn: "product_id",
                keyValue: 2,
                column: "description",
                value: "Laptop gaming hiệu năng cao card đồ họa RTX 4050, tản nhiệt buồng hơi kép, tần số quét 144Hz.");

            migrationBuilder.UpdateData(
                table: "products",
                keyColumn: "product_id",
                keyValue: 3,
                column: "description",
                value: "Tai nghe chống ồn chủ động đỉnh cao với bộ xử lý V1 và HD QN1, chất âm Hi-Res Audio, thời lượng pin 30h.");

            migrationBuilder.UpdateData(
                table: "products",
                keyColumn: "product_id",
                keyValue: 4,
                columns: new[] { "description", "image_url", "variant_attributes" },
                values: new object[] { "Bàn phím cơ layout 75% 3 chế độ kết nối (Bluetooth/2.4G/Dây), mạch xuôi, foam tiêu âm Poron cao cấp.", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/b/a/ban-phim-co-fl-esports-gp75.png", "[\"M\\u00E0u s\\u1EAFc\",\"Switch\"]" });

            migrationBuilder.UpdateData(
                table: "products",
                keyColumn: "product_id",
                keyValue: 5,
                columns: new[] { "description", "image_url", "product_name", "variant_attributes" },
                values: new object[] { "Robot dọn nhà thông minh tự động giặt sấy giẻ, tự đổ rác và bơm nước lau sàn, lực hút 5300Pa với AI camera tránh chướng ngại vật.", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/r/o/robot-hut-bui-dreame-l10s-ultra.png", "Robot hút bụi lau nhà Xiaomi Dreame L10s Ultra", "[\"M\\u00E0u s\\u1EAFc\",\"Phi\\u00EAn b\\u1EA3n\"]" });

            migrationBuilder.UpdateData(
                table: "roles",
                keyColumn: "role_id",
                keyValue: "ADMIN",
                columns: new[] { "description", "is_system" },
                values: new object[] { null, true });

            migrationBuilder.UpdateData(
                table: "roles",
                keyColumn: "role_id",
                keyValue: "SALES_STAFF",
                columns: new[] { "description", "is_system" },
                values: new object[] { null, true });

            migrationBuilder.UpdateData(
                table: "roles",
                keyColumn: "role_id",
                keyValue: "SURVEY_STAFF",
                columns: new[] { "description", "is_system" },
                values: new object[] { null, true });

            migrationBuilder.UpdateData(
                table: "roles",
                keyColumn: "role_id",
                keyValue: "USER",
                columns: new[] { "description", "is_system" },
                values: new object[] { null, true });

            migrationBuilder.UpdateData(
                table: "roles",
                keyColumn: "role_id",
                keyValue: "WAREHOUSE_STAFF",
                columns: new[] { "description", "is_system" },
                values: new object[] { null, true });

            migrationBuilder.CreateIndex(
                name: "IX_role_permissions_permission_id",
                table: "role_permissions",
                column: "permission_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "role_permissions");

            migrationBuilder.DropTable(
                name: "permissions");

            migrationBuilder.DropColumn(
                name: "description",
                table: "roles");

            migrationBuilder.DropColumn(
                name: "is_system",
                table: "roles");

            migrationBuilder.AlterColumn<string>(
                name: "role_id",
                table: "user_roles",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(50)",
                oldMaxLength: 50);

            migrationBuilder.AlterColumn<string>(
                name: "role_name",
                table: "roles",
                type: "character varying(50)",
                maxLength: 50,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(100)",
                oldMaxLength: 100);

            migrationBuilder.AlterColumn<string>(
                name: "role_id",
                table: "roles",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                oldClrType: typeof(string),
                oldType: "character varying(50)",
                oldMaxLength: 50);

            migrationBuilder.UpdateData(
                table: "categories",
                keyColumn: "category_id",
                keyValue: 1,
                column: "category_name",
                value: "Laptop");

            migrationBuilder.UpdateData(
                table: "categories",
                keyColumn: "category_id",
                keyValue: 3,
                column: "category_name",
                value: "Phụ kiện máy tính");

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 1,
                columns: new[] { "attributes", "image_url", "stock_quantity", "variant_name" },
                values: new object[] { "{\"C\\u1EA5u h\\u00ECnh (RAM/SSD)\":\"16GB RAM / 512GB SSD\",\"M\\u00E0u s\\u1EAFc\":\"Xanh\"}", null, 15, "16GB RAM / 512GB SSD - Xanh" });

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 2,
                columns: new[] { "attributes", "image_url", "price", "stock_quantity", "variant_name" },
                values: new object[] { "{\"C\\u1EA5u h\\u00ECnh (RAM/SSD)\":\"32GB RAM / 1TB SSD\",\"M\\u00E0u s\\u1EAFc\":\"Xanh\"}", null, 28990000m, 10, "32GB RAM / 1TB SSD - Xanh" });

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 3,
                columns: new[] { "attributes", "image_url", "stock_quantity", "variant_name" },
                values: new object[] { "{\"C\\u1EA5u h\\u00ECnh (RAM/SSD)\":\"16GB RAM / 512GB SSD\",\"M\\u00E0u s\\u1EAFc\":\"\\u0110en\"}", null, 20, "16GB RAM / 512GB SSD - Đen" });

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 4,
                columns: new[] { "attributes", "price", "stock_quantity", "variant_name" },
                values: new object[] { "{\"M\\u00E0u s\\u1EAFc\":\"M\\u00E0u \\u0110en (Midnight Black)\"}", 7490000m, 25, "Màu Đen (Midnight Black)" });

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 5,
                columns: new[] { "attributes", "image_url", "price", "stock_quantity", "variant_name" },
                values: new object[] { "{\"M\\u00E0u s\\u1EAFc\":\"M\\u00E0u B\\u1EA1c (Silver Platinum)\"}", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/s/o/sony-wh-1000xm5.png", 7490000m, 15, "Màu Bạc (Silver Platinum)" });

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 6,
                columns: new[] { "attributes", "image_url", "price", "stock_quantity", "variant_name" },
                values: new object[] { "{\"Lo\\u1EA1i Switch\":\"Taro Pink Switch\"}", null, 2190000m, 18, "Taro Pink Switch" });

            migrationBuilder.UpdateData(
                table: "product_variants",
                keyColumn: "variant_id",
                keyValue: 7,
                columns: new[] { "attributes", "image_url", "price", "product_id", "stock_quantity", "variant_name" },
                values: new object[] { "{\"M\\u00E0u s\\u1EAFc\":\"M\\u00E0u Than Ch\\u00EC (Chalk)\"}", null, 1890000m, 5, 12, "Màu Than Chì (Chalk)" });

            migrationBuilder.UpdateData(
                table: "products",
                keyColumn: "product_id",
                keyValue: 1,
                column: "description",
                value: "Laptop mỏng nhẹ cao cấp màn hình OLED 120Hz, chip Intel Core Ultra thế hệ mới.");

            migrationBuilder.UpdateData(
                table: "products",
                keyColumn: "product_id",
                keyValue: 2,
                column: "description",
                value: "Laptop gaming hiệu năng cao card đồ họa RTX 4050, tản nhiệt buồng hơi kép.");

            migrationBuilder.UpdateData(
                table: "products",
                keyColumn: "product_id",
                keyValue: 3,
                column: "description",
                value: "Tai nghe chống ồn chủ động đỉnh cao chống ồn tự động theo môi trường, pin 30h.");

            migrationBuilder.UpdateData(
                table: "products",
                keyColumn: "product_id",
                keyValue: 4,
                columns: new[] { "description", "image_url", "variant_attributes" },
                values: new object[] { "Bàn phím cơ 3 mode kết nối gõ êm ái, switch custom hot-swap mạch xuôi.", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/f/l/fl-esports-gp75.png", "[\"Lo\\u1EA1i Switch\"]" });

            migrationBuilder.UpdateData(
                table: "products",
                keyColumn: "product_id",
                keyValue: 5,
                columns: new[] { "description", "image_url", "product_name", "variant_attributes" },
                values: new object[] { "Màn hình trợ lý ảo tích hợp loa cảm ứng theo dõi giấc ngủ Radar Soli.", "https://cdn2.cellphones.com.vn/insecure/rs:fill:358:358/q:90/plain/https://cellphones.com.vn/media/catalog/product/g/o/google-nest-hub-2.png", "Màn hình thông minh Google Nest Hub Gen 2", "[\"M\\u00E0u s\\u1EAFc\"]" });
        }
    }
}
