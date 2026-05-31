using Knjizalica.Api.Common;
using Knjizalica.Api.DTOs.Notifications;
using Knjizalica.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjizalica.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public sealed class NotificationsController : ControllerBase
{
    private readonly INotificationService _service;

    public NotificationsController(INotificationService service)
    {
        _service = service;
    }

    [HttpGet]
    public async Task<ActionResult<PagedResult<NotificationDto>>> GetMyNotifications([FromQuery] PaginationQuery query, CancellationToken cancellationToken) =>
        Ok(await _service.GetMyNotificationsAsync(query, cancellationToken));

    [HttpGet("unread-count")]
    public async Task<ActionResult<UnreadCountDto>> GetUnreadCount(CancellationToken cancellationToken) =>
        Ok(await _service.GetUnreadCountAsync(cancellationToken));

    [HttpPost("{id:int}/read")]
    public async Task<ActionResult<MessageResponse>> MarkAsRead(int id, CancellationToken cancellationToken)
    {
        await _service.MarkAsReadAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Notification marked as read." });
    }

    [HttpPost("read-all")]
    public async Task<ActionResult<MessageResponse>> MarkAllAsRead(CancellationToken cancellationToken)
    {
        await _service.MarkAllAsReadAsync(cancellationToken);
        return Ok(new MessageResponse { Message = "All notifications marked as read." });
    }
}
