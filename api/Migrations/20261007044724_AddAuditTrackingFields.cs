using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace WebBanHang.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddAuditTrackingFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "created_by_user_id",
                table: "users",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "assigned_by_user_id",
                table: "user_roles",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "updated_by_user_id",
                table: "orders",
                type: "integer",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_users_created_by_user_id",
                table: "users",
                column: "created_by_user_id");

            migrationBuilder.CreateIndex(
                name: "IX_user_roles_assigned_by_user_id",
                table: "user_roles",
                column: "assigned_by_user_id");

            migrationBuilder.CreateIndex(
                name: "IX_orders_updated_by_user_id",
                table: "orders",
                column: "updated_by_user_id");

            migrationBuilder.AddForeignKey(
                name: "FK_orders_users_updated_by_user_id",
                table: "orders",
                column: "updated_by_user_id",
                principalTable: "users",
                principalColumn: "user_id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_user_roles_users_assigned_by_user_id",
                table: "user_roles",
                column: "assigned_by_user_id",
                principalTable: "users",
                principalColumn: "user_id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_users_users_created_by_user_id",
                table: "users",
                column: "created_by_user_id",
                principalTable: "users",
                principalColumn: "user_id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_orders_users_updated_by_user_id",
                table: "orders");

            migrationBuilder.DropForeignKey(
                name: "FK_user_roles_users_assigned_by_user_id",
                table: "user_roles");

            migrationBuilder.DropForeignKey(
                name: "FK_users_users_created_by_user_id",
                table: "users");

            migrationBuilder.DropIndex(
                name: "IX_users_created_by_user_id",
                table: "users");

            migrationBuilder.DropIndex(
                name: "IX_user_roles_assigned_by_user_id",
                table: "user_roles");

            migrationBuilder.DropIndex(
                name: "IX_orders_updated_by_user_id",
                table: "orders");

            migrationBuilder.DropColumn(
                name: "created_by_user_id",
                table: "users");

            migrationBuilder.DropColumn(
                name: "assigned_by_user_id",
                table: "user_roles");

            migrationBuilder.DropColumn(
                name: "updated_by_user_id",
                table: "orders");
        }
    }
}
