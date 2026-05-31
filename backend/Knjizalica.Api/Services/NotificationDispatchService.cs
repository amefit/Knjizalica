using Knjizalica.Api.Data;
using Knjizalica.Api.Data.Entities;
using Knjizalica.Api.Hubs;
using Knjizalica.Api.Messaging;
using Knjizalica.Shared.Messages;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Services;

public interface INotificationDispatchService
{
    Task SendAsync(int userId, string title, string message, bool sendEmail = false, string? email = null, CancellationToken cancellationToken = default);
}

public sealed class NotificationDispatchService : INotificationDispatchService
{
    private readonly ApplicationDbContext _context;
    private readonly IHubContext<NotificationHub> _hub;
    private readonly IMessagePublisher _publisher;

    public NotificationDispatchService(ApplicationDbContext context, IHubContext<NotificationHub> hub, IMessagePublisher publisher)
    {
        _context = context;
        _hub = hub;
        _publisher = publisher;
    }

    public async Task SendAsync(int userId, string title, string message, bool sendEmail = false, string? email = null, CancellationToken cancellationToken = default)
    {
        var notification = new Notification
        {
            UserId = userId,
            Title = title,
            Message = message,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        };

        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync(cancellationToken);

        await _hub.Clients.Group($"user-{userId}").SendAsync("NotificationReceived", new
        {
            notification.Id,
            notification.Title,
            notification.Message,
            notification.IsRead,
            notification.CreatedAt
        }, cancellationToken);

        if (sendEmail && !string.IsNullOrWhiteSpace(email))
        {
            await _publisher.PublishEmailAsync(new SendEmailMessage
            {
                ToEmail = email,
                Subject = title,
                Body = message
            }, cancellationToken);
        }
    }
}
