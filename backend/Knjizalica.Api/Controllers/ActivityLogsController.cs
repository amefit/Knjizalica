using Knjizalica.Api.Common;
using Knjizalica.Api.DTOs.ActivityLogs;
using Knjizalica.Api.Services;
using Knjizalica.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjizalica.Api.Controllers;

[ApiController]
[Authorize(Roles = RoleNames.Admin)]
[Route("api/[controller]")]
public sealed class ActivityLogsController : ControllerBase
{
    private readonly IActivityLogQueryService _service;

    public ActivityLogsController(IActivityLogQueryService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<ActivityLogDto>>> GetAll([FromQuery] ActivityLogFilterQuery query, CancellationToken cancellationToken) =>
        Ok(await _service.GetAllAsync(query, cancellationToken));
}
