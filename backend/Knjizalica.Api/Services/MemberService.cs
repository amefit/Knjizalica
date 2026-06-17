using System.Security.Cryptography;
using Knjizalica.Api.Common;
using Knjizalica.Api.Data;
using Knjizalica.Api.Data.Entities;
using Knjizalica.Api.DTOs.Members;
using Knjizalica.Shared.Constants;
using Knjizalica.Shared.Exceptions;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Knjizalica.Api.Services;

public interface IMemberService
{
    Task<PagedResult<MemberDto>> GetAllAsync(MemberFilterQuery query, CancellationToken cancellationToken = default);
    Task<MemberDto> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<MemberDto> CreateAsync(CreateMemberRequest request, CancellationToken cancellationToken = default);
    Task<MemberDto> UpdateAsync(int id, UpdateMemberRequest request, CancellationToken cancellationToken = default);
    Task DeleteAsync(int id, CancellationToken cancellationToken = default);
    Task BlockAsync(int id, CancellationToken cancellationToken = default);
    Task UnblockAsync(int id, CancellationToken cancellationToken = default);
    Task<MemberProfileDto> GetMyProfileAsync(CancellationToken cancellationToken = default);
    Task<MemberProfileDto> UpdateMyProfileAsync(UpdateProfileRequest request, CancellationToken cancellationToken = default);
}

public sealed class MemberService : IMemberService
{
    private readonly ApplicationDbContext _context;
    private readonly UserManager<ApplicationUser> _userManager;
    private readonly ICurrentUserService _currentUser;
    private readonly IActivityLogService _activityLog;

    public MemberService(
        ApplicationDbContext context,
        UserManager<ApplicationUser> userManager,
        ICurrentUserService currentUser,
        IActivityLogService activityLog)
    {
        _context = context;
        _userManager = userManager;
        _currentUser = currentUser;
        _activityLog = activityLog;
    }

    public async Task<PagedResult<MemberDto>> GetAllAsync(MemberFilterQuery query, CancellationToken cancellationToken = default)
    {
        var members = _context.MemberProfiles.AsNoTracking()
            .Include(m => m.User)
            .Include(m => m.MembershipStatus)
            .Include(m => m.City)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(query.Tab))
        {
            var tab = query.Tab.Trim().ToLower();
            if (tab == "active")
            {
                members = members.Where(m => m.MembershipStatus.Name == MembershipStatusNames.Active);
            }
            else if (tab == "blocked")
            {
                members = members.Where(m => m.MembershipStatus.Name == MembershipStatusNames.Blocked);
            }
        }

        if (!string.IsNullOrWhiteSpace(query.Search))
        {
            var search = query.Search.Trim().ToLower();
            members = members.Where(m =>
                m.MemberCardNumber.ToLower().Contains(search) ||
                m.User.FirstName.ToLower().Contains(search) ||
                m.User.LastName.ToLower().Contains(search) ||
                (m.User.Email != null && m.User.Email.ToLower().Contains(search)) ||
                (m.User.UserName != null && m.User.UserName.ToLower().Contains(search)));
        }

        var projected = members
            .OrderByDescending(m => m.RegistrationDate)
            .Select(m => new MemberDto
            {
                Id = m.Id,
                UserId = m.UserId,
                Username = m.User.UserName ?? string.Empty,
                Email = m.User.Email ?? string.Empty,
                FirstName = m.User.FirstName,
                LastName = m.User.LastName,
                PhoneNumber = m.User.PhoneNumber,
                MemberCardNumber = m.MemberCardNumber,
                MembershipStatus = m.MembershipStatus.Name,
                CityId = m.CityId,
                CityName = m.City.Name,
                ProfileImagePath = m.ProfileImagePath,
                RegistrationDate = m.RegistrationDate,
                ExpiryDate = m.ExpiryDate,
                IsActive = m.User.IsActive
            });

