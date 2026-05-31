using Knjizalica.Api.Common;
using Knjizalica.Api.DTOs.Members;
using Knjizalica.Api.Services;
using Knjizalica.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjizalica.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public sealed class MembersController : ControllerBase
{
    private readonly IMemberService _service;

    public MembersController(IMemberService service)
    {
        _service = service;
    }

    [Authorize(Roles = RoleNames.Admin)]
    [HttpGet]
    public async Task<ActionResult<PagedResult<MemberDto>>> GetAll([FromQuery] MemberFilterQuery query, CancellationToken cancellationToken) =>
        Ok(await _service.GetAllAsync(query, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpGet("{id:int}")]
    public async Task<ActionResult<MemberDto>> GetById(int id, CancellationToken cancellationToken) =>
        Ok(await _service.GetByIdAsync(id, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost]
    public async Task<ActionResult<MemberDto>> Create([FromBody] CreateMemberRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPut("{id:int}")]
    public async Task<ActionResult<MemberDto>> Update(int id, [FromBody] UpdateMemberRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdateAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpDelete("{id:int}")]
    public async Task<ActionResult<MessageResponse>> Delete(int id, CancellationToken cancellationToken)
    {
        await _service.DeleteAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Member deleted." });
    }

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("{id:int}/block")]
    public async Task<ActionResult<MessageResponse>> Block(int id, CancellationToken cancellationToken)
    {
        await _service.BlockAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Member blocked." });
    }

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("{id:int}/unblock")]
    public async Task<ActionResult<MessageResponse>> Unblock(int id, CancellationToken cancellationToken)
    {
        await _service.UnblockAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Member unblocked." });
    }

    [HttpGet("me")]
    public async Task<ActionResult<MemberProfileDto>> GetMyProfile(CancellationToken cancellationToken) =>
        Ok(await _service.GetMyProfileAsync(cancellationToken));

    [HttpPut("me")]
    public async Task<ActionResult<MemberProfileDto>> UpdateMyProfile([FromBody] UpdateProfileRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdateMyProfileAsync(request, cancellationToken));
}
