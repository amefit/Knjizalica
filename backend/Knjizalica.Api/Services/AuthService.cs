using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Knjizalica.Api.Common;
using Knjizalica.Api.Data;
using Knjizalica.Api.Data.Entities;
using Knjizalica.Api.DTOs.Auth;
using Knjizalica.Api.Messaging;
using Knjizalica.Shared.Configuration;
using Knjizalica.Shared.Constants;
using Knjizalica.Shared.Exceptions;
using Knjizalica.Shared.Messages;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace Knjizalica.Api.Services;

public interface IAuthService
{
    Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default);
    Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default);
    Task LogoutAsync(CancellationToken cancellationToken = default);
    Task<MessageResponse> ForgotPasswordAsync(ForgotPasswordRequest request, CancellationToken cancellationToken = default);
    Task<MessageResponse> ResetPasswordAsync(ResetPasswordRequest request, CancellationToken cancellationToken = default);
    Task<MessageResponse> ChangePasswordAsync(ChangePasswordRequest request, CancellationToken cancellationToken = default);
    Task<UserInfoResponse> GetCurrentUserAsync(CancellationToken cancellationToken = default);
}

public sealed class AuthService : IAuthService
{
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ApplicationDbContext _context;
    private readonly ICurrentUserService _currentUserService;
    private readonly IActivityLogService _activityLog;
    private readonly IMessagePublisher _messagePublisher;
    private readonly JwtSettings _jwtSettings;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        UserManager<ApplicationUser> userManager,
        ApplicationDbContext context,
        ICurrentUserService currentUserService,
        IActivityLogService activityLog,
        IMessagePublisher messagePublisher,
        AppSettings appSettings,
        ILogger<AuthService> logger)
    {
        _userManager = userManager;
        _context = context;
        _currentUserService = currentUserService;
        _activityLog = activityLog;
        _messagePublisher = messagePublisher;
        _jwtSettings = appSettings.Jwt;
        _logger = logger;
    }

    public async Task<AuthResponse> LoginAsync(LoginRequest request, CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByNameAsync(request.Username)
            ?? throw new UnauthorizedAppException("Invalid username or password.");

        if (!user.IsActive)
        {
            throw new UnauthorizedAppException("Account is disabled.");
        }

        var validPassword = await _userManager.CheckPasswordAsync(user, request.Password);
        if (!validPassword)
        {
            throw new UnauthorizedAppException("Invalid username or password.");
        }

        await _activityLog.LogAsync(
            "Login",
            "User",
            user.Id,
            $"{user.UserName} signed in.",
            user.Id,
            cancellationToken);

        return await BuildAuthResponseAsync(user, cancellationToken);
    }

    public async Task<AuthResponse> RegisterAsync(RegisterRequest request, CancellationToken cancellationToken = default)
    {
        var cityExists = await _context.Cities.AnyAsync(c => c.Id == request.CityId, cancellationToken);
        if (!cityExists)
        {
            throw new ValidationAppException("Selected city does not exist.");
        }

        if (await _userManager.FindByNameAsync(request.Username) != null)
        {
            throw new BusinessException("Username is already taken.");
        }

        if (await _userManager.FindByEmailAsync(request.Email) != null)
        {
            throw new BusinessException("Email is already registered.");
        }

        var activeStatus = await _context.MembershipStatuses
            .FirstAsync(s => s.Name == MembershipStatusNames.Active, cancellationToken);

        await using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            var user = new ApplicationUser
            {
                UserName = request.Username,
                Email = request.Email,
                FirstName = request.FirstName,
                LastName = request.LastName,
                PhoneNumber = request.PhoneNumber,
                EmailConfirmed = true
            };

            var createResult = await _userManager.CreateAsync(user, request.Password);
            if (!createResult.Succeeded)
            {
                throw new ValidationAppException(string.Join(" ", createResult.Errors.Select(e => e.Description)));
            }

            await _userManager.AddToRoleAsync(user, RoleNames.User);

            var cardNumber = await GenerateMemberCardNumberAsync(cancellationToken);
            _context.MemberProfiles.Add(new MemberProfile
            {
                UserId = user.Id,
                MemberCardNumber = cardNumber,
                MembershipStatusId = activeStatus.Id,
                CityId = request.CityId,
                RegistrationDate = DateTime.UtcNow,
                ExpiryDate = DateTime.UtcNow.AddYears(1)
            });

            await _context.SaveChangesAsync(cancellationToken);

            await transaction.CommitAsync(cancellationToken);
            return await BuildAuthResponseAsync(user, cancellationToken);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    public async Task LogoutAsync(CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.UserId
            ?? throw new UnauthorizedAppException("User is not authenticated.");

        var jti = _currentUserService.TokenJti;
        if (string.IsNullOrWhiteSpace(jti))
        {
            throw new UnauthorizedAppException("Invalid token.");
        }

        var alreadyRevoked = await _context.RevokedTokens
            .AnyAsync(t => t.Jti == jti, cancellationToken);

        if (!alreadyRevoked)
        {
            _context.RevokedTokens.Add(new RevokedToken
            {
                Jti = jti,
                UserId = userId,
                ExpiresAt = _currentUserService.TokenExpiresAt ?? DateTime.UtcNow.AddHours(1)
            });
            await _context.SaveChangesAsync(cancellationToken);
        }
    }

    public async Task<MessageResponse> ForgotPasswordAsync(ForgotPasswordRequest request, CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByEmailAsync(request.Email);
        if (user == null)
        {
            return new MessageResponse { Message = "If the email exists, a reset link has been sent." };
        }

        var tokenBytes = RandomNumberGenerator.GetBytes(32);
        var plainToken = Convert.ToBase64String(tokenBytes);
        var tokenHash = HashToken(plainToken);

        _context.PasswordResetTokens.Add(new PasswordResetToken
        {
            UserId = user.Id,
            TokenHash = tokenHash,
            ExpiresAt = DateTime.UtcNow.AddHours(1),
            IsUsed = false
        });

        await _context.SaveChangesAsync(cancellationToken);

        await _messagePublisher.PublishEmailAsync(new SendEmailMessage
        {
            ToEmail = user.Email!,
            Subject = "Knjizalica password reset",
            Body = $"Use this reset token within 1 hour:\n\n{plainToken}\n\nIf you did not request a reset, ignore this email."
        }, cancellationToken);

        _logger.LogInformation("Password reset email queued for user {UserId}.", user.Id);

        return new MessageResponse { Message = "If the email exists, a reset link has been sent." };
    }

    public async Task<MessageResponse> ResetPasswordAsync(ResetPasswordRequest request, CancellationToken cancellationToken = default)
    {
        var user = await _userManager.FindByEmailAsync(request.Email)
            ?? throw new ValidationAppException("Invalid reset request.");

        var tokenHash = HashToken(request.Token);
        var resetToken = await _context.PasswordResetTokens
            .Where(t => t.UserId == user.Id && !t.IsUsed && t.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(t => t.CreatedAt)
            .FirstOrDefaultAsync(t => t.TokenHash == tokenHash, cancellationToken)
            ?? throw new ValidationAppException("Invalid or expired reset token.");

        var identityResetToken = await _userManager.GeneratePasswordResetTokenAsync(user);
        var resetResult = await _userManager.ResetPasswordAsync(user, identityResetToken, request.NewPassword);

        if (!resetResult.Succeeded)
        {
            throw new ValidationAppException(string.Join(" ", resetResult.Errors.Select(e => e.Description)));
        }

        resetToken.IsUsed = true;
        await _context.SaveChangesAsync(cancellationToken);

        return new MessageResponse { Message = "Password reset successfully." };
    }

    public async Task<MessageResponse> ChangePasswordAsync(ChangePasswordRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.UserId
            ?? throw new UnauthorizedAppException("User is not authenticated.");

        var user = await _userManager.FindByIdAsync(userId.ToString())
            ?? throw new NotFoundException("User not found.");

        var result = await _userManager.ChangePasswordAsync(user, request.CurrentPassword, request.NewPassword);
        if (!result.Succeeded)
        {
            throw new ValidationAppException(string.Join(" ", result.Errors.Select(e => e.Description)));
        }

        return new MessageResponse { Message = "Password changed successfully." };
    }

    public async Task<UserInfoResponse> GetCurrentUserAsync(CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.UserId
            ?? throw new UnauthorizedAppException("User is not authenticated.");

        var user = await _userManager.FindByIdAsync(userId.ToString())
            ?? throw new NotFoundException("User not found.");

        return await MapUserInfoAsync(user);
    }

    private async Task<AuthResponse> BuildAuthResponseAsync(ApplicationUser user, CancellationToken cancellationToken)
    {
        var roles = await _userManager.GetRolesAsync(user);
        var (token, expiresAt, _) = GenerateJwtToken(user, roles);

        return new AuthResponse
        {
            Token = token,
            ExpiresAt = expiresAt,
            User = await MapUserInfoAsync(user, roles)
        };
    }

    private (string Token, DateTime ExpiresAt, string Jti) GenerateJwtToken(ApplicationUser user, IList<string> roles)
    {
        var jti = Guid.NewGuid().ToString();
        var expiresAt = DateTime.UtcNow.AddMinutes(_jwtSettings.ExpirationMinutes);
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new(JwtRegisteredClaimNames.Sub, user.Id.ToString()),
            new(JwtRegisteredClaimNames.UniqueName, user.UserName ?? string.Empty),
            new(JwtRegisteredClaimNames.Email, user.Email ?? string.Empty),
            new(JwtRegisteredClaimNames.Jti, jti),
            new("firstName", user.FirstName),
            new("lastName", user.LastName)
        };

        claims.AddRange(roles.Select(role => new Claim(ClaimTypes.Role, role)));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_jwtSettings.Key));
        var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var token = new JwtSecurityToken(
            issuer: _jwtSettings.Issuer,
            audience: _jwtSettings.Audience,
            claims: claims,
            expires: expiresAt,
            signingCredentials: credentials);

        return (new JwtSecurityTokenHandler().WriteToken(token), expiresAt, jti);
    }

    private async Task<UserInfoResponse> MapUserInfoAsync(ApplicationUser user, IList<string>? roles = null)
    {
        roles ??= await _userManager.GetRolesAsync(user);
        return new UserInfoResponse
        {
            Id = user.Id,
            Username = user.UserName ?? string.Empty,
            Email = user.Email ?? string.Empty,
            FirstName = user.FirstName,
            LastName = user.LastName,
            Roles = roles.ToList()
        };
    }

    private async Task<string> GenerateMemberCardNumberAsync(CancellationToken cancellationToken)
    {
        string cardNumber;
        do
        {
            var suffix = RandomNumberGenerator.GetInt32(100000, 999999);
            cardNumber = $"K-{suffix}";
        }
        while (await _context.MemberProfiles.AnyAsync(m => m.MemberCardNumber == cardNumber, cancellationToken));

        return cardNumber;
    }

    private static string HashToken(string token)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(token));
        return Convert.ToHexString(bytes);
    }
}
