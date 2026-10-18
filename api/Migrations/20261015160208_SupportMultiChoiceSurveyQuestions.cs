using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace WebBanHang.Api.Migrations
{
    /// <inheritdoc />
    public partial class SupportMultiChoiceSurveyQuestions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropPrimaryKey(
                name: "PK_survey_answers",
                table: "survey_answers");

            migrationBuilder.AddColumn<int>(
                name: "answer_id",
                table: "survey_answers",
                type: "integer",
                nullable: false,
                defaultValue: 0)
                .Annotation("Npgsql:ValueGenerationStrategy", NpgsqlValueGenerationStrategy.IdentityByDefaultColumn);

            migrationBuilder.AddPrimaryKey(
                name: "PK_survey_answers",
                table: "survey_answers",
                column: "answer_id");

            migrationBuilder.CreateIndex(
                name: "IX_survey_answers_assignment_id_question_id",
                table: "survey_answers",
                columns: new[] { "assignment_id", "question_id" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropPrimaryKey(
                name: "PK_survey_answers",
                table: "survey_answers");

            migrationBuilder.DropIndex(
                name: "IX_survey_answers_assignment_id_question_id",
                table: "survey_answers");

            migrationBuilder.DropColumn(
                name: "answer_id",
                table: "survey_answers");

            migrationBuilder.AddPrimaryKey(
                name: "PK_survey_answers",
                table: "survey_answers",
                columns: new[] { "assignment_id", "question_id" });
        }
    }
}
