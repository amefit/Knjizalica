using Knjizalica.Api.Common;
using Knjizalica.Api.Data;
using Knjizalica.Api.DTOs.ActivityLogs;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Services;

public interface IActivityLogQueryService
{
    Task<PagedResult<ActivityLogDto>> GetAllAsync(ActivityLogFilterQuery query, CancellationToken cancellationToken = default);
}

public sealed class ActivityLogQueryService : IActivityLogQueryService
{
    private readonly ApplicationDbContext _context;

    public ActivityLogQueryService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<ActivityLogDto>> GetAllAsync(ActivityLogFilterQuery query, CancellationToken cancellationToken = default)
    {
        var logs = _context.ActivityLogs.AsNoTracking()
            .Include(l => l.User)
            .Include(l => l.ActivityType)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            logs = logs.Where(l =>
                l.Description.ToLower().Contains(search) ||
                l.EntityName.ToLower().Contains(search) ||
                (l.User != null && l.User.UserName != null && l.User.UserName.ToLower().Contains(search)));
        }

        if (!string.IsNullOrWhiteSpace(query.ActivityType))
        {
            logs = logs.Where(l => l.ActivityType.Name == query.ActivityType);
        }

        if (!string.IsNullOrWhiteSpace(query.EntityName))
        {
            logs = logs.Where(l => l.EntityName == query.EntityName);
        }

        if (query.UserId.HasValue)
        {
            logs = logs.Where(l => l.UserId == query.UserId.Value);
        }

        if (query.FromDate.HasValue)
        {
            logs = logs.Where(l => l.CreatedAt >= query.FromDate.Value);
        }

        if (query.ToDate.HasValue)
        {
            logs = logs.Where(l => l.CreatedAt <= query.ToDate.Value);
        }

        var projected = logs
            .OrderByDescending(l => l.CreatedAt)
            .Select(l => new ActivityLogDto
            {
                Id = l.Id,
                UserId = l.UserId,
                UserName = l.User != null ? l.User.UserName : null,
                ActivityType = l.ActivityType.Name,
                EntityName = l.EntityName,
                EntityId = l.EntityId,
                Description = l.Description,
                CreatedAt = l.CreatedAt
            });

        return await projected.ToPagedResultAsync(query, cancellationToken);
    }
}
