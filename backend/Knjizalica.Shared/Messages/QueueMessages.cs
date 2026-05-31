namespace Knjizalica.Shared.Messages;

public sealed class SendEmailMessage
{
    public required string ToEmail { get; init; }
    public required string Subject { get; init; }
    public required string Body { get; init; }
}

public sealed class SendNotificationMessage
{
    public int UserId { get; init; }
    public required string Title { get; init; }
    public required string Message { get; init; }
}
