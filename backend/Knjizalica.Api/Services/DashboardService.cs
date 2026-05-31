using Knjizalica.Api.Data;
using Knjizalica.Api.DTOs.Dashboard;
using Knjizalica.Shared.Constants;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Services;

public interface IDashboardService
{
    Task<DashboardDto> GetDashboardAsync(CancellationToken cancellationToken = default);
}

public sealed class DashboardService : IDashboardService
{
    private readonly ApplicationDbContext _context;

    public DashboardService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<DashboardDto> GetDashboardAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var monthStart = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        var totalBooks = await _context.Books.CountAsync(cancellationToken);
        var totalCopies = await _context.BookCopies.CountAsync(cancellationToken);
        var availableCopies = await _context.BookCopies.CountAsync(c => c.IsAvailable, cancellationToken);

        var activeLoanStatuses = new[] { LoanStatusNames.Confirmed, LoanStatusNames.Overdue };
        var activeLoans = await _context.Loans
            .Include(l => l.LoanStatus)
            .CountAsync(l => activeLoanStatuses.Contains(l.LoanStatus.Name), cancellationToken);

        var overdueLoans = await _context.Loans
            .Include(l => l.LoanStatus)
            .CountAsync(l =>
                l.LoanStatus.Name == LoanStatusNames.Overdue ||
                (l.ReturnedAt == null && l.DueDate < now && l.LoanStatus.Name == LoanStatusNames.Confirmed), cancellationToken);

        var pendingLoans = await _context.Loans
            .Include(l => l.LoanStatus)
            .CountAsync(l => l.LoanStatus.Name == LoanStatusNames.Pending, cancellationToken);

        var totalMembers = await _context.MemberProfiles.CountAsync(cancellationToken);
        var newMembersThisMonth = await _context.MemberProfiles
            .CountAsync(m => m.RegistrationDate >= monthStart, cancellationToken);

        var yearStart = new DateTime(now.Year, 1, 1, 0, 0, 0, DateTimeKind.Utc);
        var newMembersThisYear = await _context.MemberProfiles
            .CountAsync(m => m.RegistrationDate >= yearStart, cancellationToken);

        var returnedBooksThisMonth = await _context.Loans
            .Include(l => l.LoanStatus)
            .CountAsync(l =>
                l.LoanStatus.Name == LoanStatusNames.Completed &&
                l.ReturnedAt != null &&
                l.ReturnedAt >= monthStart, cancellationToken);

        var pendingReservations = await _context.Reservations
            .Include(r => r.ReservationStatus)
            .CountAsync(r => r.ReservationStatus.Name == ReservationStatusNames.Pending, cancellationToken);

        var activeReservations = await _context.Reservations
            .Include(r => r.ReservationStatus)
            .CountAsync(r => r.ReservationStatus.Name == ReservationStatusNames.Confirmed, cancellationToken);

        var loansByMonth = await GetLoansByMonthAsync(cancellationToken);
        var loansLast7Days = await GetLoansLast7DaysAsync(cancellationToken);
        var topBorrowedBooks = await GetTopBorrowedBooksAsync(cancellationToken);
        var membersByCity = await GetMembersByCityAsync(cancellationToken);
        var loansByStatus = await GetLoansByStatusAsync(cancellationToken);
        var topGenres = await GetTopGenresAsync(cancellationToken);

