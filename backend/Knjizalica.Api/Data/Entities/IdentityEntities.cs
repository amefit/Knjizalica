using Microsoft.AspNetCore.Identity;

namespace Knjizalica.Api.Data.Entities;

public sealed class ApplicationUser : IdentityUser<int>
{
    public required string FirstName { get; set; }
    public required string LastName { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public MemberProfile? MemberProfile { get; set; }
    public ICollection<RefreshToken> RefreshTokens { get; set; } = [];
    public ICollection<RevokedToken> RevokedTokens { get; set; } = [];
    public ICollection<PasswordResetToken> PasswordResetTokens { get; set; } = [];
    public ICollection<Notification> Notifications { get; set; } = [];
    public ICollection<SearchHistory> SearchHistories { get; set; } = [];
    public ICollection<ActivityLog> ActivityLogs { get; set; } = [];
}

public sealed class ApplicationRole : IdentityRole<int>
{
}

public sealed class RefreshToken
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public required string Token { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsRevoked { get; set; }

    public ApplicationUser User { get; set; } = null!;
}

public sealed class RevokedToken
{
    public int Id { get; set; }
    public required string Jti { get; set; }
    public int UserId { get; set; }
    public DateTime ExpiresAt { get; set; }
    public DateTime RevokedAt { get; set; } = DateTime.UtcNow;

    public ApplicationUser User { get; set; } = null!;
}

public sealed class PasswordResetToken
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public required string TokenHash { get; set; }
    public DateTime ExpiresAt { get; set; }
    public bool IsUsed { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ApplicationUser User { get; set; } = null!;
}
