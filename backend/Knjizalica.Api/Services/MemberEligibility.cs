using Knjizalica.Api.Data.Entities;
using Knjizalica.Shared.Constants;
using Knjizalica.Shared.Exceptions;

namespace Knjizalica.Api.Services;

internal static class MemberEligibility
{
    public static void EnsureCanBorrowAndReserve(MemberProfile member, DateTime? asOfDate = null)
    {
        if (member.MembershipStatus.Name != MembershipStatusNames.Active)
        {
            throw new BusinessException("Member is not active.");
        }

        var today = (asOfDate ?? DateTime.UtcNow).Date;
        if (member.ExpiryDate.Date < today)
        {
            throw new BusinessException("Membership has expired.");
        }
    }
}
