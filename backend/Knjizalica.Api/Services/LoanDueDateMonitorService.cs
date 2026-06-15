using Knjizalica.Api.Data;
using Knjizalica.Api.Data.Entities;
using Knjizalica.Api.Messaging;
using Knjizalica.Shared.Constants;
using Knjizalica.Shared.Messages;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Services;

public sealed class LoanDueDateMonitorService
{
    private const string DueReminderTitle = "Return reminder";
    private const string OverdueTitle = "Loan overdue";

    private readonly ApplicationDbContext _context;
    private readonly IMessagePublisher _publisher;
    private readonly ILogger<LoanDueDateMonitorService> _logger;

    public LoanDueDateMonitorService(
        ApplicationDbContext context,
        IMessagePublisher publisher,
        ILogger<LoanDueDateMonitorService> logger)
    {
        _context = context;
        _publisher = publisher;
        _logger = logger;
    }

    public async Task ProcessAsync(CancellationToken cancellationToken = default)
    {
        var today = DateTime.UtcNow.Date;
        var overdueStatus = await _context.LoanStatuses
            .FirstAsync(s => s.Name == LoanStatusNames.Overdue, cancellationToken);

        var openLoans = await _context.Loans
            .Include(l => l.LoanStatus)
            .Include(l => l.MemberProfile).ThenInclude(m => m.User)
            .Include(l => l.BookCopy).ThenInclude(c => c.Book)
            .Where(l => l.ReturnedAt == null &&
                (l.LoanStatus.Name == LoanStatusNames.Confirmed || l.LoanStatus.Name == LoanStatusNames.Overdue))
            .ToListAsync(cancellationToken);

        var dueReminders = 0;
        var overdueMarked = 0;
        var overdueReminders = 0;

        foreach (var loan in openLoans)
        {
            if (LoanOverdueRules.IsDueSoon(loan, LoanOverdueRules.DefaultReminderDaysBeforeDue, today))
            {
                if (await TrySendNotificationAsync(
                        loan,
                        DueReminderTitle,
                        $"Your loan for '{loan.BookCopy.Book.Title}' is due on {loan.DueDate:yyyy-MM-dd}. Please return the book on time.",
                        sendEmail: true,
                        cancellationToken))
                {
                    dueReminders++;
                }
            }

            if (loan.LoanStatus.Name == LoanStatusNames.Confirmed && LoanOverdueRules.ShouldMarkOverdue(loan, today))
            {
                loan.LoanStatusId = overdueStatus.Id;
                overdueMarked++;

                if (await TrySendNotificationAsync(
                        loan,
                        OverdueTitle,
                        $"Your loan for '{loan.BookCopy.Book.Title}' is overdue. Due date was {loan.DueDate:yyyy-MM-dd}. Please return the book as soon as possible.",
                        sendEmail: true,
                        cancellationToken))
                {
                    overdueReminders++;
                }

                continue;
            }

            if (loan.LoanStatus.Name == LoanStatusNames.Overdue &&
                await TrySendNotificationAsync(
                    loan,
                    OverdueTitle,
                    $"Your loan for '{loan.BookCopy.Book.Title}' is still overdue. Please return the book as soon as possible.",
                    sendEmail: true,
                    cancellationToken))
            {
                overdueReminders++;
            }
        }

        if (dueReminders > 0 || overdueMarked > 0 || overdueReminders > 0)
        {
            await _context.SaveChangesAsync(cancellationToken);
        }

        _logger.LogInformation(
            "Loan due-date monitor completed. Due reminders: {DueReminders}, marked overdue: {OverdueMarked}, overdue reminders: {OverdueReminders}",
            dueReminders,
            overdueMarked,
            overdueReminders);
    }

    private async Task<bool> TrySendNotificationAsync(
        Loan loan,
        string title,
        string message,
        bool sendEmail,
        CancellationToken cancellationToken)
    {
        var userId = loan.MemberProfile.UserId;
        var bookTitle = loan.BookCopy.Book.Title;

        if (await WasNotifiedTodayAsync(userId, title, bookTitle, cancellationToken))
        {
            return false;
        }

        _context.Notifications.Add(new Notification
        {
            UserId = userId,
            Title = title,
            Message = message,
            IsRead = false,
            CreatedAt = DateTime.UtcNow
        });

        if (sendEmail && !string.IsNullOrWhiteSpace(loan.MemberProfile.User.Email))
        {
            await _publisher.PublishEmailAsync(new SendEmailMessage
            {
                ToEmail = loan.MemberProfile.User.Email!,
                Subject = title,
                Body = message
            }, cancellationToken);
        }

        return true;
    }

    private Task<bool> WasNotifiedTodayAsync(int userId, string title, string bookTitle, CancellationToken cancellationToken)
    {
        var today = DateTime.UtcNow.Date;
        return _context.Notifications.AnyAsync(
            n => n.UserId == userId &&
                 n.Title == title &&
                 n.Message.Contains(bookTitle) &&
                 n.CreatedAt.Date == today,
            cancellationToken);
    }
}
