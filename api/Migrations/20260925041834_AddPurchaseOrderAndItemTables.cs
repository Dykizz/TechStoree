using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace WebBanHang.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddPurchaseOrderAndItemTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "purchase_orders",
                columns: table => new
                {
                    purchase_order_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    po_code = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false),
                    supplier_id = table.Column<int>(type: "integer", nullable: false),
                    created_by_user_id = table.Column<int>(type: "integer", nullable: false),
                    total_cost = table.Column<decimal>(type: "numeric(12,0)", nullable: false),
                    status = table.Column<string>(type: "character varying(30)", maxLength: 30, nullable: false, defaultValue: "COMPLETED"),
                    note = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_purchase_orders", x => x.purchase_order_id);
                    table.ForeignKey(
                        name: "FK_purchase_orders_Suppliers_supplier_id",
                        column: x => x.supplier_id,
                        principalTable: "Suppliers",
                        principalColumn: "SupplierId",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_purchase_orders_users_created_by_user_id",
                        column: x => x.created_by_user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateTable(
                name: "purchase_order_items",
                columns: table => new
                {
                    po_item_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    purchase_order_id = table.Column<int>(type: "integer", nullable: false),
                    variant_id = table.Column<int>(type: "integer", nullable: false),
                    import_price = table.Column<decimal>(type: "numeric(12,0)", nullable: false),
                    quantity = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_purchase_order_items", x => x.po_item_id);
                    table.ForeignKey(
                        name: "FK_purchase_order_items_product_variants_variant_id",
                        column: x => x.variant_id,
                        principalTable: "product_variants",
                        principalColumn: "variant_id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_purchase_order_items_purchase_orders_purchase_order_id",
                        column: x => x.purchase_order_id,
                        principalTable: "purchase_orders",
                        principalColumn: "purchase_order_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_purchase_order_items_purchase_order_id",
                table: "purchase_order_items",
                column: "purchase_order_id");

            migrationBuilder.CreateIndex(
                name: "IX_purchase_order_items_variant_id",
                table: "purchase_order_items",
                column: "variant_id");

            migrationBuilder.CreateIndex(
                name: "IX_purchase_orders_created_by_user_id",
                table: "purchase_orders",
                column: "created_by_user_id");

            migrationBuilder.CreateIndex(
                name: "IX_purchase_orders_po_code",
                table: "purchase_orders",
                column: "po_code",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_purchase_orders_supplier_id",
                table: "purchase_orders",
                column: "supplier_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "purchase_order_items");

            migrationBuilder.DropTable(
                name: "purchase_orders");
        }
    }
}
