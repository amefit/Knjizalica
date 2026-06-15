using Knjizalica.Api.Data.Entities;
using Knjizalica.Shared.Constants;

namespace Knjizalica.Api.Services;

internal static class LoanOverdueRules
{
    public const int DefaultReminderDaysBeforeDue = 1;

    public static bool IsOverdue(string status, DateTime dueDate, DateTime? returnedAt, DateTime? asOf = null)
    {
        if (returnedAt.HasValue)
        {
            return false;
        }

        if (status == LoanStatusNames.Overdue)
        {
            return true;
        }

        var now = asOf ?? DateTime.UtcNow;
        return status == LoanStatusNames.Confirmed && dueDate < now;
    }

    public static bool IsOverdue(Loan loan, DateTime? asOf = null) =>
        IsOverdue(loan.LoanStatus.Name, loan.DueDate, loan.ReturnedAt, asOf);

    public static bool ShouldMarkOverdue(Loan loan, DateTime? asOf = null)
    {
        if (loan.ReturnedAt.HasValue || loan.LoanStatus.Name != LoanStatusNames.Confirmed)
        {
            return false;
        }

        var today = (asOf ?? DateTime.UtcNow).Date;
        return loan.DueDate.Date < today;
    }

    public static bool IsDueSoon(Loan loan, int daysBeforeDue = DefaultReminderDaysBeforeDue, DateTime? asOf = null)
    {
        if (loan.ReturnedAt.HasValue || loan.LoanStatus.Name != LoanStatusNames.Confirmed)
        {
            return false;
        }

        var today = (asOf ?? DateTime.UtcNow).Date;
        return loan.DueDate.Date == today.AddDays(daysBeforeDue);
    }
}
