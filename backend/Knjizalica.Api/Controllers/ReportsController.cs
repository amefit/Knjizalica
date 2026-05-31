using Knjizalica.Api.DTOs.Reports;
using Knjizalica.Api.Services;
using Knjizalica.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjizalica.Api.Controllers;

[ApiController]
[Authorize(Roles = RoleNames.Admin)]
[Route("api/[controller]")]
public sealed class ReportsController : ControllerBase
{
    private readonly IReportService _service;

    public ReportsController(IReportService service)
    {
        _service = service;
    }

    [HttpGet("overdue-loans")]
    public async Task<IActionResult> GetOverdueLoansReport(CancellationToken cancellationToken)
    {
        var pdf = await _service.GenerateOverdueLoansReportAsync(cancellationToken);
        return File(pdf, "application/pdf", $"overdue-loans-{DateTime.UtcNow:yyyyMMdd}.pdf");
    }

    [HttpGet("loans-by-period")]
    public async Task<IActionResult> GetLoansByPeriodReport([FromQuery] LoansByPeriodReportRequest request, CancellationToken cancellationToken)
    {
        var pdf = await _service.GenerateLoansByPeriodReportAsync(request.FromDate, request.ToDate, cancellationToken);
        return File(pdf, "application/pdf", $"loans-by-period-{request.FromDate:yyyyMMdd}-{request.ToDate:yyyyMMdd}.pdf");
    }
}
