using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Knjizalica.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AddReservationAuditFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTime>(
                name: "ApprovedAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<DateTime>(
                name: "CancelledAt",
                table: "Reservations",
                type: "datetime2",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CancelledByUserId",
                table: "Reservations",
                type: "int",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_Reservations_CancelledByUserId",
                table: "Reservations",
                column: "CancelledByUserId");

            migrationBuilder.AddForeignKey(
                name: "FK_Reservations_AspNetUsers_CancelledByUserId",
                table: "Reservations",
                column: "CancelledByUserId",
                principalTable: "AspNetUsers",
                principalColumn: "Id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Reservations_AspNetUsers_CancelledByUserId",
                table: "Reservations");

            migrationBuilder.DropIndex(
                name: "IX_Reservations_CancelledByUserId",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "ApprovedAt",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "CancelledAt",
                table: "Reservations");

            migrationBuilder.DropColumn(
                name: "CancelledByUserId",
                table: "Reservations");
        }
    }
}