        return new DashboardDto
        {
            Kpis = new DashboardKpiDto
            {
                TotalBooks = totalBooks,
                TotalBookCopies = totalCopies,
                AvailableCopies = availableCopies,
                ActiveLoans = activeLoans,
                OverdueLoans = overdueLoans,
                PendingLoans = pendingLoans,
                NewMembersThisMonth = newMembersThisMonth,
                NewMembersThisYear = newMembersThisYear,
                ReturnedBooksThisMonth = returnedBooksThisMonth,
                TotalMembers = totalMembers,
                PendingReservations = pendingReservations,
                ActiveReservations = activeReservations
            },
            Charts = new DashboardChartsDto
            {
                LoansByMonth = loansByMonth,
                TopBorrowedBooks = topBorrowedBooks,
                MembersByCity = membersByCity,
                LoansByStatus = loansByStatus,
                LoansLast7Days = loansLast7Days,
                TopGenres = topGenres
            }
        };
    }

    private async Task<IReadOnlyList<ChartDataPointDto>> GetLoansLast7DaysAsync(CancellationToken cancellationToken)
    {
        var today = DateTime.UtcNow.Date;
        var start = today.AddDays(-6);

        var counts = await _context.Loans.AsNoTracking()
            .Where(l => l.BorrowedAt >= start)
            .GroupBy(l => l.BorrowedAt.Date)
            .Select(g => new { Day = g.Key, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var result = new List<ChartDataPointDto>();
        for (var i = 0; i < 7; i++)
        {
            var day = start.AddDays(i);
            var count = counts.FirstOrDefault(c => c.Day == day)?.Count ?? 0;
            result.Add(new ChartDataPointDto
            {
                Label = day.ToString("ddd"),
                Value = count
            });
        }

        return result;
    }

    private async Task<IReadOnlyList<ChartDataPointDto>> GetTopGenresAsync(CancellationToken cancellationToken) =>
        await _context.Loans.AsNoTracking()
            .GroupBy(l => l.BookCopy.Book.Genre.Name)
            .OrderByDescending(g => g.Count())
            .Take(6)
            .Select(g => new ChartDataPointDto { Label = g.Key, Value = g.Count() })
            .ToListAsync(cancellationToken);

    private async Task<IReadOnlyList<ChartDataPointDto>> GetLoansByMonthAsync(CancellationToken cancellationToken)
    {
        var start = DateTime.UtcNow.AddMonths(-11);
        var startMonth = new DateTime(start.Year, start.Month, 1, 0, 0, 0, DateTimeKind.Utc);

        var loans = await _context.Loans.AsNoTracking()
            .Where(l => l.BorrowedAt >= startMonth)
            .GroupBy(l => new { l.BorrowedAt.Year, l.BorrowedAt.Month })
            .Select(g => new { g.Key.Year, g.Key.Month, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var result = new List<ChartDataPointDto>();
        for (var i = 0; i < 12; i++)
        {
            var date = startMonth.AddMonths(i);
            var count = loans.FirstOrDefault(l => l.Year == date.Year && l.Month == date.Month)?.Count ?? 0;
            result.Add(new ChartDataPointDto
            {
                Label = date.ToString("yyyy-MM"),
                Value = count
            });
        }

        return result;
    }

    private async Task<IReadOnlyList<ChartDataPointDto>> GetTopBorrowedBooksAsync(CancellationToken cancellationToken) =>
        await _context.Loans.AsNoTracking()
            .GroupBy(l => l.BookCopy.Book.Title)
            .OrderByDescending(g => g.Count())
            .Take(5)
            .Select(g => new ChartDataPointDto { Label = g.Key, Value = g.Count() })
            .ToListAsync(cancellationToken);

    private async Task<IReadOnlyList<ChartDataPointDto>> GetMembersByCityAsync(CancellationToken cancellationToken) =>
        await _context.MemberProfiles.AsNoTracking()
            .GroupBy(m => m.City.Name)
            .OrderByDescending(g => g.Count())
            .Select(g => new ChartDataPointDto { Label = g.Key, Value = g.Count() })
            .ToListAsync(cancellationToken);

    private async Task<IReadOnlyList<ChartDataPointDto>> GetLoansByStatusAsync(CancellationToken cancellationToken) =>
        await _context.Loans.AsNoTracking()
            .GroupBy(l => l.LoanStatus.Name)
            .Select(g => new ChartDataPointDto { Label = g.Key, Value = g.Count() })
            .ToListAsync(cancellationToken);
}
