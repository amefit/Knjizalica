using Knjizalica.Api.Common;
using Knjizalica.Api.DTOs.News;
using Knjizalica.Api.Services;
using Knjizalica.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjizalica.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public sealed class NewsController : ControllerBase
{
    private readonly INewsService _service;

    public NewsController(INewsService service)
    {
        _service = service;
    }

    [AllowAnonymous]
    [HttpGet("public")]
    public async Task<ActionResult<IReadOnlyList<NewsDto>>> GetPublicActive(CancellationToken cancellationToken) =>
        Ok(await _service.GetPublicActiveAsync(cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpGet]
    public async Task<ActionResult<PagedResult<NewsDto>>> GetAll([FromQuery] NewsFilterQuery query, CancellationToken cancellationToken) =>
        Ok(await _service.GetAllAsync(query, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpGet("{id:int}")]
    public async Task<ActionResult<NewsDto>> GetById(int id, CancellationToken cancellationToken) =>
        Ok(await _service.GetByIdAsync(id, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost]
    public async Task<ActionResult<NewsDto>> Create([FromBody] CreateNewsRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPut("{id:int}")]
    public async Task<ActionResult<NewsDto>> Update(int id, [FromBody] UpdateNewsRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdateAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpDelete("{id:int}")]
    public async Task<ActionResult<MessageResponse>> Delete(int id, CancellationToken cancellationToken)
    {
        await _service.DeleteAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "News item deleted." });
    }
}
