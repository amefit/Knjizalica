using Knjizalica.Api.Common;
using Knjizalica.Api.Data;
using Knjizalica.Api.Data.Entities;
using Knjizalica.Api.DTOs.Reservations;
using Knjizalica.Api.StateMachine;
using Knjizalica.Shared.Constants;
using Knjizalica.Shared.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Services;

public interface IReservationService
{
    Task<PagedResult<ReservationDto>> GetAllAsync(ReservationFilterQuery query, CancellationToken cancellationToken = default);
    Task<PagedResult<ReservationDto>> GetMyReservationsAsync(ReservationFilterQuery query, CancellationToken cancellationToken = default);
    Task<ReservationDto> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<ReservationDto> CreateAsync(CreateReservationRequest request, CancellationToken cancellationToken = default);
    Task<ReservationDto> CancelAsync(int id, CancelReservationRequest request, CancellationToken cancellationToken = default);
    Task<ReservationDto> ConfirmAsync(int id, CancellationToken cancellationToken = default);
    Task<ReservationDto> CompleteAsync(int id, CancellationToken cancellationToken = default);
    Task<AvailabilityCalendarDto> GetAvailabilityCalendarAsync(int bookCopyId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default);
}

public sealed class ReservationService : IReservationService
{
    private readonly ApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;
    private readonly IActivityLogService _activityLog;
    private readonly INotificationDispatchService _notifications;

    public ReservationService(
        ApplicationDbContext context,
        ICurrentUserService currentUser,
        IActivityLogService activityLog,
        INotificationDispatchService notifications)
    {
        _context = context;
        _currentUser = currentUser;
        _activityLog = activityLog;
        _notifications = notifications;
    }

    public Task<PagedResult<ReservationDto>> GetAllAsync(ReservationFilterQuery query, CancellationToken cancellationToken = default) =>
        GetReservationsAsync(query, null, cancellationToken);

    public async Task<PagedResult<ReservationDto>> GetMyReservationsAsync(ReservationFilterQuery query, CancellationToken cancellationToken = default)
    {
        var userId = _currentUser.UserId
            ?? throw new UnauthorizedAppException("User is not authenticated.");

        var profileId = await _context.MemberProfiles
            .Where(m => m.UserId == userId)
            .Select(m => (int?)m.Id)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("Member profile not found.");

        return await GetReservationsAsync(query, profileId, cancellationToken);
    }

    public async Task<ReservationDto> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var reservation = await BuildQuery().FirstOrDefaultAsync(r => r.Id == id, cancellationToken)
            ?? throw new NotFoundException("Reservation not found.");

