using Knjizalica.Api.Common;
using Knjizalica.Api.DTOs.Loans;
using Knjizalica.Api.Services;
using Knjizalica.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjizalica.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public sealed class LoansController : ControllerBase
{
    private readonly ILoanService _service;

    public LoansController(ILoanService service)
    {
        _service = service;
    }

    [Authorize(Roles = RoleNames.Admin)]
    [HttpGet]
    public async Task<ActionResult<PagedResult<LoanDto>>> GetAll([FromQuery] LoanFilterQuery query, CancellationToken cancellationToken) =>
        Ok(await _service.GetAllAsync(query, cancellationToken));

    [HttpGet("my")]
    public async Task<ActionResult<PagedResult<LoanDto>>> GetMyLoans([FromQuery] LoanFilterQuery query, CancellationToken cancellationToken) =>
        Ok(await _service.GetMyLoansAsync(query, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpGet("overdue")]
    public async Task<ActionResult<PagedResult<LoanDto>>> GetOverdue([FromQuery] PaginationQuery query, CancellationToken cancellationToken) =>
        Ok(await _service.GetOverdueAsync(query, cancellationToken));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<LoanDto>> GetById(int id, CancellationToken cancellationToken) =>
        Ok(await _service.GetByIdAsync(id, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost]
    public async Task<ActionResult<LoanDto>> Create([FromBody] CreateLoanRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("{id:int}/confirm")]
    public async Task<ActionResult<LoanDto>> Confirm(int id, CancellationToken cancellationToken) =>
        Ok(await _service.ConfirmAsync(id, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("{id:int}/complete")]
    public async Task<ActionResult<LoanDto>> Complete(int id, CancellationToken cancellationToken) =>
        Ok(await _service.CompleteAsync(id, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("{id:int}/return")]
    public async Task<ActionResult<LoanDto>> Return(int id, CancellationToken cancellationToken) =>
        Ok(await _service.ReturnAsync(id, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("{id:int}/cancel")]
    public async Task<ActionResult<LoanDto>> Cancel(int id, [FromBody] CancelLoanRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CancelAsync(id, request, cancellationToken));
}
