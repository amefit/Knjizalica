using System.ComponentModel.DataAnnotations;
using Knjizalica.Api.Common;

namespace Knjizalica.Api.DTOs.Members;

public sealed class MemberDto
{
    public int Id { get; init; }
    public int UserId { get; init; }
    public required string Username { get; init; }
    public required string Email { get; init; }
    public required string FirstName { get; init; }
    public required string LastName { get; init; }
    public string? PhoneNumber { get; init; }
    public required string MemberCardNumber { get; init; }
    public required string MembershipStatus { get; init; }
    public int CityId { get; init; }
    public required string CityName { get; init; }
    public string? ProfileImagePath { get; init; }
    public DateTime RegistrationDate { get; init; }
    public DateTime ExpiryDate { get; init; }
    public bool IsActive { get; init; }
}

public sealed class MemberProfileDto
{
    public int Id { get; init; }
    public required string Username { get; init; }
    public required string Email { get; init; }
    public required string FirstName { get; init; }
    public required string LastName { get; init; }
    public string? PhoneNumber { get; init; }
    public required string MemberCardNumber { get; init; }
    public required string MembershipStatus { get; init; }
    public int CityId { get; init; }
    public required string CityName { get; init; }
    public string? ProfileImagePath { get; init; }
    public DateTime RegistrationDate { get; init; }
    public DateTime ExpiryDate { get; init; }
}

public sealed class CreateMemberRequest
{
    [Required, MaxLength(100)]
    public required string FirstName { get; init; }

    [Required, MaxLength(100)]
    public required string LastName { get; init; }

    [Required, EmailAddress, MaxLength(256)]
    public required string Email { get; init; }

    [Required, MinLength(3), MaxLength(50)]
    public required string Username { get; init; }

    [Required, MinLength(6), MaxLength(100)]
    public required string Password { get; init; }

    [Phone]
    public string? PhoneNumber { get; init; }

    [Required]
    public int CityId { get; init; }

    public DateTime? ExpiryDate { get; init; }
}

public sealed class UpdateMemberRequest
{
    [Required, MaxLength(100)]
    public required string FirstName { get; init; }

    [Required, MaxLength(100)]
    public required string LastName { get; init; }

    [Required, EmailAddress, MaxLength(256)]
    public required string Email { get; init; }

    [Phone]
    public string? PhoneNumber { get; init; }

    [Required]
    public int CityId { get; init; }

    public DateTime? ExpiryDate { get; init; }
}

public sealed class UpdateProfileRequest
{
    [Required, MaxLength(100)]
    public required string FirstName { get; init; }

    [Required, MaxLength(100)]
    public required string LastName { get; init; }

    [Phone]
    public string? PhoneNumber { get; init; }

    [Required]
    public int CityId { get; init; }

    public string? ProfileImagePath { get; init; }
}

public sealed class MemberFilterQuery : PaginationQuery
{
    public string? Tab { get; set; }
}
