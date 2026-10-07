using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace WebBanHang.Api.Migrations
{
    /// <inheritdoc />
    public partial class SupportMultiRoles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. Tạo bảng trung gian user_roles trước
            migrationBuilder.CreateTable(
                name: "user_roles",
                columns: table => new
                {
                    user_id = table.Column<int>(type: "integer", nullable: false),
                    role_id = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    assigned_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_user_roles", x => new { x.user_id, x.role_id });
                    table.ForeignKey(
                        name: "FK_user_roles_roles_role_id",
                        column: x => x.role_id,
                        principalTable: "roles",
                        principalColumn: "role_id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_user_roles_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            // 2. Chuyển đổi toàn bộ dữ liệu vai trò hiện có từ users.role_id sang bảng trung gian user_roles
            migrationBuilder.Sql("INSERT INTO user_roles (user_id, role_id, assigned_at) SELECT user_id, role_id, CURRENT_TIMESTAMP FROM users ON CONFLICT DO NOTHING;");

            // 3. Xóa khóa ngoại, index và cột role_id trên bảng users
            migrationBuilder.DropForeignKey(
                name: "FK_users_roles_role_id",
                table: "users");

            migrationBuilder.DropIndex(
                name: "IX_users_role_id",
                table: "users");

            migrationBuilder.DropColumn(
                name: "role_id",
                table: "users");

            // 4. Cập nhật và bổ sung các vai trò chuẩn hóa vào bảng roles
            migrationBuilder.UpdateData(
                table: "roles",
                keyColumn: "role_id",
                keyValue: "USER",
                column: "role_name",
                value: "Khách hàng");

            migrationBuilder.InsertData(
                table: "roles",
                columns: new[] { "role_id", "role_name" },
                values: new object[,]
                {
                    { "SALES_STAFF", "Nhân viên bán hàng" },
                    { "SURVEY_STAFF", "Nhân viên khảo sát & CRM" },
                    { "WAREHOUSE_STAFF", "Nhân viên quản lý kho" }
                });

            migrationBuilder.CreateIndex(
                name: "IX_user_roles_role_id",
                table: "user_roles",
                column: "role_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "role_id",
                table: "users",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "USER");

            // Khôi phục role_id từ user_roles
            migrationBuilder.Sql("UPDATE users u SET role_id = COALESCE((SELECT ur.role_id FROM user_roles ur WHERE ur.user_id = u.user_id LIMIT 1), 'USER');");

            migrationBuilder.DropTable(
                name: "user_roles");

            migrationBuilder.DeleteData(
                table: "roles",
                keyColumn: "role_id",
                keyValue: "SALES_STAFF");

            migrationBuilder.DeleteData(
                table: "roles",
                keyColumn: "role_id",
                keyValue: "SURVEY_STAFF");

            migrationBuilder.DeleteData(
                table: "roles",
                keyColumn: "role_id",
                keyValue: "WAREHOUSE_STAFF");

            migrationBuilder.UpdateData(
                table: "roles",
                keyColumn: "role_id",
                keyValue: "USER",
                column: "role_name",
                value: "Người dùng");

            migrationBuilder.CreateIndex(
                name: "IX_users_role_id",
                table: "users",
                column: "role_id");

            migrationBuilder.AddForeignKey(
                name: "FK_users_roles_role_id",
                table: "users",
                column: "role_id",
                principalTable: "roles",
                principalColumn: "role_id",
                onDelete: ReferentialAction.Restrict);
        }
    }
}
