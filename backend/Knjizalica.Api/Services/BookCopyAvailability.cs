using Knjizalica.Api.Data.Entities;
using Knjizalica.Api.DTOs.Reservations;
using Knjizalica.Shared.Constants;

namespace Knjizalica.Api.Services;

internal static class BookCopyAvailability
{
    public static bool IsActiveReservationStatus(string? status) =>
        status is ReservationStatusNames.Pending or ReservationStatusNames.Confirmed;

    public static bool IsActiveLoanStatus(string? status) =>
        status is LoanStatusNames.Pending or LoanStatusNames.Confirmed or LoanStatusNames.Overdue;

    public static bool IsPhysicallyAvailable(BookCopy copy) => copy.IsAvailable;

    public static bool HasActiveReservationOnDate(BookCopy copy, DateTime date) =>
        copy.Reservations.Any(r =>
            IsActiveReservationStatus(r.ReservationStatus?.Name) &&
            r.FromDate.Date <= date.Date &&
            r.ToDate.Date >= date.Date);

    public static bool HasActiveLoanOnDate(BookCopy copy, DateTime date) =>
        copy.Loans.Any(l =>
            IsActiveLoanStatus(l.LoanStatus?.Name) &&
            l.BorrowedAt.Date <= date.Date &&
            l.DueDate.Date >= date.Date);

    public static bool IsRentableOnDate(BookCopy copy, DateTime date) =>
        IsPhysicallyAvailable(copy) &&
        !HasActiveReservationOnDate(copy, date) &&
        !HasActiveLoanOnDate(copy, date);

    public static int CountRentableCopies(IEnumerable<BookCopy> copies, DateTime date) =>
        copies.Count(c => IsRentableOnDate(c, date));

    public static bool HasAnyRentableCopy(IEnumerable<BookCopy> copies, DateTime date) =>
        copies.Any(c => IsRentableOnDate(c, date));

    public static IReadOnlyList<OccupiedPeriodDto> GetOccupiedPeriods(BookCopy copy, DateTime rangeStart, DateTime rangeEnd)
    {
        var occupied = new List<OccupiedPeriodDto>();

        if (!IsPhysicallyAvailable(copy))
        {
            occupied.Add(new OccupiedPeriodDto
            {
                FromDate = rangeStart,
                ToDate = rangeEnd,
                Reason = "Copy unavailable",
                SourceType = "Physical"
            });
            return occupied;
        }

        occupied.AddRange(copy.Reservations
            .Where(r => IsActiveReservationStatus(r.ReservationStatus?.Name))
            .Where(r => r.FromDate.Date <= rangeEnd && r.ToDate.Date >= rangeStart)
            .Select(r => new OccupiedPeriodDto
            {
                FromDate = r.FromDate.Date,
                ToDate = r.ToDate.Date,
                Reason = $"Reservation ({r.ReservationStatus!.Name})",
                SourceType = "Reservation"
            }));

        occupied.AddRange(copy.Loans
            .Where(l => IsActiveLoanStatus(l.LoanStatus?.Name))
            .Where(l => l.BorrowedAt.Date <= rangeEnd && l.DueDate.Date >= rangeStart)
            .Select(l => new OccupiedPeriodDto
            {
                FromDate = l.BorrowedAt.Date,
                ToDate = l.DueDate.Date,
                Reason = $"Loan ({l.LoanStatus!.Name})",
                SourceType = "Loan"
            }));

        return occupied.OrderBy(o => o.FromDate).ToList();
    }
}
