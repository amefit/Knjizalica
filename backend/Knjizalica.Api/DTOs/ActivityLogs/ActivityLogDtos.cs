using Knjizalica.Api.Common;

namespace Knjizalica.Api.DTOs.ActivityLogs;

public sealed class ActivityLogDto
{
    public int Id { get; init; }
    public int? UserId { get; init; }
    public string? UserName { get; init; }
    public required string ActivityType { get; init; }
    public required string EntityName { get; init; }
    public int? EntityId { get; init; }
    public required string Description { get; init; }
    public DateTime CreatedAt { get; init; }
}

public sealed class ActivityLogFilterQuery : PaginationQuery
{
    public string? ActivityType { get; set; }
    public string? EntityName { get; set; }
    public int? UserId { get; set; }
    public DateTime? FromDate { get; set; }
    public DateTime? ToDate { get; set; }
}
