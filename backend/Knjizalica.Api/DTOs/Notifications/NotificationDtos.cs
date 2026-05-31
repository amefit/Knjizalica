namespace Knjizalica.Api.DTOs.Notifications;

public sealed class NotificationDto
{
    public int Id { get; init; }
    public required string Title { get; init; }
    public required string Message { get; init; }
    public bool IsRead { get; init; }
    public DateTime CreatedAt { get; init; }
}

public sealed class UnreadCountDto
{
    public int Count { get; init; }
}
