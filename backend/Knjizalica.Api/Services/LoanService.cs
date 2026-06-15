using Knjizalica.Api.Common;
using Knjizalica.Api.Data;
using Knjizalica.Api.Data.Entities;
using Knjizalica.Api.DTOs.Loans;
using Knjizalica.Api.StateMachine;
using Knjizalica.Shared.Constants;
using Knjizalica.Shared.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Services;

public interface ILoanService
{
    Task<PagedResult<LoanDto>> GetAllAsync(LoanFilterQuery query, CancellationToken cancellationToken = default);
    Task<PagedResult<LoanDto>> GetMyLoansAsync(LoanFilterQuery query, CancellationToken cancellationToken = default);
    Task<PagedResult<LoanDto>> GetOverdueAsync(PaginationQuery query, CancellationToken cancellationToken = default);
    Task<LoanDto> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<LoanDto> CreateAsync(CreateLoanRequest request, CancellationToken cancellationToken = default);
    Task<LoanDto> ConfirmAsync(int id, CancellationToken cancellationToken = default);
    Task<LoanDto> CompleteAsync(int id, CancellationToken cancellationToken = default);
    Task<LoanDto> ReturnAsync(int id, CancellationToken cancellationToken = default);
    Task<LoanDto> CancelAsync(int id, CancelLoanRequest request, CancellationToken cancellationToken = default);
}

public sealed class LoanService : ILoanService
{
    private readonly ApplicationDbContext _context;
    private readonly ICurrentUserService _currentUser;
    private readonly IActivityLogService _activityLog;
    private readonly INotificationDispatchService _notifications;

    public LoanService(
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

    public Task<PagedResult<LoanDto>> GetAllAsync(LoanFilterQuery query, CancellationToken cancellationToken = default) =>
        GetLoansAsync(query, null, cancellationToken);

    public async Task<PagedResult<LoanDto>> GetMyLoansAsync(LoanFilterQuery query, CancellationToken cancellationToken = default)
    {
        var userId = _currentUser.UserId
            ?? throw new UnauthorizedAppException("User is not authenticated.");

        var profileId = await _context.MemberProfiles
            .Where(m => m.UserId == userId)
            .Select(m => (int?)m.Id)
            .FirstOrDefaultAsync(cancellationToken)
            ?? throw new NotFoundException("Member profile not found.");

        return await GetLoansAsync(query, profileId, cancellationToken);
    }

    public async Task<PagedResult<LoanDto>> GetOverdueAsync(PaginationQuery query, CancellationToken cancellationToken = default)
    {
        var filter = new LoanFilterQuery
        {
            Page = query.Page,
            PageSize = query.PageSize,
            Search = query.Search,
            OverdueOnly = true
        };
        return await GetLoansAsync(filter, null, cancellationToken);
    }

    public async Task<LoanDto> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var loan = await BuildLoanQuery().FirstOrDefaultAsync(l => l.Id == id, cancellationToken)
            ?? throw new NotFoundException("Loan not found.");

        await EnsureAccessAsync(loan, cancellationToken);
        return MapLoan(loan);
    }

