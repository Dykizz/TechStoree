using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

#pragma warning disable CA1814 // Prefer jagged arrays over multidimensional

namespace WebBanHang.Api.Migrations
{
    /// <inheritdoc />
    public partial class AddSurveyModule : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "surveys",
                columns: table => new
                {
                    survey_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    title = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    description = table.Column<string>(type: "text", nullable: true),
                    reward_voucher_id = table.Column<int>(type: "integer", nullable: true),
                    is_active = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    created_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_surveys", x => x.survey_id);
                    table.ForeignKey(
                        name: "FK_surveys_vouchers_reward_voucher_id",
                        column: x => x.reward_voucher_id,
                        principalTable: "vouchers",
                        principalColumn: "voucher_id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "survey_assignments",
                columns: table => new
                {
                    assignment_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    survey_id = table.Column<int>(type: "integer", nullable: false),
                    user_id = table.Column<int>(type: "integer", nullable: false),
                    assigned_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: false, defaultValueSql: "CURRENT_TIMESTAMP"),
                    completed_at = table.Column<DateTime>(type: "timestamp with time zone", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_survey_assignments", x => x.assignment_id);
                    table.ForeignKey(
                        name: "FK_survey_assignments_surveys_survey_id",
                        column: x => x.survey_id,
                        principalTable: "surveys",
                        principalColumn: "survey_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_survey_assignments_users_user_id",
                        column: x => x.user_id,
                        principalTable: "users",
                        principalColumn: "user_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "survey_questions",
                columns: table => new
                {
                    question_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    survey_id = table.Column<int>(type: "integer", nullable: false),
                    question_text = table.Column<string>(type: "text", nullable: false),
                    question_type = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false, defaultValue: "SINGLE_CHOICE"),
                    is_required = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    order_num = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_survey_questions", x => x.question_id);
                    table.ForeignKey(
                        name: "FK_survey_questions_surveys_survey_id",
                        column: x => x.survey_id,
                        principalTable: "surveys",
                        principalColumn: "survey_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "survey_options",
                columns: table => new
                {
                    option_id = table.Column<int>(type: "integer", nullable: false)
                        .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn),
                    question_id = table.Column<int>(type: "integer", nullable: false),
                    option_text = table.Column<string>(type: "character varying(255)", maxLength: 255, nullable: false),
                    order_num = table.Column<int>(type: "integer", nullable: false, defaultValue: 1)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_survey_options", x => x.option_id);
                    table.ForeignKey(
                        name: "FK_survey_options_survey_questions_question_id",
                        column: x => x.question_id,
                        principalTable: "survey_questions",
                        principalColumn: "question_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "survey_answers",
                columns: table => new
                {
                    assignment_id = table.Column<int>(type: "integer", nullable: false),
                    question_id = table.Column<int>(type: "integer", nullable: false),
                    selected_option_id = table.Column<int>(type: "integer", nullable: true),
                    text_answer = table.Column<string>(type: "text", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_survey_answers", x => new { x.assignment_id, x.question_id });
                    table.CheckConstraint("chk_survey_answer_content", "selected_option_id IS NOT NULL OR text_answer IS NOT NULL");
                    table.ForeignKey(
                        name: "FK_survey_answers_survey_assignments_assignment_id",
                        column: x => x.assignment_id,
                        principalTable: "survey_assignments",
                        principalColumn: "assignment_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_survey_answers_survey_options_selected_option_id",
                        column: x => x.selected_option_id,
                        principalTable: "survey_options",
                        principalColumn: "option_id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_survey_answers_survey_questions_question_id",
                        column: x => x.question_id,
                        principalTable: "survey_questions",
                        principalColumn: "question_id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.InsertData(
                table: "surveys",
                columns: new[] { "survey_id", "created_at", "description", "is_active", "reward_voucher_id", "title" },
                values: new object[] { 1, new DateTime(2026, 1, 5, 0, 0, 0, 0, DateTimeKind.Utc), "Khảo sát ý kiến khách hàng về mức giá và tính năng kỳ vọng của dòng tai nghe cao cấp Sony WH-1000XM6 sắp mở bán. Nhận ngay Voucher giảm giá sau khi hoàn thành!", true, null, "Thăm dò nhu cầu Tai nghe chống ồn Sony WH-1000XM6 (2026)" });

            migrationBuilder.InsertData(
                table: "survey_questions",
                columns: new[] { "question_id", "is_required", "order_num", "question_text", "survey_id" },
                values: new object[] { 1, true, 1, "Bạn kỳ vọng mức giá niêm yết của Sony WH-1000XM6 khoảng bao nhiêu?", 1 });

            migrationBuilder.InsertData(
                table: "survey_questions",
                columns: new[] { "question_id", "order_num", "question_text", "question_type", "survey_id" },
                values: new object[] { 2, 2, "Bạn có đóng góp ý kiến hoặc kỳ vọng tính năng gì mới ở thế hệ Sony XM6 này?", "TEXT", 1 });

            migrationBuilder.InsertData(
                table: "survey_options",
                columns: new[] { "option_id", "option_text", "order_num", "question_id" },
                values: new object[,]
                {
                    { 1, "Dưới 8.000.000 VNĐ", 1, 1 },
                    { 2, "Từ 8.000.000 - 10.000.000 VNĐ", 2, 1 },
                    { 3, "Trên 10.000.000 VNĐ", 3, 1 }
                });

            migrationBuilder.CreateIndex(
                name: "IX_survey_answers_question_id",
                table: "survey_answers",
                column: "question_id");

            migrationBuilder.CreateIndex(
                name: "IX_survey_answers_selected_option_id",
                table: "survey_answers",
                column: "selected_option_id");

            migrationBuilder.CreateIndex(
                name: "IX_survey_assignments_survey_id_user_id",
                table: "survey_assignments",
                columns: new[] { "survey_id", "user_id" },
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_survey_assignments_user_id",
                table: "survey_assignments",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_survey_options_question_id",
                table: "survey_options",
                column: "question_id");

            migrationBuilder.CreateIndex(
                name: "IX_survey_questions_survey_id",
                table: "survey_questions",
                column: "survey_id");

            migrationBuilder.CreateIndex(
                name: "IX_surveys_reward_voucher_id",
                table: "surveys",
                column: "reward_voucher_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "survey_answers");

            migrationBuilder.DropTable(
                name: "survey_assignments");

            migrationBuilder.DropTable(
                name: "survey_options");

            migrationBuilder.DropTable(
                name: "survey_questions");

            migrationBuilder.DropTable(
                name: "surveys");
        }
    }
}
