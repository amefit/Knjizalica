using System.ComponentModel.DataAnnotations;

namespace Knjizalica.Api.DTOs.Auth;

public sealed class LoginRequest
{
    [Required]
    public required string Username { get; init; }

    [Required]
    public required string Password { get; init; }
}

public sealed class RegisterRequest
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

    [Required, Compare(nameof(Password))]
    public required string ConfirmPassword { get; init; }

    [Phone]
    public string? PhoneNumber { get; init; }

    [Required]
    public int CityId { get; init; }
}

public sealed class AuthResponse
{
    public required string Token { get; init; }
    public required DateTime ExpiresAt { get; init; }
    public required UserInfoResponse User { get; init; }
}

public sealed class UserInfoResponse
{
    public int Id { get; init; }
    public required string Username { get; init; }
    public required string Email { get; init; }
    public required string FirstName { get; init; }
    public required string LastName { get; init; }
    public required IReadOnlyList<string> Roles { get; init; }
}

public sealed class ForgotPasswordRequest
{
    [Required, EmailAddress]
    public required string Email { get; init; }
}

public sealed class ResetPasswordRequest
{
    [Required, EmailAddress]
    public required string Email { get; init; }

    [Required]
    public required string Token { get; init; }

    [Required, MinLength(6), MaxLength(100)]
    public required string NewPassword { get; init; }

    [Required, Compare(nameof(NewPassword))]
    public required string ConfirmPassword { get; init; }
}

public sealed class ChangePasswordRequest
{
    [Required]
    public required string CurrentPassword { get; init; }

    [Required, MinLength(6), MaxLength(100)]
    public required string NewPassword { get; init; }

    [Required, Compare(nameof(NewPassword))]
    public required string ConfirmPassword { get; init; }
}