    public async Task<LoanDto> CreateAsync(CreateLoanRequest request, CancellationToken cancellationToken = default)
    {
        var member = await _context.MemberProfiles
            .Include(m => m.User)
            .Include(m => m.MembershipStatus)
            .FirstOrDefaultAsync(m => m.Id == request.MemberProfileId, cancellationToken)
            ?? throw new NotFoundException("Member not found.");

        MemberEligibility.EnsureCanBorrowAndReserve(member);

        var copy = await _context.BookCopies
            .Include(c => c.Book)
            .Include(c => c.Loans).ThenInclude(l => l.LoanStatus)
            .Include(c => c.Reservations).ThenInclude(r => r.ReservationStatus)
            .FirstOrDefaultAsync(c => c.Id == request.BookCopyId, cancellationToken)
            ?? throw new NotFoundException("Book copy not found.");

        if (!BookCopyAvailability.IsRentableOnDate(copy, DateTime.UtcNow.Date))
        {
            throw new BusinessException("Book copy is not available.");
        }

        await EnsureNoActiveLoanOverlapAsync(copy.Id, cancellationToken);

        var fromDate = DateTime.UtcNow.Date;
        var toDate = request.DueDate.ToUniversalTime().Date;
        await EnsureNoActiveReservationOverlapAsync(copy.Id, fromDate, toDate, cancellationToken);

        var pendingStatus = await _context.LoanStatuses
            .FirstAsync(s => s.Name == LoanStatusNames.Pending, cancellationToken);

        var loan = new Loan
        {
            MemberProfileId = member.Id,
            BookCopyId = copy.Id,
            LoanStatusId = pendingStatus.Id,
            BorrowedAt = DateTime.UtcNow,
            DueDate = request.DueDate.ToUniversalTime(),
            Notes = request.Notes?.Trim()
        };

        _context.Loans.Add(loan);
        await _context.SaveChangesAsync(cancellationToken);
        await _activityLog.LogAsync("Loan Created", "Loan", loan.Id, $"Loan created for '{copy.Book.Title}'.", cancellationToken: cancellationToken);

        await _notifications.SendAsync(
            member.UserId,
            "Loan request created",
            $"A loan request for '{copy.Book.Title}' has been created.",
            cancellationToken: cancellationToken);

        return await GetByIdAsync(loan.Id, cancellationToken);
    }

    public async Task<LoanDto> ConfirmAsync(int id, CancellationToken cancellationToken = default)
    {
        var loan = await LoadLoanForUpdateAsync(id, cancellationToken);
        var currentStatus = loan.LoanStatus.Name;
        LoanStateMachine.ValidateTransition(currentStatus, LoanStatusNames.Confirmed);

        await EnsureNoActiveLoanOverlapAsync(loan.BookCopyId, loan.Id, cancellationToken);
        await EnsureNoActiveReservationOverlapAsync(loan.BookCopyId, loan.BorrowedAt.Date, loan.DueDate.Date, cancellationToken);

        var confirmedStatus = await _context.LoanStatuses
            .FirstAsync(s => s.Name == LoanStatusNames.Confirmed, cancellationToken);

        loan.LoanStatusId = confirmedStatus.Id;
        loan.ApprovedByUserId = _currentUser.UserId;
        loan.ApprovedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);
        await NotifyStatusChangeAsync(loan, "confirmed", cancellationToken);
        await _activityLog.LogAsync("Loan Created", "Loan", loan.Id, $"Loan #{loan.Id} was confirmed.", cancellationToken: cancellationToken);

