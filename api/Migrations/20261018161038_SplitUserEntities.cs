using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace WebBanHang.Api.Migrations
{
    /// <inheritdoc />
    public partial class SplitUserEntities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "admins",
                columns: table => new
                {
                    admin_id = table.Column<int>(type: "integer", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_admins", x => x.admin_id);
                    table.ForeignKey(
                        name: "FK_admins_users_admin_id",
                        column: x => x.admin_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "customers",
                columns: table => new
                {
                    customer_id = table.Column<int>(type: "integer", nullable: false),
                    address = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: true),
                    date_of_birth = table.Column<DateTime>(type: "timestamp with time zone", nullable: true),
                    tech_interest = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_customers", x => x.customer_id);
                    table.ForeignKey(
                        name: "FK_customers_users_customer_id",
                        column: x => x.customer_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "employees",
                columns: table => new
                {
                    employee_id = table.Column<int>(type: "integer", nullable: false),
                    employee_code = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    employment_type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "FULL_TIME"),
                    base_salary = table.Column<decimal>(type: "numeric(12,0)", nullable: false, defaultValue: 0m),
                    hourly_rate = table.Column<decimal>(type: "numeric(10,0)", nullable: false, defaultValue: 0m)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_employees", x => x.employee_id);
                    table.ForeignKey(
                        name: "FK_employees_users_employee_id",
                        column: x => x.employee_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_employees_employee_code",
                table: "employees",
                column: "employee_code",
                unique: true);

            // Tự động chuyển giao dữ liệu người dùng cũ sang 3 bảng chuyên biệt mới
            migrationBuilder.Sql(@"
                INSERT INTO customers (customer_id, address, date_of_birth, tech_interest)
                SELECT u.user_id, u.address, u.date_of_birth, u.tech_interest
                FROM users u
                WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.customer_id = u.user_id);

                INSERT INTO admins (admin_id)
                SELECT DISTINCT ur.user_id
                FROM user_roles ur
                WHERE ur.role_id = 'ADMIN'
                  AND NOT EXISTS (SELECT 1 FROM admins a WHERE a.admin_id = ur.user_id);

                INSERT INTO employees (employee_id, employee_code, employment_type, base_salary, hourly_rate)
                SELECT DISTINCT ur.user_id, SUBSTRING('NV' || u.username, 1, 20), 'FULL_TIME', 10000000, 50000
                FROM user_roles ur
                JOIN users u ON u.user_id = ur.user_id
                WHERE ur.role_id IN ('WAREHOUSE_STAFF', 'SALES_STAFF', 'SURVEY_STAFF')
                  AND NOT EXISTS (SELECT 1 FROM employees e WHERE e.employee_id = ur.user_id);
            ");

            migrationBuilder.DropColumn(
                name: "address",
                table: "users");

            migrationBuilder.DropColumn(
                name: "date_of_birth",
                table: "users");

            migrationBuilder.DropColumn(
                name: "tech_interest",
                table: "users");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "address",
                table: "users",
                type: "character varying(255)",
                maxLength: 255,
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "date_of_birth",
                table: "users",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "tech_interest",
                table: "users",
                type: "character varying(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.Sql(@"
                UPDATE users u
                SET address = c.address,
                    date_of_birth = c.date_of_birth,
                    tech_interest = c.tech_interest
                FROM customers c
                WHERE u.user_id = c.customer_id;
            ");

            migrationBuilder.DropTable(name: "admins");
            migrationBuilder.DropTable(name: "customers");
            migrationBuilder.DropTable(name: "employees");
        }
    }
}
