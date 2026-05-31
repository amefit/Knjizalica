using Knjizalica.Shared.Constants;
using Knjizalica.Shared.Exceptions;

namespace Knjizalica.Api.StateMachine;

public static class LoanStateMachine
{
    private static readonly Dictionary<string, HashSet<string>> AllowedTransitions = new()
    {
        [LoanStatusNames.Pending] = [LoanStatusNames.Confirmed, LoanStatusNames.Cancelled],
        [LoanStatusNames.Confirmed] = [LoanStatusNames.Completed, LoanStatusNames.Overdue, LoanStatusNames.Cancelled],
        [LoanStatusNames.Overdue] = [LoanStatusNames.Completed, LoanStatusNames.Cancelled],
        [LoanStatusNames.Completed] = [],
        [LoanStatusNames.Cancelled] = []
    };

    public static void ValidateTransition(string currentStatus, string newStatus)
    {
        if (!AllowedTransitions.TryGetValue(currentStatus, out var allowed) || !allowed.Contains(newStatus))
        {
            throw new BusinessException($"Cannot transition loan from '{currentStatus}' to '{newStatus}'.");
        }
    }

    public static bool CanTransition(string currentStatus, string newStatus) =>
        AllowedTransitions.TryGetValue(currentStatus, out var allowed) && allowed.Contains(newStatus);
}
