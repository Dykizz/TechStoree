using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace WebBanHang.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddVoucherAndUserVoucherTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "vouchers",
                columns: table => new
                {
                    voucher_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    code = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    title = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    description = table.Column<string>(type: "character varying(1000)", maxLength: 1000, nullable: true),
                    discount_type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    discount_value = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false),
                    min_order_value = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: false, defaultValue: 0m),
                    max_discount_amount = table.Column<decimal>(type: "numeric(18,2)", precision: 18, scale: 2, nullable: true),
                    usage_limit = table.Column<int>(type: "integer", nullable: true),
                    used_count = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    limit_per_user = table.Column<int>(type: "integer", nullable: false, defaultValue: 1),
                    start_date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    end_date = table.Column<DateTime>(type: "timestamp with time zone", nullable: false),
                    is_active = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    is_public = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_vouchers", x => x.voucher_id);
                });

            migrationBuilder.CreateTable(
                name: "user_vouchers",
                columns: table => new
                {
                    user_voucher_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    user_id = table.Column<int>(type: "integer", nullable: false),
                    voucher_id = table.Column<int>(type: "integer", nullable: false),
                    assigned_type = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false, defaultValue: "CLAIMED"),
                    assigned_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    is_used = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    used_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    order_id = table.Column<int>(type: "integer", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_user_vouchers", x => x.user_voucher_id);
                    table.ForeignKey(
                        name: "FK_user_vouchers_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_user_vouchers_vouchers_voucher_id",
                        column: x => x.voucher_id,
                        principalTable: "vouchers",
                        principalColumn: "voucher_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_user_vouchers_user_id_voucher_id",
                table: "user_vouchers",
                columns: new[] { "user_id", "voucher_id" });

            migrationBuilder.CreateIndex(
                name: "IX_user_vouchers_voucher_id",
                table: "user_vouchers",
                column: "voucher_id");

            migrationBuilder.CreateIndex(
                name: "IX_vouchers_code",
                table: "vouchers",
                column: "code",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "user_vouchers");

            migrationBuilder.DropTable(
                name: "vouchers");
        }
    }
}
