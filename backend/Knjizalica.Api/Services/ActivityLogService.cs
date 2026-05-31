using Knjizalica.Api.Data;
using Knjizalica.Api.Data.Entities;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Services;

public interface IActivityLogService
{
    Task LogAsync(string activityTypeName, string entityName, int? entityId, string description, int? userId = null, CancellationToken cancellationToken = default);
}

public sealed class ActivityLogService : IActivityLogService
{
    private readonly ApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public ActivityLogService(ApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task LogAsync(string activityTypeName, string entityName, int? entityId, string description, int? userId = null, CancellationToken cancellationToken = default)
    {
        var type = await _context.ActivityTypes.AsNoTracking()
            .FirstOrDefaultAsync(t => t.Name == activityTypeName, cancellationToken);
        if (type == null)
        {
            return;
        }

        _context.ActivityLogs.Add(new ActivityLog
        {
            UserId = userId ?? _currentUser.UserId,
            ActivityTypeId = type.Id,
            EntityName = entityName,
            EntityId = entityId,
            Description = description,
            CreatedAt = DateTime.UtcNow
        });
        await _context.SaveChangesAsync(cancellationToken);
    }
}
