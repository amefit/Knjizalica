using System.ComponentModel.DataAnnotations;
using Knjizalica.Api.Common;
using Knjizalica.Api.Services;

namespace Knjizalica.Api.DTOs.Loans;

public sealed class LoanDto
{
    public int Id { get; init; }
    public int MemberProfileId { get; init; }
    public required string MemberName { get; init; }
    public required string MemberCardNumber { get; init; }
    public int BookCopyId { get; init; }
    public required string InventoryCode { get; init; }
    public int BookId { get; init; }
    public required string BookTitle { get; init; }
    public string? CoverImagePath { get; init; }
    public required string Status { get; init; }
    public DateTime BorrowedAt { get; init; }
    public DateTime DueDate { get; init; }
    public DateTime? ReturnedAt { get; init; }
    public string? ApprovedByName { get; init; }
    public DateTime? ApprovedAt { get; init; }
    public string? RejectionReason { get; init; }
    public string? Notes { get; init; }
    public bool IsOverdue => LoanOverdueRules.IsOverdue(Status, DueDate, ReturnedAt);
}

public sealed class CreateLoanRequest
{
    [Required]
    public int MemberProfileId { get; init; }

    [Required]
    public int BookCopyId { get; init; }

    [Required]
    public DateTime DueDate { get; init; }

    [MaxLength(500)]
    public string? Notes { get; init; }
}

public sealed class CancelLoanRequest
{
    [MaxLength(500)]
    public string? Reason { get; init; }
}

public sealed class LoanFilterQuery : PaginationQuery
{
    public string? Status { get; set; }
    public int? MemberProfileId { get; set; }
    public bool OverdueOnly { get; set; }
}
