using System.Security.Claims;

namespace Knjizalica.Api.Services;

public interface ICurrentUserService
{
    int? UserId { get; }
    string? TokenJti { get; }
    DateTime? TokenExpiresAt { get; }
    bool IsInRole(string role);
}

public sealed class CurrentUserService : ICurrentUserService
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUserService(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public int? UserId
    {
        get
        {
            var value = _httpContextAccessor.HttpContext?.User.FindFirstValue(ClaimTypes.NameIdentifier)
                ?? _httpContextAccessor.HttpContext?.User.FindFirstValue(ClaimTypes.Name)
                ?? _httpContextAccessor.HttpContext?.User.FindFirstValue("sub");

            return int.TryParse(value, out var id) ? id : null;
        }
    }

    public string? TokenJti => _httpContextAccessor.HttpContext?.User.FindFirstValue("jti");

    public DateTime? TokenExpiresAt
    {
        get
        {
            var exp = _httpContextAccessor.HttpContext?.User.FindFirstValue("exp");
            if (long.TryParse(exp, out var unixSeconds))
            {
                return DateTimeOffset.FromUnixTimeSeconds(unixSeconds).UtcDateTime;
            }

            return null;
        }
    }

    public bool IsInRole(string role) =>
        _httpContextAccessor.HttpContext?.User.IsInRole(role) ?? false;
}
