using Knjizalica.Api.Data;
using Knjizalica.Api.DTOs.Books;
using Knjizalica.Api.DTOs.Recommendations;
using Knjizalica.Shared.Constants;
using Knjizalica.Shared.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Services;

public interface IRecommendationService
{
    Task<RecommendationsResponse> GetRecommendationsAsync(int limit = 10, CancellationToken cancellationToken = default);
}

public sealed class RecommendationService : IRecommendationService
{
    private readonly ApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;

    public RecommendationService(ApplicationDbContext context, ICurrentUserService currentUser)
    {
        _context = context;
        _currentUser = currentUser;
    }

    public async Task<RecommendationsResponse> GetRecommendationsAsync(int limit = 10, CancellationToken cancellationToken = default)
    {
        var userId = _currentUser.UserId
            ?? throw new UnauthorizedAppException("User is not authenticated.");

        limit = Math.Clamp(limit, 1, 50);

        var borrowedBookIds = await _context.Loans.AsNoTracking()
            .Where(l => l.MemberProfile.UserId == userId)
            .Select(l => l.BookCopy.BookId)
            .Distinct()
            .ToListAsync(cancellationToken);

        var searchedQueries = await _context.SearchHistories.AsNoTracking()
            .Where(s => s.UserId == userId)
            .OrderByDescending(s => s.CreatedAt)
            .Take(20)
            .Select(s => s.Query.ToLower())
            .ToListAsync(cancellationToken);

        var preferredGenres = await GetPreferredIdsAsync(borrowedBookIds, b => b.GenreId, cancellationToken);
        var preferredCategories = await GetPreferredIdsAsync(borrowedBookIds, b => b.BookCategoryId, cancellationToken);
        var preferredAuthors = await _context.BookAuthors.AsNoTracking()
            .Where(ba => borrowedBookIds.Contains(ba.BookId))
            .GroupBy(ba => ba.AuthorId)
            .OrderByDescending(g => g.Count())
            .Select(g => g.Key)
            .Take(5)
            .ToListAsync(cancellationToken);

        var allBooksLoaded = await _context.Books.AsNoTracking()
            .Include(b => b.Genre)
            .Include(b => b.BookCategory)
            .Include(b => b.Language)
            .Include(b => b.Publisher)
            .Include(b => b.BookAuthors).ThenInclude(ba => ba.Author)
            .Include(b => b.BookCopies).ThenInclude(c => c.Reservations).ThenInclude(r => r.ReservationStatus)
            .Include(b => b.BookCopies).ThenInclude(c => c.Loans).ThenInclude(l => l.LoanStatus)
            .ToListAsync(cancellationToken);

        var today = DateTime.UtcNow.Date;
        var allBooks = allBooksLoaded
            .Where(b => BookCopyAvailability.HasAnyRentableCopy(b.BookCopies, today))
            .ToList();

        var excludeIds = borrowedBookIds.ToHashSet();
        var candidates = allBooks.Where(b => !excludeIds.Contains(b.Id)).ToList();

        var contentBased = new List<RecommendationDto>();

        foreach (var book in candidates)
        {
            var reasons = new List<string>();
            var score = 0.0;

            if (preferredGenres.Contains(book.GenreId))
            {
                reasons.Add($"Because you enjoy {book.Genre.Name} books");
                score += 3;
            }

            if (preferredCategories.Contains(book.BookCategoryId))
            {
                reasons.Add($"Based on your interest in {book.BookCategory.Name}");
                score += 2;
            }

            var authorMatch = book.BookAuthors.FirstOrDefault(ba => preferredAuthors.Contains(ba.AuthorId));
            if (authorMatch != null)
            {
                reasons.Add($"Because you read {authorMatch.Author.FirstName} {authorMatch.Author.LastName}");
                score += 4;
            }

            if (searchedQueries.Any(q =>
                book.Title.ToLower().Contains(q) ||
                book.BookAuthors.Any(ba =>
                    ba.Author.FirstName.ToLower().Contains(q) ||
                    ba.Author.LastName.ToLower().Contains(q)) ||
                book.Genre.Name.ToLower().Contains(q) ||
                book.BookCategory.Name.ToLower().Contains(q)))
            {
                reasons.Add("Based on your recent searches");
                score += 2;
            }

            if (reasons.Count == 0)
            {
                continue;
            }

            contentBased.Add(new RecommendationDto
            {
                Book = MapBookList(book),
                Reason = string.Join("; ", reasons),
                Source = "ContentBased",
                Score = score
            });
        }

        contentBased = contentBased
            .OrderByDescending(r => r.Score)
            .Take(limit)
            .ToList();

        var ninetyDaysAgo = DateTime.UtcNow.AddDays(-90);
        var popularBookIds = await _context.Loans.AsNoTracking()
            .Include(l => l.LoanStatus)
            .Where(l => (l.LoanStatus.Name == LoanStatusNames.Completed || l.LoanStatus.Name == LoanStatusNames.Confirmed)
                        && l.BorrowedAt >= ninetyDaysAgo)
            .GroupBy(l => l.BookCopy.BookId)
            .OrderByDescending(g => g.Count())
            .Select(g => new { BookId = g.Key, Count = g.Count() })
            .Take(limit * 3)
            .ToListAsync(cancellationToken);

        var popularBooks = await _context.Books.AsNoTracking()
            .Include(b => b.Genre)
            .Include(b => b.BookCategory)
            .Include(b => b.Language)
            .Include(b => b.Publisher)
            .Include(b => b.BookAuthors).ThenInclude(ba => ba.Author)
            .Include(b => b.BookCopies).ThenInclude(c => c.Reservations).ThenInclude(r => r.ReservationStatus)
            .Include(b => b.BookCopies).ThenInclude(c => c.Loans).ThenInclude(l => l.LoanStatus)
            .Where(b => popularBookIds.Select(p => p.BookId).Contains(b.Id))
            .Where(b => !borrowedBookIds.Contains(b.Id))
            .ToListAsync(cancellationToken);

        var popular = popularBookIds
            .Join(popularBooks, p => p.BookId, b => b.Id, (p, b) => new { p, b })
            .Where(x => BookCopyAvailability.HasAnyRentableCopy(x.b.BookCopies, today))
            .Select(x => new RecommendationDto
            {
                Book = MapBookList(x.b),
                Reason = "One of the most borrowed books in the last 90 days",
                Source = "Popularity",
                Score = x.p.Count
            })
            .Take(limit)
            .ToList();

        return new RecommendationsResponse
        {
            ContentBased = contentBased,
            Popular = popular
        };
    }

    private async Task<List<int>> GetPreferredIdsAsync(List<int> bookIds, Func<Data.Entities.Book, int> selector, CancellationToken cancellationToken)
    {
        if (bookIds.Count == 0)
        {
            return [];
        }

        var books = await _context.Books.AsNoTracking()
            .Where(b => bookIds.Contains(b.Id))
            .ToListAsync(cancellationToken);

        return books
            .GroupBy(selector)
            .OrderByDescending(g => g.Count())
            .Select(g => g.Key)
            .Take(3)
            .ToList();
    }

    private static BookListDto MapBookList(Data.Entities.Book b)
    {
        var today = DateTime.UtcNow.Date;
        return new BookListDto
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
            AvailableCopies = BookCopyAvailability.CountRentableCopies(b.BookCopies, today),
            AuthorNames = b.BookAuthors.Select(ba => ba.Author.FirstName + " " + ba.Author.LastName).ToList()
        };
    }
}
