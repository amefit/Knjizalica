using System.ComponentModel.DataAnnotations;

namespace Knjizalica.Api.DTOs.Reports;

public sealed class LoansByPeriodReportRequest
{
    [Required]
    public DateTime FromDate { get; init; }

    [Required]
    public DateTime ToDate { get; init; }
}
