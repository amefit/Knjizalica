using Knjizalica.Api.Common;
using Knjizalica.Api.Data;
using Knjizalica.Api.Data.Entities;
using Knjizalica.Api.DTOs.Authors;
using Knjizalica.Api.DTOs.Books;
using Knjizalica.Shared.Constants;
using Knjizalica.Shared.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Services;

public interface IBookService
{
    Task<PagedResult<BookListDto>> SearchAsync(BookFilterQuery query, CancellationToken cancellationToken = default);
    Task<BookDetailDto> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<BookDetailDto> CreateAsync(CreateBookRequest request, CancellationToken cancellationToken = default);
    Task<BookDetailDto> UpdateAsync(int id, UpdateBookRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(int id, CancellationToken cancellationToken = default);
}

public sealed class BookService : IBookService
{
    private readonly ApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;
    private readonly IActivityLogService _activityLog;

    public BookService(ApplicationDbContext context, ICurrentUserService currentUser, IActivityLogService activityLog)
    {
        _context = context;
        _currentUser = currentUser;
        _activityLog = activityLog;
    }

    public async Task<PagedResult<BookListDto>> SearchAsync(BookFilterQuery query, CancellationToken cancellationToken = default)
    {
        if (!string.IsNullOrWhiteSpace(query.Search) && _currentUser.UserId.HasValue)
        {
            try
            {
                _context.SearchHistories.Add(new SearchHistory
                {
                    UserId = _currentUser.UserId.Value,
                    Query = query.Search.Trim(),
                    CreatedAt = DateTime.UtcNow
                });
                await _context.SaveChangesAsync(cancellationToken);
            }
            catch
            {
                // Search history is optional; do not block catalog search.
            }
        }

        var books = _context.Books.AsNoTracking()
            .Include(b => b.Genre)
            .Include(b => b.BookCategory)
            .Include(b => b.Language)
            .Include(b => b.Publisher)
            .Include(b => b.BookAuthors).ThenInclude(ba => ba.Author)
            .Include(b => b.BookCopies)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            books = books.Where(b =>
                b.Title.ToLower().Contains(search) ||
                (b.Description != null && b.Description.ToLower().Contains(search)) ||
                b.BookAuthors.Any(ba =>
                    ba.Author.FirstName.ToLower().Contains(search) ||
                    ba.Author.LastName.ToLower().Contains(search)));
        }

        if (query.GenreId.HasValue)
        {
            books = books.Where(b => b.GenreId == query.GenreId.Value);
        }

        if (query.BookCategoryId.HasValue)
        {
            books = books.Where(b => b.BookCategoryId == query.BookCategoryId.Value);
        }

        if (query.LanguageId.HasValue)
        {
            books = books.Where(b => b.LanguageId == query.LanguageId.Value);
        }

        if (query.PublisherId.HasValue)
        {
            books = books.Where(b => b.PublisherId == query.PublisherId.Value);
        }

        if (query.AuthorId.HasValue)
        {
            books = books.Where(b => b.BookAuthors.Any(ba => ba.AuthorId == query.AuthorId.Value));
        }

        if (query.AvailableOnly == true)
        {
            var today = DateTime.UtcNow.Date;
            books = books.Where(b => b.BookCopies.Any(c =>
                c.IsAvailable &&
                !c.Reservations.Any(r =>
                    (r.ReservationStatus.Name == ReservationStatusNames.Pending ||
                     r.ReservationStatus.Name == ReservationStatusNames.Confirmed) &&
                    r.FromDate <= today &&
                    r.ToDate >= today) &&
                !c.Loans.Any(l =>
                    (l.LoanStatus.Name == LoanStatusNames.Pending ||
                     l.LoanStatus.Name == LoanStatusNames.Confirmed ||
                     l.LoanStatus.Name == LoanStatusNames.Overdue) &&
                    l.BorrowedAt.Date <= today &&
                    l.DueDate.Date >= today)));
        }

        var todayForList = DateTime.UtcNow.Date;
        var projected = books
            .OrderBy(b => b.Title)
            .Select(b => new BookListDto
            {
                Id = b.Id,
                Title = b.Title,
                Edition = b.Edition,
                CoverImagePath = b.CoverImagePath,
                GenreName = b.Genre.Name,
                CategoryName = b.BookCategory.Name,
                LanguageName = b.Language.Name,
                PublisherName = b.Publisher.Name,
                TotalCopies = b.BookCopies.Count,
                AvailableCopies = b.BookCopies.Count(c =>
                    c.IsAvailable &&
                    !c.Reservations.Any(r =>
                        (r.ReservationStatus.Name == ReservationStatusNames.Pending ||
                         r.ReservationStatus.Name == ReservationStatusNames.Confirmed) &&
                        r.FromDate <= todayForList &&
                        r.ToDate >= todayForList) &&
                    !c.Loans.Any(l =>
                        (l.LoanStatus.Name == LoanStatusNames.Pending ||
                         l.LoanStatus.Name == LoanStatusNames.Confirmed ||
                         l.LoanStatus.Name == LoanStatusNames.Overdue) &&
                        l.BorrowedAt.Date <= todayForList &&
                        l.DueDate.Date >= todayForList)),
                AuthorNames = b.BookAuthors.Select(ba => ba.Author.FirstName + " " + ba.Author.LastName).ToList()
            });

