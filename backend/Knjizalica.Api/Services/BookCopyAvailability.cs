using Knjizalica.Api.Data.Entities;
using Knjizalica.Shared.Constants;

namespace Knjizalica.Api.Services;

internal static class BookCopyAvailability
{
    public static bool HasActiveReservationOnDate(BookCopy copy, DateTime date) =>
        copy.Reservations.Any(r =>
            IsActiveReservationStatus(r.ReservationStatus?.Name) &&
            r.FromDate.Date <= date.Date &&
            r.ToDate.Date >= date.Date);

    public static bool IsRentableOnDate(BookCopy copy, DateTime date) =>
        copy.IsAvailable && !HasActiveReservationOnDate(copy, date);

    public static int CountRentableCopies(IEnumerable<BookCopy> copies, DateTime date) =>
        copies.Count(c => IsRentableOnDate(c, date));

    public static bool IsActiveReservationStatus(string? status) =>
        status is ReservationStatusNames.Pending or ReservationStatusNames.Confirmed;
}
