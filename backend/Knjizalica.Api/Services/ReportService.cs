using Knjizalica.Api.Data;
using Knjizalica.Api.Data.Entities;
using Knjizalica.Shared.Constants;
using Knjizalica.Shared.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Services;

public interface IReportService
{
    Task<byte[]> GenerateOverdueLoansReportAsync(CancellationToken cancellationToken = default);
    Task<byte[]> GenerateLoansByPeriodReportAsync(DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default);
}

public sealed class ReportService : IReportService
{
    private readonly ApplicationDbContext _context;

    public ReportService(ApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<byte[]> GenerateOverdueLoansReportAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        var loans = await _context.Loans.AsNoTracking()
            .Include(l => l.MemberProfile).ThenInclude(m => m.User)
            .Include(l => l.BookCopy).ThenInclude(c => c.Book)
            .Include(l => l.LoanStatus)
            .Where(l =>
                l.ReturnedAt == null &&
                (l.LoanStatus.Name == LoanStatusNames.Overdue ||
                 (l.LoanStatus.Name == LoanStatusNames.Confirmed && l.DueDate < now)))
            .OrderBy(l => l.DueDate)
            .ToListAsync(cancellationToken);

        var lines = new List<string>
        {
            "#  Member                         Book                           Inventory    Due        Days"
        };

        if (loans.Count == 0)
        {
            lines.Add("No overdue loans.");
        }
        else
        {
            var index = 1;
            foreach (var loan in loans)
            {
                var daysOverdue = Math.Max(0, (int)(now.Date - loan.DueDate.Date).TotalDays);
                lines.Add(FormatRow(
                    index.ToString(),
                    MemberName(loan.MemberProfile),
                    loan.BookCopy.Book.Title,
                    loan.BookCopy.InventoryCode,
                    loan.DueDate.ToString("yyyy-MM-dd"),
                    daysOverdue.ToString()));
                index++;
            }
        }

        return MinimalPdfBuilder.Build(
            "Overdue Loans Report",
            $"Generated: {DateTime.UtcNow:yyyy-MM-dd HH:mm} UTC",
            lines);
    }

    public async Task<byte[]> GenerateLoansByPeriodReportAsync(DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
    {
        if (toDate < fromDate)
        {
            throw new ValidationAppException("From date must be before or equal to to date.");
        }

        var from = fromDate.Date;
        var to = toDate.Date.AddDays(1).AddTicks(-1);

        var loans = await _context.Loans.AsNoTracking()
            .Include(l => l.MemberProfile).ThenInclude(m => m.User)
            .Include(l => l.BookCopy).ThenInclude(c => c.Book)
            .Include(l => l.LoanStatus)
            .Where(l => l.BorrowedAt >= from && l.BorrowedAt <= to)
            .OrderBy(l => l.BorrowedAt)
            .ToListAsync(cancellationToken);

        var lines = new List<string>
        {
            "#  Member                         Book                           Inventory    Borrowed   Due        Status"
        };

        if (loans.Count == 0)
        {
            lines.Add("No loans in the selected period.");
        }
        else
        {
            var index = 1;
            foreach (var loan in loans)
            {
                lines.Add(FormatRow(
                    index.ToString(),
                    MemberName(loan.MemberProfile),
                    loan.BookCopy.Book.Title,
                    loan.BookCopy.InventoryCode,
                    loan.BorrowedAt.ToString("yyyy-MM-dd"),
                    loan.DueDate.ToString("yyyy-MM-dd"),
                    loan.LoanStatus.Name));
                index++;
            }
        }

        return MinimalPdfBuilder.Build(
            "Loans By Period Report",
            $"Period: {fromDate:yyyy-MM-dd} to {toDate:yyyy-MM-dd} | Generated: {DateTime.UtcNow:yyyy-MM-dd} UTC",
            lines);
    }

    private static string MemberName(MemberProfile profile) =>
        $"{profile.User.FirstName} {profile.User.LastName}";

    private static string FormatRow(params string[] columns)
    {
        if (columns.Length == 6)
        {
            return $"{Pad(columns[0], 2)} {Pad(columns[1], 30)} {Pad(columns[2], 30)} {Pad(columns[3], 12)} {Pad(columns[4], 10)} {Pad(columns[5], 4)}";
        }

        return $"{Pad(columns[0], 2)} {Pad(columns[1], 30)} {Pad(columns[2], 30)} {Pad(columns[3], 12)} {Pad(columns[4], 10)} {Pad(columns[5], 10)} {Pad(columns[6], 12)}";
    }

    private static string Pad(string value, int width)
    {
        value = value.Length > width ? value[..width] : value;
        return value.PadRight(width);
    }
}
