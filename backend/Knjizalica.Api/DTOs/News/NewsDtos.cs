using System.ComponentModel.DataAnnotations;

using Knjizalica.Api.Common;

namespace Knjizalica.Api.DTOs.News;

public sealed class NewsDto
{
    public int Id { get; init; }
    public required string Title { get; init; }
    public required string Content { get; init; }
    public string? ImagePath { get; init; }
    public DateTime PublishedAt { get; init; }
    public bool IsActive { get; init; }
}

public sealed class CreateNewsRequest
{
    [Required, MaxLength(200)]
    public required string Title { get; init; }

    [Required, MaxLength(8000)]
    public required string Content { get; init; }

    public string? ImagePath { get; init; }

    public DateTime? PublishedAt { get; init; }

    public bool IsActive { get; init; } = true;
}

public sealed class UpdateNewsRequest
{
    [Required, MaxLength(200)]
    public required string Title { get; init; }

    [Required, MaxLength(8000)]
    public required string Content { get; init; }

    public string? ImagePath { get; init; }

    public DateTime? PublishedAt { get; init; }

    public bool IsActive { get; init; }
}

public sealed class NewsFilterQuery : PaginationQuery
{
    public bool? IsActive { get; set; }
}
