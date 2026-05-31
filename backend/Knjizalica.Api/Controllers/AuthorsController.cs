using Knjizalica.Api.Common;
using Knjizalica.Api.DTOs.Authors;
using Knjizalica.Api.Services;
using Knjizalica.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjizalica.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public sealed class AuthorsController : ControllerBase
{
    private readonly IAuthorService _service;

    public AuthorsController(IAuthorService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<AuthorDto>>> GetAll([FromQuery] PaginationQuery query, CancellationToken cancellationToken) =>
        Ok(await _service.GetAllAsync(query, cancellationToken));

    [HttpGet("{id:int}")]
    public async Task<ActionResult<AuthorDto>> GetById(int id, CancellationToken cancellationToken) =>
        Ok(await _service.GetByIdAsync(id, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost]
    public async Task<ActionResult<AuthorDto>> Create([FromBody] CreateAuthorRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPut("{id:int}")]
    public async Task<ActionResult<AuthorDto>> Update(int id, [FromBody] UpdateAuthorRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdateAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpDelete("{id:int}")]
    public async Task<ActionResult<MessageResponse>> Delete(int id, CancellationToken cancellationToken)
    {
        await _service.DeleteAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Author deleted." });
    }
}