        return await projected.ToPagedResultAsync(query, cancellationToken);
    }

    public async Task<MemberDto> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var member = await _context.MemberProfiles.AsNoTracking()
            .Include(m => m.User)
            .Include(m => m.MembershipStatus)
            .Include(m => m.City)
            .FirstOrDefaultAsync(m => m.Id == id, cancellationToken)
            ?? throw new NotFoundException("Member not found.");

        return MapMember(member);
    }

    public async Task<MemberDto> CreateAsync(CreateMemberRequest request, CancellationToken cancellationToken = default)
    {
        if (!await _context.Cities.AnyAsync(c => c.Id == request.CityId, cancellationToken))
        {
            throw new ValidationAppException("City does not exist.");
        }

        if (await _userManager.FindByNameAsync(request.Username) != null)
        {
            throw new BusinessException("Username is already taken.");
        }

        if (await _userManager.FindByEmailAsync(request.Email) != null)
        {
            throw new BusinessException("Email is already registered.");
        }

        var activeStatus = await _context.MembershipStatuses
            .FirstAsync(s => s.Name == MembershipStatusNames.Active, cancellationToken);

        await using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            var user = new ApplicationUser
            {
                UserName = request.Username,
                Email = request.Email,
                FirstName = request.FirstName.Trim(),
                LastName = request.LastName.Trim(),
                PhoneNumber = request.PhoneNumber,
                EmailConfirmed = true
            };

            var createResult = await _userManager.CreateAsync(user, request.Password);
            if (!createResult.Succeeded)
            {
                throw new ValidationAppException(string.Join(" ", createResult.Errors.Select(e => e.Description)));
            }

            await _userManager.AddToRoleAsync(user, RoleNames.User);

            var profile = new MemberProfile
            {
                UserId = user.Id,
                MemberCardNumber = await GenerateMemberCardNumberAsync(cancellationToken),
                MembershipStatusId = activeStatus.Id,
                CityId = request.CityId,
                RegistrationDate = DateTime.UtcNow,
                ExpiryDate = request.ExpiryDate ?? DateTime.UtcNow.AddYears(1)
            };

            _context.MemberProfiles.Add(profile);
            await _context.SaveChangesAsync(cancellationToken);
            await _activityLog.LogAsync("Member Created", "MemberProfile", profile.Id, $"Member '{user.FirstName} {user.LastName}' was created.", cancellationToken: cancellationToken);

            await transaction.CommitAsync(cancellationToken);
            return await GetByIdAsync(profile.Id, cancellationToken);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    public async Task<MemberDto> UpdateAsync(int id, UpdateMemberRequest request, CancellationToken cancellationToken = default)
    {
        var profile = await _context.MemberProfiles
            .Include(m => m.User)
            .FirstOrDefaultAsync(m => m.Id == id, cancellationToken)
            ?? throw new NotFoundException("Member not found.");

        if (!await _context.Cities.AnyAsync(c => c.Id == request.CityId, cancellationToken))
        {
            throw new ValidationAppException("City does not exist.");
        }

        var existingEmail = await _userManager.FindByEmailAsync(request.Email);
        if (existingEmail != null && existingEmail.Id != profile.UserId)
        {
            throw new BusinessException("Email is already registered.");
        }

        await using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            profile.User.FirstName = request.FirstName.Trim();
            profile.User.LastName = request.LastName.Trim();
            profile.User.Email = request.Email;
            profile.User.PhoneNumber = request.PhoneNumber;
            profile.CityId = request.CityId;
            if (request.ExpiryDate.HasValue)
            {
                profile.ExpiryDate = request.ExpiryDate.Value;
            }

            await _userManager.UpdateAsync(profile.User);
            await _context.SaveChangesAsync(cancellationToken);

            await transaction.CommitAsync(cancellationToken);
            return await GetByIdAsync(id, cancellationToken);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    public async Task DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var profile = await _context.MemberProfiles
            .Include(m => m.User)
            .FirstOrDefaultAsync(m => m.Id == id, cancellationToken)
            ?? throw new NotFoundException("Member not found.");

        var activeLoanStatuses = new[] { LoanStatusNames.Pending, LoanStatusNames.Confirmed, LoanStatusNames.Overdue };
        var activeReservationStatuses = new[] { ReservationStatusNames.Pending, ReservationStatusNames.Confirmed };

        if (await _context.Loans
                .Include(l => l.LoanStatus)
                .AnyAsync(l => l.MemberProfileId == id && activeLoanStatuses.Contains(l.LoanStatus.Name), cancellationToken))
        {
            throw new BusinessException("Cannot delete member with active loans.");
        }

        if (await _context.Reservations
                .Include(r => r.ReservationStatus)
                .AnyAsync(r => r.MemberProfileId == id && activeReservationStatuses.Contains(r.ReservationStatus.Name), cancellationToken))
        {
            throw new BusinessException("Cannot delete member with active reservations.");
        }

        if (await _context.Loans.AnyAsync(l => l.MemberProfileId == id, cancellationToken))
        {
            throw new BusinessException("Cannot delete member with existing loans.");
        }

        if (await _context.Reservations.AnyAsync(r => r.MemberProfileId == id, cancellationToken))
        {
            throw new BusinessException("Cannot delete member with existing reservations.");
        }

        await using var transaction = await _context.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            _context.MemberProfiles.Remove(profile);
            await _context.SaveChangesAsync(cancellationToken);
            await _userManager.DeleteAsync(profile.User);

            await transaction.CommitAsync(cancellationToken);
        }
        catch
        {
            await transaction.RollbackAsync(cancellationToken);
            throw;
        }
    }

    public async Task BlockAsync(int id, CancellationToken cancellationToken = default)
    {
        var profile = await _context.MemberProfiles
            .Include(m => m.User)
            .Include(m => m.MembershipStatus)
            .FirstOrDefaultAsync(m => m.Id == id, cancellationToken)
            ?? throw new NotFoundException("Member not found.");

        var blockedStatus = await _context.MembershipStatuses
            .FirstAsync(s => s.Name == MembershipStatusNames.Blocked, cancellationToken);

        profile.MembershipStatusId = blockedStatus.Id;
        profile.User.IsActive = false;
        await _context.SaveChangesAsync(cancellationToken);
        await _activityLog.LogAsync("Member Blocked", "MemberProfile", profile.Id, $"Member '{profile.User.FirstName} {profile.User.LastName}' was blocked.", cancellationToken: cancellationToken);
    }

    public async Task UnblockAsync(int id, CancellationToken cancellationToken = default)
    {
        var profile = await _context.MemberProfiles
            .Include(m => m.User)
            .FirstOrDefaultAsync(m => m.Id == id, cancellationToken)
            ?? throw new NotFoundException("Member not found.");

        var activeStatus = await _context.MembershipStatuses
            .FirstAsync(s => s.Name == MembershipStatusNames.Active, cancellationToken);

        profile.MembershipStatusId = activeStatus.Id;
        profile.User.IsActive = true;
        await _context.SaveChangesAsync(cancellationToken);
        await _activityLog.LogAsync("Member Unblocked", "MemberProfile", profile.Id, $"Member '{profile.User.FirstName} {profile.User.LastName}' was unblocked.", cancellationToken: cancellationToken);
    }

    public async Task<MemberProfileDto> GetMyProfileAsync(CancellationToken cancellationToken = default)
    {
        var userId = _currentUser.UserId
            ?? throw new UnauthorizedAppException("User is not authenticated.");

        var profile = await _context.MemberProfiles.AsNoTracking()
            .Include(m => m.User)
            .Include(m => m.MembershipStatus)
            .Include(m => m.City)
            .FirstOrDefaultAsync(m => m.UserId == userId, cancellationToken)
            ?? throw new NotFoundException("Member profile not found.");

        return MapProfile(profile);
    }

    public async Task<MemberProfileDto> UpdateMyProfileAsync(UpdateProfileRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUser.UserId
            ?? throw new UnauthorizedAppException("User is not authenticated.");

        var profile = await _context.MemberProfiles
            .Include(m => m.User)
            .Include(m => m.MembershipStatus)
            .Include(m => m.City)
            .FirstOrDefaultAsync(m => m.UserId == userId, cancellationToken)
            ?? throw new NotFoundException("Member profile not found.");

        if (!await _context.Cities.AnyAsync(c => c.Id == request.CityId, cancellationToken))
        {
            throw new ValidationAppException("City does not exist.");
        }

        profile.User.FirstName = request.FirstName.Trim();
        profile.User.LastName = request.LastName.Trim();
        profile.User.PhoneNumber = request.PhoneNumber;
        profile.CityId = request.CityId;
        profile.ProfileImagePath = request.ProfileImagePath;

        await _userManager.UpdateAsync(profile.User);
        await _context.SaveChangesAsync(cancellationToken);

        return MapProfile(profile);
    }

    private static MemberDto MapMember(MemberProfile m) => new()
    {
        Id = m.Id,
        UserId = m.UserId,
        Username = m.User.UserName ?? string.Empty,
        Email = m.User.Email ?? string.Empty,
        FirstName = m.User.FirstName,
        LastName = m.User.LastName,
        PhoneNumber = m.User.PhoneNumber,
        MemberCardNumber = m.MemberCardNumber,
        MembershipStatus = m.MembershipStatus.Name,
        CityId = m.CityId,
        CityName = m.City.Name,
        ProfileImagePath = m.ProfileImagePath,
        RegistrationDate = m.RegistrationDate,
        ExpiryDate = m.ExpiryDate,
        IsActive = m.User.IsActive
    };

    private static MemberProfileDto MapProfile(MemberProfile m) => new()
    {
        Id = m.Id,
        Username = m.User.UserName ?? string.Empty,
        Email = m.User.Email ?? string.Empty,
        FirstName = m.User.FirstName,
        LastName = m.User.LastName,
        PhoneNumber = m.User.PhoneNumber,
        MemberCardNumber = m.MemberCardNumber,
        MembershipStatus = m.MembershipStatus.Name,
        CityId = m.CityId,
        CityName = m.City.Name,
        ProfileImagePath = m.ProfileImagePath,
        RegistrationDate = m.RegistrationDate,
        ExpiryDate = m.ExpiryDate
    };

    private async Task<string> GenerateMemberCardNumberAsync(CancellationToken cancellationToken)
    {
        string cardNumber;
        do
        {
            var suffix = RandomNumberGenerator.GetInt32(100000, 999999);
            cardNumber = $"K-{suffix}";
        }
        while (await _context.MemberProfiles.AnyAsync(m => m.MemberCardNumber == cardNumber, cancellationToken));

        return cardNumber;
    }
}
