using System.ComponentModel.DataAnnotations;

namespace Knjizalica.Api.DTOs.Authors;

public sealed class AuthorDto
{
    public int Id { get; init; }
    public required string FirstName { get; init; }
    public required string LastName { get; init; }
    public string? Biography { get; init; }
    public string FullName => $"{FirstName} {LastName}";
}

public sealed class CreateAuthorRequest
{
    [Required, MaxLength(100)]
    public required string FirstName { get; init; }

    [Required, MaxLength(100)]
    public required string LastName { get; init; }

    [MaxLength(2000)]
    public string? Biography { get; init; }
}

public sealed class UpdateAuthorRequest
{
    [Required, MaxLength(100)]
    public required string FirstName { get; init; }

    [Required, MaxLength(100)]
    public required string LastName { get; init; }

    [MaxLength(2000)]
    public string? Biography { get; init; }
}
