using Knjizalica.Api.Common;
using Knjizalica.Api.Data;
using Knjizalica.Api.Data.Entities;
using Knjizalica.Api.DTOs.Authors;
using Knjizalica.Shared.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Services;

public interface IAuthorService
{
    Task<PagedResult<AuthorDto>> GetAllAsync(PaginationQuery query, CancellationToken cancellationToken = default);
    Task<AuthorDto> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<AuthorDto> CreateAsync(CreateAuthorRequest request, CancellationToken cancellationToken = default);
    Task<AuthorDto> UpdateAsync(int id, UpdateAuthorRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(int id, CancellationToken cancellationToken = default);
}

public sealed class AuthorService : IAuthorService
{
    private readonly ApplicationDbContext _context;
    private readonly IActivityLogService _activityLog;

    public AuthorService(ApplicationDbContext context, IActivityLogService activityLog)
    {
        _context = context;
        _activityLog = activityLog;
    }

    public async Task<PagedResult<AuthorDto>> GetAllAsync(PaginationQuery query, CancellationToken cancellationToken = default)
    {
        var authors = _context.Authors.AsNoTracking().AsQueryable();
        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            authors = authors.Where(a =>
                a.FirstName.ToLower().Contains(search) ||
                a.LastName.ToLower().Contains(search));
        }

        var projected = authors
            .OrderBy(a => a.LastName).ThenBy(a => a.FirstName)
            .Select(a => new AuthorDto
            {
                Id = a.Id,
                FirstName = a.FirstName,
                LastName = a.LastName,
                Biography = a.Biography
            });

        return await projected.ToPagedResultAsync(query, cancellationToken);
    }

    public async Task<AuthorDto> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var author = await _context.Authors.AsNoTracking()
            .Where(a => a.Id == id)
            .Select(a => new AuthorDto
            {
                Id = a.Id,
                FirstName = a.FirstName,
                LastName = a.LastName,
                Biography = a.Biography
            })
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("Author not found.");

        return author;
    }

    public async Task<AuthorDto> CreateAsync(CreateAuthorRequest request, CancellationToken cancellationToken = default)
    {
        var author = new Author
        {
            FirstName = request.FirstName.Trim(),
            LastName = request.LastName.Trim(),
            Biography = request.Biography?.Trim()
        };

        _context.Authors.Add(author);
        await _context.SaveChangesAsync(cancellationToken);
        await _activityLog.LogAsync("Author Created", "Author", author.Id, $"Author '{author.FirstName} {author.LastName}' was created.", cancellationToken: cancellationToken);

        return new AuthorDto
        {
            Id = author.Id,
            FirstName = author.FirstName,
            LastName = author.LastName,
            Biography = author.Biography
        };
    }

    public async Task<AuthorDto> UpdateAsync(int id, UpdateAuthorRequest request, CancellationToken cancellationToken = default)
    {
        var author = await _context.Authors.FindAsync([id], cancellationToken)
            ?? throw new NotFoundException("Author not found.");

        author.FirstName = request.FirstName.Trim();
        author.LastName = request.LastName.Trim();
        author.Biography = request.Biography?.Trim();
        await _context.SaveChangesAsync(cancellationToken);
        await _activityLog.LogAsync("Author Updated", "Author", author.Id, $"Author '{author.FirstName} {author.LastName}' was updated.", cancellationToken: cancellationToken);

        return new AuthorDto
        {
            Id = author.Id,
            FirstName = author.FirstName,
            LastName = author.LastName,
            Biography = author.Biography
        };
    }

    public async Task DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var author = await _context.Authors.FindAsync([id], cancellationToken)
            ?? throw new NotFoundException("Author not found.");

        if (await _context.BookAuthors.AnyAsync(ba => ba.AuthorId == id, cancellationToken))
        {
            throw new BusinessException("Cannot delete author linked to books.");
        }

        _context.Authors.Remove(author);
        await _context.SaveChangesAsync(cancellationToken);
        await _activityLog.LogAsync("Author Deleted", "Author", id, $"Author '{author.FirstName} {author.LastName}' was deleted.", cancellationToken: cancellationToken);
    }
}
