using Knjizalica.Api.Common;
using Knjizalica.Api.DTOs.Reservations;
using Knjizalica.Api.Services;
using Knjizalica.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjizalica.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public sealed class ReservationsController : ControllerBase
{
    private readonly IReservationService _service;

    public ReservationsController(IReservationService service)
    {
        _service = service;
    }

    [Authorize(Roles = RoleNames.Admin)]
    [HttpGet]
    public async Task<ActionResult<PagedResult<ReservationDto>>> GetAll([FromQuery] ReservationFilterQuery query, CancellationToken cancellationToken) =>
        Ok(await _service.GetAllAsync(query, cancellationToken));

    [HttpGet("my")]
    public async Task<ActionResult<PagedResult<ReservationDto>>> GetMyReservations([FromQuery] ReservationFilterQuery query, CancellationToken cancellationToken) =>
        Ok(await _service.GetMyReservationsAsync(query, cancellationToken));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<ReservationDto>> GetById(int id, CancellationToken cancellationToken) =>
        Ok(await _service.GetByIdAsync(id, cancellationToken));

    [HttpPost]
    public async Task<ActionResult<ReservationDto>> Create([FromBody] CreateReservationRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateAsync(request, cancellationToken));

    [HttpPost("{id:int}/cancel")]
    public async Task<ActionResult<ReservationDto>> Cancel(int id, [FromBody] CancelReservationRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CancelAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("{id:int}/confirm")]
    public async Task<ActionResult<ReservationDto>> Confirm(int id, CancellationToken cancellationToken) =>
        Ok(await _service.ConfirmAsync(id, cancellationToken));

    [HttpGet("availability/{bookCopyId:int}")]
    public async Task<ActionResult<AvailabilityCalendarDto>> GetAvailability(
        int bookCopyId,
        [FromQuery] DateTime fromDate,
        [FromQuery] DateTime toDate,
        CancellationToken cancellationToken) =>
        Ok(await _service.GetAvailabilityCalendarAsync(bookCopyId, fromDate, toDate, cancellationToken));
}