        await EnsureAccessAsync(reservation, cancellationToken);
        return MapReservation(reservation);
    }

    public async Task<ReservationDto> CreateAsync(CreateReservationRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUser.UserId
            ?? throw new UnauthorizedAppException("User is not authenticated.");

        var member = await _context.MemberProfiles
            .Include(m => m.User)
            .Include(m => m.MembershipStatus)
            .FirstOrDefaultAsync(m => m.UserId == userId, cancellationToken)
            ?? throw new NotFoundException("Member profile not found.");

        MemberEligibility.EnsureCanBorrowAndReserve(member);

        var copy = await _context.BookCopies
            .Include(c => c.Book)
            .FirstOrDefaultAsync(c => c.Id == request.BookCopyId, cancellationToken)
            ?? throw new NotFoundException("Book copy not found.");

        var fromDate = request.FromDate.Date;
        var toDate = request.ToDate.Date;

        if (fromDate < DateTime.UtcNow.Date)
        {
            throw new ValidationAppException("Reservation cannot be in the past.");
        }

        if (toDate < fromDate)
        {
            throw new ValidationAppException("ToDate must be on or after FromDate.");
        }

        await EnsureNoReservationOverlapAsync(copy.Id, fromDate, toDate, null, cancellationToken);
        await EnsureNoLoanOverlapAsync(copy.Id, fromDate, toDate, cancellationToken);

        var pendingStatus = await _context.ReservationStatuses
            .FirstAsync(s => s.Name == ReservationStatusNames.Pending, cancellationToken);

        var reservation = new Reservation
        {
            MemberProfileId = member.Id,
            BookCopyId = copy.Id,
            ReservationStatusId = pendingStatus.Id,
            FromDate = fromDate,
            ToDate = toDate,
            CreatedAt = DateTime.UtcNow
        };

        _context.Reservations.Add(reservation);
        await _context.SaveChangesAsync(cancellationToken);
        await _activityLog.LogAsync("Reservation Created", "Reservation", reservation.Id, $"Reservation created for '{copy.Book.Title}'.", cancellationToken: cancellationToken);

        await _notifications.SendAsync(
            member.UserId,
            "Reservation created",
            $"Your reservation for '{copy.Book.Title}' from {fromDate:yyyy-MM-dd} to {toDate:yyyy-MM-dd} was submitted.",
            cancellationToken: cancellationToken);

        return await GetByIdAsync(reservation.Id, cancellationToken);
    }

    public async Task<ReservationDto> CancelAsync(int id, CancelReservationRequest request, CancellationToken cancellationToken = default)
    {
        var reservation = await LoadForUpdateAsync(id, cancellationToken);
        ReservationStateMachine.ValidateTransition(reservation.ReservationStatus.Name, ReservationStatusNames.Cancelled);

        if (!_currentUser.IsInRole(RoleNames.Admin))
        {
            var userId = _currentUser.UserId
                ?? throw new UnauthorizedAppException("User is not authenticated.");

            if (reservation.MemberProfile.UserId != userId)
            {
                throw new UnauthorizedAppException("You can only cancel your own reservations.");
            }
        }

        var cancelledStatus = await _context.ReservationStatuses
            .FirstAsync(s => s.Name == ReservationStatusNames.Cancelled, cancellationToken);

        reservation.ReservationStatusId = cancelledStatus.Id;
        reservation.CancelledAt = DateTime.UtcNow;
        reservation.CancelledByUserId = _currentUser.UserId;
        reservation.CancellationReason = request.Reason?.Trim();

        await _context.SaveChangesAsync(cancellationToken);
        await _activityLog.LogAsync("Reservation Cancelled", "Reservation", reservation.Id, $"Reservation #{reservation.Id} was cancelled. Reason: {reservation.CancellationReason}", cancellationToken: cancellationToken);

        await _notifications.SendAsync(
            reservation.MemberProfile.UserId,
            "Reservation cancelled",
            $"Your reservation for '{reservation.BookCopy.Book.Title}' was cancelled.",
            cancellationToken: cancellationToken);

        return MapReservation(reservation);
    }

    public async Task<ReservationDto> ConfirmAsync(int id, CancellationToken cancellationToken = default)
    {
        var reservation = await LoadForUpdateAsync(id, cancellationToken);
        ReservationStateMachine.ValidateTransition(reservation.ReservationStatus.Name, ReservationStatusNames.Confirmed);

        await EnsureNoReservationOverlapAsync(
            reservation.BookCopyId,
            reservation.FromDate,
            reservation.ToDate,
            reservation.Id,
            cancellationToken);

        await EnsureNoLoanOverlapAsync(
            reservation.BookCopyId,
            reservation.FromDate,
            reservation.ToDate,
            cancellationToken);

        var confirmedStatus = await _context.ReservationStatuses
            .FirstAsync(s => s.Name == ReservationStatusNames.Confirmed, cancellationToken);

        reservation.ReservationStatusId = confirmedStatus.Id;
        reservation.ApprovedByUserId = _currentUser.UserId;
        reservation.ApprovedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);
        await _activityLog.LogAsync("Reservation Confirmed", "Reservation", reservation.Id, $"Reservation #{reservation.Id} was confirmed.", cancellationToken: cancellationToken);

        await _notifications.SendAsync(
            reservation.MemberProfile.UserId,
            "Reservation confirmed",
            $"Your reservation for '{reservation.BookCopy.Book.Title}' was confirmed.",
            sendEmail: true,
            email: reservation.MemberProfile.User.Email,
            cancellationToken: cancellationToken);

        return MapReservation(reservation);
    }

    public async Task<ReservationDto> CompleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var reservation = await LoadForUpdateAsync(id, cancellationToken);
        ReservationStateMachine.ValidateTransition(reservation.ReservationStatus.Name, ReservationStatusNames.Completed);

        var completedStatus = await _context.ReservationStatuses
            .FirstAsync(s => s.Name == ReservationStatusNames.Completed, cancellationToken);

        reservation.ReservationStatusId = completedStatus.Id;

        await _context.SaveChangesAsync(cancellationToken);
        await _activityLog.LogAsync("Reservation Completed", "Reservation", reservation.Id, $"Reservation #{reservation.Id} was completed.", cancellationToken: cancellationToken);

        return MapReservation(reservation);
    }

    public async Task<AvailabilityCalendarDto> GetAvailabilityCalendarAsync(int bookCopyId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken = default)
    {
        var copy = await _context.BookCopies.AsNoTracking()
            .Include(c => c.Book)
            .Include(c => c.Reservations).ThenInclude(r => r.ReservationStatus)
            .Include(c => c.Loans).ThenInclude(l => l.LoanStatus)
            .FirstOrDefaultAsync(c => c.Id == bookCopyId, cancellationToken)
            ?? throw new NotFoundException("Book copy not found.");

        var rangeStart = fromDate.Date;
        var rangeEnd = toDate.Date;

        if (rangeEnd < rangeStart)
        {
            throw new ValidationAppException("ToDate must be on or after FromDate.");
        }

        var occupied = BookCopyAvailability.GetOccupiedPeriods(copy, rangeStart, rangeEnd).ToList();
        var freePeriods = CalculateFreePeriods(rangeStart, rangeEnd, occupied);

        return new AvailabilityCalendarDto
        {
            BookCopyId = copy.Id,
            InventoryCode = copy.InventoryCode,
            BookId = copy.BookId,
            BookTitle = copy.Book.Title,
            FromDate = rangeStart,
            ToDate = rangeEnd,
            OccupiedPeriods = occupied,
            FreePeriods = freePeriods
        };
    }

    private async Task<PagedResult<ReservationDto>> GetReservationsAsync(ReservationFilterQuery query, int? memberProfileId, CancellationToken cancellationToken)
    {
        var reservations = BuildQuery();

        if (memberProfileId.HasValue)
        {
            reservations = reservations.Where(r => r.MemberProfileId == memberProfileId.Value);
        }

        if (!string.IsNullOrWhiteSpace(query.Status))
        {
            reservations = reservations.Where(r => r.ReservationStatus.Name == query.Status);
        }

        if (query.MemberProfileId.HasValue)
        {
            reservations = reservations.Where(r => r.MemberProfileId == query.MemberProfileId.Value);
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            reservations = reservations.Where(r =>
                r.BookCopy.Book.Title.ToLower().Contains(search) ||
                r.BookCopy.InventoryCode.ToLower().Contains(search) ||
                r.MemberProfile.User.FirstName.ToLower().Contains(search) ||
                r.MemberProfile.User.LastName.ToLower().Contains(search));
        }

        var projected = reservations
            .OrderByDescending(r => r.CreatedAt)
            .Select(r => new ReservationDto
            {
                Id = r.Id,
                MemberProfileId = r.MemberProfileId,
                MemberName = r.MemberProfile.User.FirstName + " " + r.MemberProfile.User.LastName,
                BookCopyId = r.BookCopyId,
                InventoryCode = r.BookCopy.InventoryCode,
                BookId = r.BookCopy.BookId,
                BookTitle = r.BookCopy.Book.Title,
                CoverImagePath = r.BookCopy.Book.CoverImagePath,
                Status = r.ReservationStatus.Name,
                FromDate = r.FromDate,
                ToDate = r.ToDate,
                CreatedAt = r.CreatedAt,
                ApprovedByName = r.ApprovedByUser != null ? r.ApprovedByUser.FirstName + " " + r.ApprovedByUser.LastName : null,
                ApprovedAt = r.ApprovedAt,
                CancelledAt = r.CancelledAt,
                CancelledByName = r.CancelledByUser != null ? r.CancelledByUser.FirstName + " " + r.CancelledByUser.LastName : null,
                CancellationReason = r.CancellationReason
            });

        return await projected.ToPagedResultAsync(query, cancellationToken);
    }

    private IQueryable<Reservation> BuildQuery() =>
        _context.Reservations.AsNoTracking()
            .Include(r => r.MemberProfile).ThenInclude(m => m.User)
            .Include(r => r.BookCopy).ThenInclude(c => c.Book)
            .Include(r => r.ReservationStatus)
            .Include(r => r.ApprovedByUser)
            .Include(r => r.CancelledByUser);

    private async Task<Reservation> LoadForUpdateAsync(int id, CancellationToken cancellationToken) =>
        await _context.Reservations
            .Include(r => r.MemberProfile).ThenInclude(m => m.User)
            .Include(r => r.BookCopy).ThenInclude(c => c.Book)
            .Include(r => r.ReservationStatus)
            .Include(r => r.ApprovedByUser)
            .Include(r => r.CancelledByUser)
            .FirstOrDefaultAsync(r => r.Id == id, cancellationToken)
        ?? throw new NotFoundException("Reservation not found.");

    private async Task EnsureAccessAsync(Reservation reservation, CancellationToken cancellationToken)
    {
        if (_currentUser.IsInRole(RoleNames.Admin))
        {
            return;
        }

        var userId = _currentUser.UserId
            ?? throw new UnauthorizedAppException("User is not authenticated.");

        if (reservation.MemberProfile.UserId != userId)
        {
            throw new UnauthorizedAppException("You do not have access to this reservation.");
        }

        await Task.CompletedTask;
    }

    private async Task EnsureNoReservationOverlapAsync(int bookCopyId, DateTime fromDate, DateTime toDate, int? excludeId, CancellationToken cancellationToken)
    {
        var activeStatuses = new[] { ReservationStatusNames.Pending, ReservationStatusNames.Confirmed };
        var hasOverlap = await _context.Reservations
            .Include(r => r.ReservationStatus)
            .AnyAsync(r =>
                r.BookCopyId == bookCopyId &&
                activeStatuses.Contains(r.ReservationStatus.Name) &&
                r.FromDate <= toDate &&
                r.ToDate >= fromDate &&
                (!excludeId.HasValue || r.Id != excludeId.Value), cancellationToken);

        if (hasOverlap)
        {
            throw new BusinessException("Book copy already has an overlapping reservation.");
        }
    }

    private async Task EnsureNoLoanOverlapAsync(int bookCopyId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken)
    {
        var activeStatuses = new[] { LoanStatusNames.Pending, LoanStatusNames.Confirmed, LoanStatusNames.Overdue };
        var hasOverlap = await _context.Loans
            .Include(l => l.LoanStatus)
            .AnyAsync(l =>
                l.BookCopyId == bookCopyId &&
                activeStatuses.Contains(l.LoanStatus.Name) &&
                l.BorrowedAt.Date <= toDate &&
                l.DueDate.Date >= fromDate, cancellationToken);

        if (hasOverlap)
        {
            throw new BusinessException("Book copy has an overlapping active loan.");
        }
    }

    private static IReadOnlyList<DateRangeDto> CalculateFreePeriods(DateTime rangeStart, DateTime rangeEnd, IReadOnlyList<OccupiedPeriodDto> occupied)
    {
        var free = new List<DateRangeDto>();
        var cursor = rangeStart;

        foreach (var period in occupied.OrderBy(o => o.FromDate))
        {
            if (period.FromDate > cursor)
            {
                free.Add(new DateRangeDto { FromDate = cursor, ToDate = period.FromDate.AddDays(-1) });
            }

            if (period.ToDate >= cursor)
            {
                cursor = period.ToDate.AddDays(1);
            }
        }

        if (cursor <= rangeEnd)
        {
            free.Add(new DateRangeDto { FromDate = cursor, ToDate = rangeEnd });
        }

        return free;
    }

    private static ReservationDto MapReservation(Reservation r) => new()
    {
        Id = r.Id,
        MemberProfileId = r.MemberProfileId,
        MemberName = $"{r.MemberProfile.User.FirstName} {r.MemberProfile.User.LastName}",
        BookCopyId = r.BookCopyId,
        InventoryCode = r.BookCopy.InventoryCode,
        BookId = r.BookCopy.BookId,
        BookTitle = r.BookCopy.Book.Title,
        CoverImagePath = r.BookCopy.Book.CoverImagePath,
        Status = r.ReservationStatus.Name,
        FromDate = r.FromDate,
        ToDate = r.ToDate,
        CreatedAt = r.CreatedAt,
        ApprovedByName = r.ApprovedByUser != null ? $"{r.ApprovedByUser.FirstName} {r.ApprovedByUser.LastName}" : null,
        ApprovedAt = r.ApprovedAt,
        CancelledAt = r.CancelledAt,
        CancelledByName = r.CancelledByUser != null ? $"{r.CancelledByUser.FirstName} {r.CancelledByUser.LastName}" : null,
        CancellationReason = r.CancellationReason
    };
}