        return MapLoan(loan);
    }

    public async Task<LoanDto> CompleteAsync(int id, CancellationToken cancellationToken = default)
    {
        return await ReturnLoanAsync(id, LoanStatusNames.Completed, cancellationToken);
    }

    public Task<LoanDto> ReturnAsync(int id, CancellationToken cancellationToken = default) =>
        ReturnLoanAsync(id, LoanStatusNames.Completed, cancellationToken);

    public async Task<LoanDto> CancelAsync(int id, CancelLoanRequest request, CancellationToken cancellationToken = default)
    {
        var loan = await LoadLoanForUpdateAsync(id, cancellationToken);
        LoanStateMachine.ValidateTransition(loan.LoanStatus.Name, LoanStatusNames.Cancelled);

        var cancelledStatus = await _context.LoanStatuses
            .FirstAsync(s => s.Name == LoanStatusNames.Cancelled, cancellationToken);

        loan.LoanStatusId = cancelledStatus.Id;
        loan.RejectionReason = request.Reason?.Trim();

        await _context.SaveChangesAsync(cancellationToken);
        await NotifyStatusChangeAsync(loan, "cancelled", cancellationToken);
        await _activityLog.LogAsync("Loan Created", "Loan", loan.Id, $"Loan #{loan.Id} was cancelled.", cancellationToken: cancellationToken);

        return MapLoan(loan);
    }

    private async Task<LoanDto> ReturnLoanAsync(int id, string targetStatus, CancellationToken cancellationToken)
    {
        var loan = await LoadLoanForUpdateAsync(id, cancellationToken);
        var currentStatus = loan.LoanStatus.Name;

        if (currentStatus == LoanStatusNames.Overdue)
        {
            LoanStateMachine.ValidateTransition(currentStatus, targetStatus);
        }
        else
        {
            LoanStateMachine.ValidateTransition(currentStatus, targetStatus);
        }

        var completedStatus = await _context.LoanStatuses
            .FirstAsync(s => s.Name == targetStatus, cancellationToken);

        loan.LoanStatusId = completedStatus.Id;
        loan.ReturnedAt = DateTime.UtcNow;

        await _context.SaveChangesAsync(cancellationToken);
        await NotifyStatusChangeAsync(loan, "returned", cancellationToken);
        await _activityLog.LogAsync("Loan Returned", "Loan", loan.Id, $"Loan #{loan.Id} was returned.", cancellationToken: cancellationToken);

        return MapLoan(loan);
    }

    private async Task<PagedResult<LoanDto>> GetLoansAsync(LoanFilterQuery query, int? memberProfileId, CancellationToken cancellationToken)
    {
        var loans = BuildLoanQuery();

        if (memberProfileId.HasValue)
        {
            loans = loans.Where(l => l.MemberProfileId == memberProfileId.Value);
        }

        if (!string.IsNullOrWhiteSpace(query.Status))
        {
            loans = loans.Where(l => l.LoanStatus.Name == query.Status);
        }

        if (query.OverdueOnly)
        {
            var now = DateTime.UtcNow;
            loans = loans.Where(l =>
                l.ReturnedAt == null &&
                (l.LoanStatus.Name == LoanStatusNames.Overdue ||
                 (l.LoanStatus.Name == LoanStatusNames.Confirmed && l.DueDate < now)));
        }

        if (query.MemberProfileId.HasValue)
        {
            loans = loans.Where(l => l.MemberProfileId == query.MemberProfileId.Value);
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            loans = loans.Where(l =>
                l.BookCopy.Book.Title.ToLower().Contains(search) ||
                l.BookCopy.InventoryCode.ToLower().Contains(search) ||
                l.MemberProfile.MemberCardNumber.ToLower().Contains(search) ||
                l.MemberProfile.User.FirstName.ToLower().Contains(search) ||
                l.MemberProfile.User.LastName.ToLower().Contains(search));
        }

        var projected = loans
            .OrderByDescending(l => l.BorrowedAt)
            .Select(l => new LoanDto
            {
                Id = l.Id,
                MemberProfileId = l.MemberProfileId,
                MemberName = l.MemberProfile.User.FirstName + " " + l.MemberProfile.User.LastName,
                MemberCardNumber = l.MemberProfile.MemberCardNumber,
                BookCopyId = l.BookCopyId,
                InventoryCode = l.BookCopy.InventoryCode,
                BookId = l.BookCopy.BookId,
                BookTitle = l.BookCopy.Book.Title,
                CoverImagePath = l.BookCopy.Book.CoverImagePath,
                Status = l.LoanStatus.Name,
                BorrowedAt = l.BorrowedAt,
                DueDate = l.DueDate,
                ReturnedAt = l.ReturnedAt,
                ApprovedByName = l.ApprovedByUser != null ? l.ApprovedByUser.FirstName + " " + l.ApprovedByUser.LastName : null,
                ApprovedAt = l.ApprovedAt,
                RejectionReason = l.RejectionReason,
                Notes = l.Notes
            });

        return await projected.ToPagedResultAsync(query, cancellationToken);
    }

    private IQueryable<Loan> BuildLoanQuery() =>
        _context.Loans.AsNoTracking()
            .Include(l => l.MemberProfile).ThenInclude(m => m.User)
            .Include(l => l.BookCopy).ThenInclude(c => c.Book)
            .Include(l => l.LoanStatus)
            .Include(l => l.ApprovedByUser);

    private async Task<Loan> LoadLoanForUpdateAsync(int id, CancellationToken cancellationToken)
    {
        return await _context.Loans
            .Include(l => l.MemberProfile).ThenInclude(m => m.User)
            .Include(l => l.BookCopy).ThenInclude(c => c.Book)
            .Include(l => l.LoanStatus)
            .Include(l => l.ApprovedByUser)
            .FirstOrDefaultAsync(l => l.Id == id, cancellationToken)
            ?? throw new NotFoundException("Loan not found.");
    }

    private async Task EnsureAccessAsync(Loan loan, CancellationToken cancellationToken)
    {
        if (_currentUser.IsInRole(RoleNames.Admin))
        {
            return;
        }

        var userId = _currentUser.UserId
            ?? throw new UnauthorizedAppException("User is not authenticated.");

        var isOwner = await _context.MemberProfiles
            .AnyAsync(m => m.Id == loan.MemberProfileId && m.UserId == userId, cancellationToken);

        if (!isOwner)
        {
            throw new UnauthorizedAppException("You do not have access to this loan.");
        }
    }

    private async Task EnsureNoActiveLoanOverlapAsync(int bookCopyId, CancellationToken cancellationToken) =>
        await EnsureNoActiveLoanOverlapAsync(bookCopyId, null, cancellationToken);

    private async Task EnsureNoActiveLoanOverlapAsync(int bookCopyId, int? excludeLoanId, CancellationToken cancellationToken)
    {
        var activeStatuses = new[] { LoanStatusNames.Pending, LoanStatusNames.Confirmed, LoanStatusNames.Overdue };
        var hasOverlap = await _context.Loans
            .Include(l => l.LoanStatus)
            .AnyAsync(l =>
                l.BookCopyId == bookCopyId &&
                activeStatuses.Contains(l.LoanStatus.Name) &&
                (!excludeLoanId.HasValue || l.Id != excludeLoanId.Value), cancellationToken);

        if (hasOverlap)
        {
            throw new BusinessException("Book copy already has an active loan.");
        }
    }

    private async Task EnsureNoActiveReservationOverlapAsync(int bookCopyId, DateTime fromDate, DateTime toDate, CancellationToken cancellationToken)
    {
        var activeStatuses = new[] { ReservationStatusNames.Pending, ReservationStatusNames.Confirmed };
        var hasOverlap = await _context.Reservations
            .Include(r => r.ReservationStatus)
            .AnyAsync(r =>
                r.BookCopyId == bookCopyId &&
                activeStatuses.Contains(r.ReservationStatus.Name) &&
                r.FromDate <= toDate &&
                r.ToDate >= fromDate, cancellationToken);

        if (hasOverlap)
        {
            throw new BusinessException("Book copy has an overlapping active reservation");
        }
    }

    private async Task NotifyStatusChangeAsync(Loan loan, string action, CancellationToken cancellationToken)
    {
        var title = $"Loan {action}";
        var message = $"Your loan for '{loan.BookCopy.Book.Title}' has been {action}.";
        await _notifications.SendAsync(
            loan.MemberProfile.UserId,
            title,
            message,
            sendEmail: true,
            email: loan.MemberProfile.User.Email,
            cancellationToken: cancellationToken);
    }

    private static LoanDto MapLoan(Loan l) => new()
    {
        Id = l.Id,
        MemberProfileId = l.MemberProfileId,
        MemberName = $"{l.MemberProfile.User.FirstName} {l.MemberProfile.User.LastName}",
        MemberCardNumber = l.MemberProfile.MemberCardNumber,
        BookCopyId = l.BookCopyId,
        InventoryCode = l.BookCopy.InventoryCode,
        BookId = l.BookCopy.BookId,
        BookTitle = l.BookCopy.Book.Title,
        CoverImagePath = l.BookCopy.Book.CoverImagePath,
        Status = l.LoanStatus.Name,
        BorrowedAt = l.BorrowedAt,
        DueDate = l.DueDate,
        ReturnedAt = l.ReturnedAt,
        ApprovedByName = l.ApprovedByUser != null ? $"{l.ApprovedByUser.FirstName} {l.ApprovedByUser.LastName}" : null,
        ApprovedAt = l.ApprovedAt,
        RejectionReason = l.RejectionReason,
        Notes = l.Notes
    };

}