        return await projected.ToPagedResultAsync(query, cancellationToken);
    }

    public async Task<BookDetailDto> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var book = await _context.Books.AsNoTracking()
            .Include(b => b.Genre)
            .Include(b => b.BookCategory)
            .Include(b => b.Language)
            .Include(b => b.Publisher)
            .Include(b => b.BookAuthors).ThenInclude(ba => ba.Author)
            .Include(b => b.BookCopies).ThenInclude(c => c.Reservations).ThenInclude(r => r.ReservationStatus)
            .Include(b => b.BookCopies).ThenInclude(c => c.Loans).ThenInclude(l => l.LoanStatus)
            .FirstOrDefaultAsync(b => b.Id == id, cancellationToken)
            ?? throw new NotFoundException("Book not found.");

        return MapDetail(book);
    }

    public async Task<BookDetailDto> CreateAsync(CreateBookRequest request, CancellationToken cancellationToken = default)
    {
        await ValidateReferencesAsync(request.GenreId, request.BookCategoryId, request.LanguageId, request.PublisherId, request.AuthorIds, cancellationToken);

        var book = new Book
        {
            Title = request.Title.Trim(),
            Edition = request.Edition?.Trim(),
            Description = request.Description?.Trim(),
            CoverImagePath = request.CoverImagePath,
            GenreId = request.GenreId,
            BookCategoryId = request.BookCategoryId,
            LanguageId = request.LanguageId,
            PublisherId = request.PublisherId,
            CreatedAt = DateTime.UtcNow
        };

        _context.Books.Add(book);
        await _context.SaveChangesAsync(cancellationToken);

        foreach (var authorId in request.AuthorIds.Distinct())
        {
            _context.BookAuthors.Add(new BookAuthor { BookId = book.Id, AuthorId = authorId });
        }

        var copyCount = Math.Max(1, request.CopyCount);
        for (var i = 1; i <= copyCount; i++)
        {
            _context.BookCopies.Add(new BookCopy
            {
                BookId = book.Id,
                InventoryCode = $"BC-{book.Id:D4}-{i:D2}",
                IsAvailable = true
            });
        }

        await _context.SaveChangesAsync(cancellationToken);
        await _activityLog.LogAsync("Book Created", "Book", book.Id, $"Book '{book.Title}' was created.", cancellationToken: cancellationToken);

        return await GetByIdAsync(book.Id, cancellationToken);
    }

    public async Task<BookDetailDto> UpdateAsync(int id, UpdateBookRequest request, CancellationToken cancellationToken = default)
    {
        var book = await _context.Books
            .Include(b => b.BookAuthors)
            .Include(b => b.BookCopies)
            .FirstOrDefaultAsync(b => b.Id == id, cancellationToken)
            ?? throw new NotFoundException("Book not found.");

        await ValidateReferencesAsync(request.GenreId, request.BookCategoryId, request.LanguageId, request.PublisherId, request.AuthorIds, cancellationToken);

        book.Title = request.Title.Trim();
        book.Edition = request.Edition?.Trim();
        book.Description = request.Description?.Trim();
        book.CoverImagePath = request.CoverImagePath;
        book.GenreId = request.GenreId;
        book.BookCategoryId = request.BookCategoryId;
        book.LanguageId = request.LanguageId;
        book.PublisherId = request.PublisherId;

        _context.BookAuthors.RemoveRange(book.BookAuthors);
        foreach (var authorId in request.AuthorIds.Distinct())
        {
            _context.BookAuthors.Add(new BookAuthor { BookId = book.Id, AuthorId = authorId });
        }

        if (request.CopyCount > 0)
        {
            var target = Math.Max(1, request.CopyCount);
            var current = book.BookCopies.Count;
            for (var i = current + 1; i <= target; i++)
            {
                _context.BookCopies.Add(new BookCopy
                {
                    BookId = book.Id,
                    InventoryCode = $"BC-{book.Id:D4}-{i:D2}",
                    IsAvailable = true
                });
            }
        }

        await _context.SaveChangesAsync(cancellationToken);
        await _activityLog.LogAsync("Book Updated", "Book", book.Id, $"Book '{book.Title}' was updated.", cancellationToken: cancellationToken);

        return await GetByIdAsync(book.Id, cancellationToken);
    }

    public async Task DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var book = await _context.Books
            .Include(b => b.BookCopies)
            .Include(b => b.BookAuthors)
            .FirstOrDefaultAsync(b => b.Id == id, cancellationToken)
            ?? throw new NotFoundException("Book not found.");

        var copyIds = book.BookCopies.Select(c => c.Id).ToList();
        var activeLoanStatuses = new[] { LoanStatusNames.Pending, LoanStatusNames.Confirmed, LoanStatusNames.Overdue };
        var activeReservationStatuses = new[] { ReservationStatusNames.Pending, ReservationStatusNames.Confirmed };

        if (await _context.Loans
                .Include(l => l.LoanStatus)
                .AnyAsync(l => copyIds.Contains(l.BookCopyId) && activeLoanStatuses.Contains(l.LoanStatus.Name), cancellationToken))
        {
            throw new BusinessException("Cannot delete book with active loans.");
        }

        if (await _context.Reservations
                .Include(r => r.ReservationStatus)
                .AnyAsync(r => copyIds.Contains(r.BookCopyId) && activeReservationStatuses.Contains(r.ReservationStatus.Name), cancellationToken))
        {
            throw new BusinessException("Cannot delete book with active reservations.");
        }

        if (await _context.Loans.AnyAsync(l => copyIds.Contains(l.BookCopyId), cancellationToken))
        {
            throw new BusinessException("Cannot delete book with existing loans.");
        }

        if (await _context.Reservations.AnyAsync(r => copyIds.Contains(r.BookCopyId), cancellationToken))
        {
            throw new BusinessException("Cannot delete book with existing reservations.");
        }

        _context.BookAuthors.RemoveRange(book.BookAuthors);
        _context.BookCopies.RemoveRange(book.BookCopies);
        _context.Books.Remove(book);
        await _context.SaveChangesAsync(cancellationToken);
        await _activityLog.LogAsync("Book Deleted", "Book", id, $"Book '{book.Title}' was deleted.", cancellationToken: cancellationToken);
    }

    private async Task ValidateReferencesAsync(int genreId, int categoryId, int languageId, int publisherId, IReadOnlyList<int> authorIds, CancellationToken cancellationToken)
    {
        if (!await _context.Genres.AnyAsync(g => g.Id == genreId, cancellationToken))
        {
            throw new ValidationAppException("Genre does not exist.");
        }

        if (!await _context.BookCategories.AnyAsync(c => c.Id == categoryId, cancellationToken))
        {
            throw new ValidationAppException("Book category does not exist.");
        }

        if (!await _context.Languages.AnyAsync(l => l.Id == languageId, cancellationToken))
        {
            throw new ValidationAppException("Language does not exist.");
        }

        if (!await _context.Publishers.AnyAsync(p => p.Id == publisherId, cancellationToken))
        {
            throw new ValidationAppException("Publisher does not exist.");
        }

        if (authorIds.Count > 0)
        {
            var existingCount = await _context.Authors.CountAsync(a => authorIds.Contains(a.Id), cancellationToken);
            if (existingCount != authorIds.Distinct().Count())
            {
                throw new ValidationAppException("One or more authors do not exist.");
            }
        }
    }

    private static BookDetailDto MapDetail(Book book)
    {
        var today = DateTime.UtcNow.Date;
        return new BookDetailDto
        {
            Id = book.Id,
            Title = book.Title,
            Edition = book.Edition,
            Description = book.Description,
            CoverImagePath = book.CoverImagePath,
            GenreId = book.GenreId,
            GenreName = book.Genre.Name,
            BookCategoryId = book.BookCategoryId,
            CategoryName = book.BookCategory.Name,
            LanguageId = book.LanguageId,
            LanguageName = book.Language.Name,
            PublisherId = book.PublisherId,
            PublisherName = book.Publisher.Name,
            CreatedAt = book.CreatedAt,
            Authors = book.BookAuthors.Select(ba => new AuthorDto
            {
                Id = ba.Author.Id,
                FirstName = ba.Author.FirstName,
                LastName = ba.Author.LastName,
                Biography = ba.Author.Biography
            }).ToList(),
            Copies = book.BookCopies.Select(c => new BookCopyDto
            {
                Id = c.Id,
                InventoryCode = c.InventoryCode,
                IsAvailable = BookCopyAvailability.IsRentableOnDate(c, today)
            }).ToList(),
            TotalCopies = book.BookCopies.Count,
            AvailableCopies = BookCopyAvailability.CountRentableCopies(book.BookCopies, today)
        };
    }
}
