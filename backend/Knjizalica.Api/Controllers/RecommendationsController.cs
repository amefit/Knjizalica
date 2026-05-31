using Knjizalica.Api.DTOs.Recommendations;
using Knjizalica.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjizalica.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public sealed class RecommendationsController : ControllerBase
{
    private readonly IRecommendationService _service;

    public RecommendationsController(IRecommendationService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<RecommendationsResponse>> GetRecommendations([FromQuery] int limit = 10, CancellationToken cancellationToken = default) =>
        Ok(await _service.GetRecommendationsAsync(limit, cancellationToken));
}
