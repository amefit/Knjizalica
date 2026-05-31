using Knjizalica.Api.Common;
using Knjizalica.Api.Data;
using Knjizalica.Api.Data.Entities;
using Knjizalica.Api.DTOs.News;
using Knjizalica.Shared.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Services;

public interface INewsService
{
    Task<PagedResult<NewsDto>> GetAllAsync(NewsFilterQuery query, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<NewsDto>> GetPublicActiveAsync(CancellationToken cancellationToken = default);
    Task<NewsDto> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<NewsDto> CreateAsync(CreateNewsRequest request, CancellationToken cancellationToken = default);
    Task<NewsDto> UpdateAsync(int id, UpdateNewsRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(int id, CancellationToken cancellationToken = default);
}

public sealed class NewsService : INewsService
{
    private readonly ApplicationDbContext _context;

    public NewsService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<PagedResult<NewsDto>> GetAllAsync(NewsFilterQuery query, CancellationToken cancellationToken = default)
    {
        var news = _context.News.AsNoTracking().AsQueryable();

        if (query.IsActive.HasValue)
        {
            news = news.Where(n => n.IsActive == query.IsActive.Value);
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            news = news.Where(n =>
                n.Title.ToLower().Contains(search) ||
                n.Content.ToLower().Contains(search));
        }

        var projected = news
            .OrderByDescending(n => n.PublishedAt)
            .Select(n => new NewsDto
            {
                Id = n.Id,
                Title = n.Title,
                Content = n.Content,
                ImagePath = n.ImagePath,
                PublishedAt = n.PublishedAt,
                IsActive = n.IsActive
            });

        return await projected.ToPagedResultAsync(query, cancellationToken);
    }

    public async Task<IReadOnlyList<NewsDto>> GetPublicActiveAsync(CancellationToken cancellationToken = default) =>
        await _context.News.AsNoTracking()
            .Where(n => n.IsActive)
            .OrderByDescending(n => n.PublishedAt)
            .Select(n => new NewsDto
            {
                Id = n.Id,
                Title = n.Title,
                Content = n.Content,
                ImagePath = n.ImagePath,
                PublishedAt = n.PublishedAt,
                IsActive = n.IsActive
            })
            .ToListAsync(cancellationToken);

    public async Task<NewsDto> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var news = await _context.News.AsNoTracking()
            .Where(n => n.Id == id)
            .Select(n => new NewsDto
            {
                Id = n.Id,
                Title = n.Title,
                Content = n.Content,
                ImagePath = n.ImagePath,
                PublishedAt = n.PublishedAt,
                IsActive = n.IsActive
            })
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("News item not found.");

        return news;
    }

    public async Task<NewsDto> CreateAsync(CreateNewsRequest request, CancellationToken cancellationToken = default)
    {
        var news = new News
        {
            Title = request.Title.Trim(),
            Content = request.Content.Trim(),
            ImagePath = request.ImagePath,
            PublishedAt = request.PublishedAt ?? DateTime.UtcNow,
            IsActive = request.IsActive
        };

        _context.News.Add(news);
        await _context.SaveChangesAsync(cancellationToken);

        return MapNews(news);
    }

    public async Task<NewsDto> UpdateAsync(int id, UpdateNewsRequest request, CancellationToken cancellationToken = default)
    {
        var news = await _context.News.FindAsync([id], cancellationToken)
            ?? throw new NotFoundException("News item not found.");

        news.Title = request.Title.Trim();
        news.Content = request.Content.Trim();
        news.ImagePath = request.ImagePath;
        news.PublishedAt = request.PublishedAt ?? news.PublishedAt;
        news.IsActive = request.IsActive;

        await _context.SaveChangesAsync(cancellationToken);
        return MapNews(news);
    }

    public async Task DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var news = await _context.News.FindAsync([id], cancellationToken)
            ?? throw new NotFoundException("News item not found.");

        _context.News.Remove(news);
        await _context.SaveChangesAsync(cancellationToken);
    }

    private static NewsDto MapNews(News n) => new()
    {
        Id = n.Id,
        Title = n.Title,
        Content = n.Content,
        ImagePath = n.ImagePath,
        PublishedAt = n.PublishedAt,
        IsActive = n.IsActive
    };
}
