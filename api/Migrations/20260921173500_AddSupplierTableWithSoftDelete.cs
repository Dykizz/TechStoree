using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace WebBanHang.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddSupplierTableWithSoftDelete : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "Suppliers",
                columns: table => new
                {
                    SupplierId = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    SupplierName = table.Column<string>(type: "character varying(150)", maxLength: 150, nullable: false),
                    Phone = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    Email = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true),
                    Address = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    CreatedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    DeletedAt = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_Suppliers", x => x.SupplierId);
                });

            migrationBuilder.InsertData(
                table: "Suppliers",
                columns: new[] { "SupplierId", "Address", "CreatedAt", "DeletedAt", "Email", "Phone", "SupplierName" },
                values: new object[,]
                {
                    { 1, "Tầng 5, Tòa nhà Viettel, 285 Cách Mạng Tháng 8, Q.10, TP.HCM", new DateTime(2026, 1, 1, 0, 0, 0, 0, DateTimeKind.Utc), null, "support@asus.com.vn", "18006588", "Công ty TNHH ASUS Việt Nam" },
                    { 2, "Tầng 6, Tòa nhà President Place, 93 Nguyễn Du, Q.1, TP.HCM", new DateTime(2026, 1, 2, 0, 0, 0, 0, DateTimeKind.Utc), null, "contact@sony.com.vn", "1800588885", "Sony Electronics Việt Nam" },
                    { 3, "Tòa nhà FPT Tân Thuận, Lô L.29B-31B-33B, Tân Thuận Đông, Q.7, TP.HCM", new DateTime(2026, 1, 3, 0, 0, 0, 0, DateTimeKind.Utc), null, "apple-sales@synnexfpt.com.vn", "02873001010", "Apple Authorized Distributor (Synnex FPT)" }
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "Suppliers");
        }
    }
}
