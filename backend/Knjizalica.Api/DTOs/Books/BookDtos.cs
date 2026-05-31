using System.ComponentModel.DataAnnotations;
using Knjizalica.Api.Common;
using Knjizalica.Api.DTOs.Authors;

namespace Knjizalica.Api.DTOs.Books;

public sealed class BookListDto
{
    public int Id { get; init; }
    public required string Title { get; init; }
    public string? Edition { get; init; }
    public string? CoverImagePath { get; init; }
    public required string GenreName { get; init; }
    public required string CategoryName { get; init; }
    public required string LanguageName { get; init; }
    public required string PublisherName { get; init; }
    public int TotalCopies { get; init; }
    public int AvailableCopies { get; init; }
    public bool IsAvailable => AvailableCopies > 0;
    public IReadOnlyList<string> AuthorNames { get; init; } = [];
}

public sealed class BookDetailDto
{
    public int Id { get; init; }
    public required string Title { get; init; }
    public string? Edition { get; init; }
    public string? Description { get; init; }
    public string? CoverImagePath { get; init; }
    public int GenreId { get; init; }
    public required string GenreName { get; init; }
    public int BookCategoryId { get; init; }
    public required string CategoryName { get; init; }
    public int LanguageId { get; init; }
    public required string LanguageName { get; init; }
    public int PublisherId { get; init; }
    public required string PublisherName { get; init; }
    public DateTime CreatedAt { get; init; }
    public IReadOnlyList<AuthorDto> Authors { get; init; } = [];
    public IReadOnlyList<BookCopyDto> Copies { get; init; } = [];
    public int TotalCopies { get; init; }
    public int AvailableCopies { get; init; }
    public bool IsAvailable => AvailableCopies > 0;
}

public sealed class BookCopyDto
{
    public int Id { get; init; }
    public required string InventoryCode { get; init; }
    public bool IsAvailable { get; init; }
}

public sealed class CreateBookRequest
{
    [Required, MaxLength(200)]
    public required string Title { get; init; }

    [MaxLength(50)]
    public string? Edition { get; init; }

    [MaxLength(4000)]
    public string? Description { get; init; }

    public string? CoverImagePath { get; init; }

    [Required]
    public int GenreId { get; init; }

    [Required]
    public int BookCategoryId { get; init; }

    [Required]
    public int LanguageId { get; init; }

    [Required]
    public int PublisherId { get; init; }

    public IReadOnlyList<int> AuthorIds { get; init; } = [];

    public int CopyCount { get; init; } = 1;
}

public sealed class UpdateBookRequest
{
    [Required, MaxLength(200)]
    public required string Title { get; init; }

    [MaxLength(50)]
    public string? Edition { get; init; }

    [MaxLength(4000)]
    public string? Description { get; init; }

    public string? CoverImagePath { get; init; }

    [Required]
    public int GenreId { get; init; }

    [Required]
    public int BookCategoryId { get; init; }

    [Required]
    public int LanguageId { get; init; }

    [Required]
    public int PublisherId { get; init; }

    public IReadOnlyList<int> AuthorIds { get; init; } = [];

    /// <summary>Target total copies. Values above the current count add new inventory items.</summary>
    public int CopyCount { get; init; }
}

public sealed class BookFilterQuery : PaginationQuery
{
    public int? GenreId { get; set; }
    public int? BookCategoryId { get; set; }
    public int? LanguageId { get; set; }
    public int? PublisherId { get; set; }
    public int? AuthorId { get; set; }
    public bool? AvailableOnly { get; set; }
}
