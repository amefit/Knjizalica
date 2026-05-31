using System.ComponentModel.DataAnnotations;
using Knjizalica.Api.Common;

namespace Knjizalica.Api.DTOs.Reservations;

public sealed class ReservationDto
{
    public int Id { get; init; }
    public int MemberProfileId { get; init; }
    public required string MemberName { get; init; }
    public int BookCopyId { get; init; }
    public required string InventoryCode { get; init; }
    public int BookId { get; init; }
    public required string BookTitle { get; init; }
    public string? CoverImagePath { get; init; }
    public required string Status { get; init; }
    public DateTime FromDate { get; init; }
    public DateTime ToDate { get; init; }
    public DateTime CreatedAt { get; init; }
    public string? ApprovedByName { get; init; }
    public string? CancellationReason { get; init; }
}

public sealed class CreateReservationRequest
{
    [Required]
    public int BookCopyId { get; init; }

    [Required]
    public DateTime FromDate { get; init; }

    [Required]
    public DateTime ToDate { get; init; }
}

public sealed class CancelReservationRequest
{
    [MaxLength(500)]
    public string? Reason { get; init; }
}

public sealed class ReservationFilterQuery : PaginationQuery
{
    public string? Status { get; set; }
    public int? MemberProfileId { get; set; }
}

public sealed class AvailabilityCalendarDto
{
    public int BookCopyId { get; init; }
    public required string InventoryCode { get; init; }
    public int BookId { get; init; }
    public required string BookTitle { get; init; }
    public DateTime FromDate { get; init; }
    public DateTime ToDate { get; init; }
    public IReadOnlyList<OccupiedPeriodDto> OccupiedPeriods { get; init; } = [];
    public IReadOnlyList<DateRangeDto> FreePeriods { get; init; } = [];
}

public sealed class OccupiedPeriodDto
{
    public DateTime FromDate { get; init; }
    public DateTime ToDate { get; init; }
    public required string Reason { get; init; }
    public required string SourceType { get; init; }
}

public sealed class DateRangeDto
{
    public DateTime FromDate { get; init; }
    public DateTime ToDate { get; init; }
}
