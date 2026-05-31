using Knjizalica.Shared.Constants;
using Knjizalica.Shared.Exceptions;

namespace Knjizalica.Api.StateMachine;

public static class ReservationStateMachine
{
    private static readonly Dictionary<string, HashSet<string>> AllowedTransitions = new()
    {
        [ReservationStatusNames.Pending] = [ReservationStatusNames.Confirmed, ReservationStatusNames.Cancelled],
        [ReservationStatusNames.Confirmed] = [ReservationStatusNames.Completed, ReservationStatusNames.Cancelled],
        [ReservationStatusNames.Completed] = [],
        [ReservationStatusNames.Cancelled] = []
    };

    public static void ValidateTransition(string currentStatus, string newStatus)
    {
        if (!AllowedTransitions.TryGetValue(currentStatus, out var allowed) || !allowed.Contains(newStatus))
        {
            throw new BusinessException($"Cannot transition reservation from '{currentStatus}' to '{newStatus}'.");
        }
    }
}
