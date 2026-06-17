using Knjizalica.Api.Data;
using Knjizalica.Api.Data.Entities;
using Knjizalica.Api.DTOs.ReferenceData;
using Knjizalica.Api.Common;
using Knjizalica.Shared.Exceptions;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace Knjizalica.Api.Services;

public interface IReferenceDataService
{
    Task<IReadOnlyList<CountryDto>> GetCountriesAsync(CancellationToken cancellationToken = default);
    Task<CountryDto> CreateCountryAsync(CreateCountryRequest request, CancellationToken cancellationToken = default);
    Task<CountryDto> UpdateCountryAsync(int id, UpdateCountryRequest request, CancellationToken cancellationToken = default);
    Task DeleteCountryAsync(int id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<CityDto>> GetCitiesAsync(int? countryId = null, CancellationToken cancellationToken = default);
    Task<CityDto> CreateCityAsync(CreateCityRequest request, CancellationToken cancellationToken = default);
    Task<CityDto> UpdateCityAsync(int id, UpdateCityRequest request, CancellationToken cancellationToken = default);
    Task DeleteCityAsync(int id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<LookupDto>> GetGenresAsync(CancellationToken cancellationToken = default);
    Task<LookupDto> CreateGenreAsync(CreateLookupRequest request, CancellationToken cancellationToken = default);
    Task<LookupDto> UpdateGenreAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default);
    Task DeleteGenreAsync(int id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<LookupDto>> GetBookCategoriesAsync(CancellationToken cancellationToken = default);
    Task<LookupDto> CreateBookCategoryAsync(CreateLookupRequest request, CancellationToken cancellationToken = default);
    Task<LookupDto> UpdateBookCategoryAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default);
    Task DeleteBookCategoryAsync(int id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<LookupDto>> GetLanguagesAsync(CancellationToken cancellationToken = default);
    Task<LookupDto> CreateLanguageAsync(CreateLookupRequest request, CancellationToken cancellationToken = default);
    Task<LookupDto> UpdateLanguageAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default);
    Task DeleteLanguageAsync(int id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<LookupDto>> GetPublishersAsync(CancellationToken cancellationToken = default);
    Task<LookupDto> CreatePublisherAsync(CreateLookupRequest request, CancellationToken cancellationToken = default);
    Task<LookupDto> UpdatePublisherAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default);
    Task DeletePublisherAsync(int id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<LookupDto>> GetMembershipStatusesAsync(CancellationToken cancellationToken = default);
    Task<LookupDto> CreateMembershipStatusAsync(CreateLookupRequest request, CancellationToken cancellationToken = default);
    Task<LookupDto> UpdateMembershipStatusAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default);
    Task DeleteMembershipStatusAsync(int id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<LookupDto>> GetLoanStatusesAsync(CancellationToken cancellationToken = default);
    Task<LookupDto> CreateLoanStatusAsync(CreateLookupRequest request, CancellationToken cancellationToken = default);
    Task<LookupDto> UpdateLoanStatusAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default);
    Task DeleteLoanStatusAsync(int id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<LookupDto>> GetReservationStatusesAsync(CancellationToken cancellationToken = default);
    Task<LookupDto> CreateReservationStatusAsync(CreateLookupRequest request, CancellationToken cancellationToken = default);
    Task<LookupDto> UpdateReservationStatusAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default);
    Task DeleteReservationStatusAsync(int id, CancellationToken cancellationToken = default);

    Task<IReadOnlyList<LookupDto>> GetActivityTypesAsync(CancellationToken cancellationToken = default);
    Task<LookupDto> CreateActivityTypeAsync(CreateLookupRequest request, CancellationToken cancellationToken = default);
    Task<LookupDto> UpdateActivityTypeAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default);
    Task DeleteActivityTypeAsync(int id, CancellationToken cancellationToken = default);
}

public sealed class ReferenceDataService : IReferenceDataService
{
    private const string CacheKeyPrefix = "refdata:";
    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(30);

    private readonly ApplicationDbContext _context;
    private readonly IMemoryCache _cache;

    public ReferenceDataService(ApplicationDbContext context, IMemoryCache cache)
    {
        _context = context;
        _cache = cache;
    }

    public async Task<IReadOnlyList<CountryDto>> GetCountriesAsync(CancellationToken cancellationToken = default) =>
        await _cache.GetOrCreateAsync($"{CacheKeyPrefix}countries", async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = CacheDuration;
            return await _context.Countries.AsNoTracking()
                .OrderBy(c => c.Name)
                .Select(c => new CountryDto { Id = c.Id, Name = c.Name })
                .ToListAsync(cancellationToken);
        }) ?? [];

    public async Task<CountryDto> CreateCountryAsync(CreateCountryRequest request, CancellationToken cancellationToken = default)
    {
        var name = request.Name.Trim();
        if (await _context.Countries.AnyAsync(c => c.Name.ToLower() == name.ToLower(), cancellationToken))
        {
            throw new BusinessException("Country with this name already exists.");
        }

        var entity = new Country { Name = name };
        _context.Countries.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("countries");
        return new CountryDto { Id = entity.Id, Name = entity.Name };
    }

    public async Task<CountryDto> UpdateCountryAsync(int id, UpdateCountryRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _context.Countries.FindAsync([id], cancellationToken)
            ?? throw new NotFoundException("Country not found.");

        var name = request.Name.Trim();
        if (await _context.Countries.AnyAsync(c => c.Name.ToLower() == name.ToLower() && c.Id != id, cancellationToken))
        {
            throw new BusinessException("Country with this name already exists.");
        }

        entity.Name = name;
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("countries", "cities");
        return new CountryDto { Id = entity.Id, Name = entity.Name };
    }

    public async Task DeleteCountryAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _context.Countries.FindAsync([id], cancellationToken)
            ?? throw new NotFoundException("Country not found.");
        if (await _context.Cities.AnyAsync(c => c.CountryId == id, cancellationToken))
        {
            throw new BusinessException("Cannot delete country with existing cities.");
        }
        _context.Countries.Remove(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("countries");
    }

    public async Task<IReadOnlyList<CityDto>> GetCitiesAsync(int? countryId = null, CancellationToken cancellationToken = default)
    {
        var cacheKey = countryId.HasValue ? $"{CacheKeyPrefix}cities-{countryId}" : $"{CacheKeyPrefix}cities-all";
        return await _cache.GetOrCreateAsync(cacheKey, async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = CacheDuration;
            var query = _context.Cities.AsNoTracking().Include(c => c.Country).AsQueryable();
            if (countryId.HasValue)
            {
                query = query.Where(c => c.CountryId == countryId.Value);
            }
            return await query.OrderBy(c => c.Name)
                .Select(c => new CityDto
                {
                    Id = c.Id,
                    Name = c.Name,
                    CountryId = c.CountryId,
                    CountryName = c.Country.Name
                })
                .ToListAsync(cancellationToken);
        }) ?? [];
    }

    public async Task<CityDto> CreateCityAsync(CreateCityRequest request, CancellationToken cancellationToken = default)
    {
        await EnsureCountryExistsAsync(request.CountryId, cancellationToken);
        var name = request.Name.Trim();
        if (await _context.Cities.AnyAsync(c => c.Name.ToLower() == name.ToLower() && c.CountryId == request.CountryId, cancellationToken))
        {
            throw new BusinessException("City with this name already exists in the selected country.");
        }

        var entity = new City { Name = name, CountryId = request.CountryId };
        _context.Cities.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("cities");
        var country = await _context.Countries.AsNoTracking().FirstAsync(c => c.Id == request.CountryId, cancellationToken);
        return new CityDto { Id = entity.Id, Name = entity.Name, CountryId = entity.CountryId, CountryName = country.Name };
    }

    public async Task<CityDto> UpdateCityAsync(int id, UpdateCityRequest request, CancellationToken cancellationToken = default)
    {
        await EnsureCountryExistsAsync(request.CountryId, cancellationToken);
        var entity = await _context.Cities.FindAsync([id], cancellationToken)
            ?? throw new NotFoundException("City not found.");

        var name = request.Name.Trim();
        if (await _context.Cities.AnyAsync(c => c.Name.ToLower() == name.ToLower() && c.CountryId == request.CountryId && c.Id != id, cancellationToken))
        {
            throw new BusinessException("City with this name already exists in the selected country.");
        }

        entity.Name = name;
        entity.CountryId = request.CountryId;
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("cities");
        var country = await _context.Countries.AsNoTracking().FirstAsync(c => c.Id == request.CountryId, cancellationToken);
        return new CityDto { Id = entity.Id, Name = entity.Name, CountryId = entity.CountryId, CountryName = country.Name };
    }

    public async Task DeleteCityAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _context.Cities.FindAsync([id], cancellationToken)
            ?? throw new NotFoundException("City not found.");
        if (await _context.MemberProfiles.AnyAsync(m => m.CityId == id, cancellationToken))
        {
            throw new BusinessException("Cannot delete city with registered members.");
        }
        _context.Cities.Remove(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("cities");
    }

    public Task<IReadOnlyList<LookupDto>> GetGenresAsync(CancellationToken cancellationToken = default) =>
        GetLookupAsync("genres", cancellationToken);

    public Task<LookupDto> CreateGenreAsync(CreateLookupRequest request, CancellationToken cancellationToken = default) =>
        CreateGenreInternalAsync(request, cancellationToken);

    public Task<LookupDto> UpdateGenreAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default) =>
        UpdateLookupAsync("genres", id, request, cancellationToken);

    public Task DeleteGenreAsync(int id, CancellationToken cancellationToken = default) =>
        DeleteLookupAsync("genres", id, b => b.GenreId, "genre", cancellationToken);

    public Task<IReadOnlyList<LookupDto>> GetBookCategoriesAsync(CancellationToken cancellationToken = default) =>
        GetLookupAsync("categories", cancellationToken);

    public Task<LookupDto> CreateBookCategoryAsync(CreateLookupRequest request, CancellationToken cancellationToken = default) =>
        CreateBookCategoryInternalAsync(request, cancellationToken);

    public Task<LookupDto> UpdateBookCategoryAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default) =>
        UpdateLookupAsync("categories", id, request, cancellationToken);

    public Task DeleteBookCategoryAsync(int id, CancellationToken cancellationToken = default) =>
        DeleteLookupAsync("categories", id, b => b.BookCategoryId, "category", cancellationToken);

    public Task<IReadOnlyList<LookupDto>> GetLanguagesAsync(CancellationToken cancellationToken = default) =>
        GetLookupAsync("languages", cancellationToken);

    public Task<LookupDto> CreateLanguageAsync(CreateLookupRequest request, CancellationToken cancellationToken = default) =>
        CreateLanguageInternalAsync(request, cancellationToken);

    public Task<LookupDto> UpdateLanguageAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default) =>
        UpdateLookupAsync("languages", id, request, cancellationToken);

    public Task DeleteLanguageAsync(int id, CancellationToken cancellationToken = default) =>
        DeleteLookupAsync("languages", id, b => b.LanguageId, "language", cancellationToken);

    public Task<IReadOnlyList<LookupDto>> GetPublishersAsync(CancellationToken cancellationToken = default) =>
        GetLookupAsync("publishers", cancellationToken);

    public Task<LookupDto> CreatePublisherAsync(CreateLookupRequest request, CancellationToken cancellationToken = default) =>
        CreatePublisherInternalAsync(request, cancellationToken);

    public Task<LookupDto> UpdatePublisherAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default) =>
        UpdateLookupAsync("publishers", id, request, cancellationToken);

    public Task DeletePublisherAsync(int id, CancellationToken cancellationToken = default) =>
        DeleteLookupAsync("publishers", id, b => b.PublisherId, "publisher", cancellationToken);

    public Task<IReadOnlyList<LookupDto>> GetMembershipStatusesAsync(CancellationToken cancellationToken = default) =>
        GetLookupAsync("membership-statuses", cancellationToken);

    public Task<LookupDto> CreateMembershipStatusAsync(CreateLookupRequest request, CancellationToken cancellationToken = default) =>
        CreateMembershipStatusInternalAsync(request, cancellationToken);

    public Task<LookupDto> UpdateMembershipStatusAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default) =>
        UpdateLookupAsync("membership-statuses", id, request, cancellationToken);

    public Task DeleteMembershipStatusAsync(int id, CancellationToken cancellationToken = default) =>
        DeleteStatusLookupAsync("membership-statuses", id, "membership status", cancellationToken);

    public Task<IReadOnlyList<LookupDto>> GetLoanStatusesAsync(CancellationToken cancellationToken = default) =>
        GetLookupAsync("loan-statuses", cancellationToken);

    public Task<LookupDto> CreateLoanStatusAsync(CreateLookupRequest request, CancellationToken cancellationToken = default) =>
        CreateLoanStatusInternalAsync(request, cancellationToken);

    public Task<LookupDto> UpdateLoanStatusAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default) =>
        UpdateLookupAsync("loan-statuses", id, request, cancellationToken);

    public Task DeleteLoanStatusAsync(int id, CancellationToken cancellationToken = default) =>
        DeleteStatusLookupAsync("loan-statuses", id, "loan status", cancellationToken);

    public Task<IReadOnlyList<LookupDto>> GetReservationStatusesAsync(CancellationToken cancellationToken = default) =>
        GetLookupAsync("reservation-statuses", cancellationToken);

    public Task<LookupDto> CreateReservationStatusAsync(CreateLookupRequest request, CancellationToken cancellationToken = default) =>
        CreateReservationStatusInternalAsync(request, cancellationToken);

    public Task<LookupDto> UpdateReservationStatusAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default) =>
        UpdateLookupAsync("reservation-statuses", id, request, cancellationToken);

    public Task DeleteReservationStatusAsync(int id, CancellationToken cancellationToken = default) =>
        DeleteStatusLookupAsync("reservation-statuses", id, "reservation status", cancellationToken);

    public Task<IReadOnlyList<LookupDto>> GetActivityTypesAsync(CancellationToken cancellationToken = default) =>
        GetLookupAsync("activity-types", cancellationToken);

    public Task<LookupDto> CreateActivityTypeAsync(CreateLookupRequest request, CancellationToken cancellationToken = default) =>
        CreateActivityTypeInternalAsync(request, cancellationToken);

    public Task<LookupDto> UpdateActivityTypeAsync(int id, UpdateLookupRequest request, CancellationToken cancellationToken = default) =>
        UpdateLookupAsync("activity-types", id, request, cancellationToken);

    public Task DeleteActivityTypeAsync(int id, CancellationToken cancellationToken = default) =>
        DeleteStatusLookupAsync("activity-types", id, "activity type", cancellationToken);

    private async Task<LookupDto> CreateGenreInternalAsync(CreateLookupRequest request, CancellationToken cancellationToken)
    {
        var name = request.Name.Trim();
        if (await _context.Genres.AnyAsync(x => x.Name.ToLower() == name.ToLower(), cancellationToken))
        {
            throw new BusinessException("Genre with this name already exists.");
        }

        var entity = new Genre { Name = name };
        _context.Genres.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("genres");
        return new LookupDto { Id = entity.Id, Name = entity.Name };
    }

    private async Task<LookupDto> CreateBookCategoryInternalAsync(CreateLookupRequest request, CancellationToken cancellationToken)
    {
        var name = request.Name.Trim();
        if (await _context.BookCategories.AnyAsync(x => x.Name.ToLower() == name.ToLower(), cancellationToken))
        {
            throw new BusinessException("Book category with this name already exists.");
        }

        var entity = new BookCategory { Name = name };
        _context.BookCategories.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("categories");
        return new LookupDto { Id = entity.Id, Name = entity.Name };
    }

    private async Task<LookupDto> CreateLanguageInternalAsync(CreateLookupRequest request, CancellationToken cancellationToken)
    {
        var name = request.Name.Trim();
        if (await _context.Languages.AnyAsync(x => x.Name.ToLower() == name.ToLower(), cancellationToken))
        {
            throw new BusinessException("Language with this name already exists.");
        }

        var entity = new Language { Name = name };
        _context.Languages.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("languages");
        return new LookupDto { Id = entity.Id, Name = entity.Name };
    }

    private async Task<LookupDto> CreatePublisherInternalAsync(CreateLookupRequest request, CancellationToken cancellationToken)
    {
        var name = request.Name.Trim();
        if (await _context.Publishers.AnyAsync(x => x.Name.ToLower() == name.ToLower(), cancellationToken))
        {
            throw new BusinessException("Publisher with this name already exists.");
        }

        var entity = new Publisher { Name = name };
        _context.Publishers.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("publishers");
        return new LookupDto { Id = entity.Id, Name = entity.Name };
    }

    private async Task<LookupDto> CreateMembershipStatusInternalAsync(CreateLookupRequest request, CancellationToken cancellationToken)
    {
        var name = request.Name.Trim();
        if (await _context.MembershipStatuses.AnyAsync(x => x.Name.ToLower() == name.ToLower(), cancellationToken))
        {
            throw new BusinessException("Membership status with this name already exists.");
        }

        var entity = new MembershipStatus { Name = name };
        _context.MembershipStatuses.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("membership-statuses");
        return new LookupDto { Id = entity.Id, Name = entity.Name };
    }

    private async Task<LookupDto> CreateLoanStatusInternalAsync(CreateLookupRequest request, CancellationToken cancellationToken)
    {
        var name = request.Name.Trim();
        if (await _context.LoanStatuses.AnyAsync(x => x.Name.ToLower() == name.ToLower(), cancellationToken))
        {
            throw new BusinessException("Loan status with this name already exists.");
        }

        var entity = new LoanStatus { Name = name };
        _context.LoanStatuses.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("loan-statuses");
        return new LookupDto { Id = entity.Id, Name = entity.Name };
    }

    private async Task<LookupDto> CreateReservationStatusInternalAsync(CreateLookupRequest request, CancellationToken cancellationToken)
    {
        var name = request.Name.Trim();
        if (await _context.ReservationStatuses.AnyAsync(x => x.Name.ToLower() == name.ToLower(), cancellationToken))
        {
            throw new BusinessException("Reservation status with this name already exists.");
        }

        var entity = new ReservationStatus { Name = name };
        _context.ReservationStatuses.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("reservation-statuses");
        return new LookupDto { Id = entity.Id, Name = entity.Name };
    }

    private async Task<LookupDto> CreateActivityTypeInternalAsync(CreateLookupRequest request, CancellationToken cancellationToken)
    {
        var name = request.Name.Trim();
        if (await _context.ActivityTypes.AnyAsync(x => x.Name.ToLower() == name.ToLower(), cancellationToken))
        {
            throw new BusinessException("Activity type with this name already exists.");
        }

        var entity = new ActivityType { Name = name };
        _context.ActivityTypes.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("activity-types");
        return new LookupDto { Id = entity.Id, Name = entity.Name };
    }

    private async Task<IReadOnlyList<LookupDto>> GetLookupAsync(string cacheSuffix, CancellationToken cancellationToken)
    {
        return await _cache.GetOrCreateAsync($"{CacheKeyPrefix}{cacheSuffix}", async entry =>
        {
            entry.AbsoluteExpirationRelativeToNow = CacheDuration;
            return cacheSuffix switch
            {
                "genres" => await _context.Genres.AsNoTracking().OrderBy(x => x.Name)
                    .Select(x => new LookupDto { Id = x.Id, Name = x.Name }).ToListAsync(cancellationToken),
                "categories" => await _context.BookCategories.AsNoTracking().OrderBy(x => x.Name)
                    .Select(x => new LookupDto { Id = x.Id, Name = x.Name }).ToListAsync(cancellationToken),
                "languages" => await _context.Languages.AsNoTracking().OrderBy(x => x.Name)
                    .Select(x => new LookupDto { Id = x.Id, Name = x.Name }).ToListAsync(cancellationToken),
                "publishers" => await _context.Publishers.AsNoTracking().OrderBy(x => x.Name)
                    .Select(x => new LookupDto { Id = x.Id, Name = x.Name }).ToListAsync(cancellationToken),
                "membership-statuses" => await _context.MembershipStatuses.AsNoTracking().OrderBy(x => x.Name)
                    .Select(x => new LookupDto { Id = x.Id, Name = x.Name }).ToListAsync(cancellationToken),
                "loan-statuses" => await _context.LoanStatuses.AsNoTracking().OrderBy(x => x.Name)
                    .Select(x => new LookupDto { Id = x.Id, Name = x.Name }).ToListAsync(cancellationToken),
                "reservation-statuses" => await _context.ReservationStatuses.AsNoTracking().OrderBy(x => x.Name)
                    .Select(x => new LookupDto { Id = x.Id, Name = x.Name }).ToListAsync(cancellationToken),
                "activity-types" => await _context.ActivityTypes.AsNoTracking().OrderBy(x => x.Name)
                    .Select(x => new LookupDto { Id = x.Id, Name = x.Name }).ToListAsync(cancellationToken),
                _ => []
            };
        }) ?? [];
    }

    private async Task<LookupDto> UpdateLookupAsync(string cacheSuffix, int id, UpdateLookupRequest request, CancellationToken cancellationToken)
    {
        var name = request.Name.Trim();
        var isDuplicate = cacheSuffix switch
        {
            "genres" => await _context.Genres.AnyAsync(x => x.Name.ToLower() == name.ToLower() && x.Id != id, cancellationToken),
            "categories" => await _context.BookCategories.AnyAsync(x => x.Name.ToLower() == name.ToLower() && x.Id != id, cancellationToken),
            "languages" => await _context.Languages.AnyAsync(x => x.Name.ToLower() == name.ToLower() && x.Id != id, cancellationToken),
            "publishers" => await _context.Publishers.AnyAsync(x => x.Name.ToLower() == name.ToLower() && x.Id != id, cancellationToken),
            "membership-statuses" => await _context.MembershipStatuses.AnyAsync(x => x.Name.ToLower() == name.ToLower() && x.Id != id, cancellationToken),
            "loan-statuses" => await _context.LoanStatuses.AnyAsync(x => x.Name.ToLower() == name.ToLower() && x.Id != id, cancellationToken),
            "reservation-statuses" => await _context.ReservationStatuses.AnyAsync(x => x.Name.ToLower() == name.ToLower() && x.Id != id, cancellationToken),
            "activity-types" => await _context.ActivityTypes.AnyAsync(x => x.Name.ToLower() == name.ToLower() && x.Id != id, cancellationToken),
            _ => false
        };

        if (isDuplicate)
        {
            var label = cacheSuffix switch
            {
                "genres" => "Genre",
                "categories" => "Book category",
                "languages" => "Language",
                "publishers" => "Publisher",
                "membership-statuses" => "Membership status",
                "loan-statuses" => "Loan status",
                "reservation-statuses" => "Reservation status",
                "activity-types" => "Activity type",
                _ => "Record"
            };
            throw new BusinessException($"{label} with this name already exists.");
        }

        var entity = cacheSuffix switch
        {
            "genres" => (object?)await _context.Genres.FindAsync([id], cancellationToken),
            "categories" => await _context.BookCategories.FindAsync([id], cancellationToken),
            "languages" => await _context.Languages.FindAsync([id], cancellationToken),
            "publishers" => await _context.Publishers.FindAsync([id], cancellationToken),
            "membership-statuses" => await _context.MembershipStatuses.FindAsync([id], cancellationToken),
            "loan-statuses" => await _context.LoanStatuses.FindAsync([id], cancellationToken),
            "reservation-statuses" => await _context.ReservationStatuses.FindAsync([id], cancellationToken),
            "activity-types" => await _context.ActivityTypes.FindAsync([id], cancellationToken),
            _ => null
        } ?? throw new NotFoundException("Record not found.");

        SetName(entity, name);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache(cacheSuffix);
        return new LookupDto { Id = GetId(entity), Name = GetName(entity) };
    }

    private async Task DeleteLookupAsync(string cacheSuffix, int id, Func<Book, int> foreignKeySelector, string label, CancellationToken cancellationToken)
    {
        var entity = cacheSuffix switch
        {
            "genres" => (object?)await _context.Genres.FindAsync([id], cancellationToken),
            "categories" => await _context.BookCategories.FindAsync([id], cancellationToken),
            "languages" => await _context.Languages.FindAsync([id], cancellationToken),
            "publishers" => await _context.Publishers.FindAsync([id], cancellationToken),
            _ => null
        } ?? throw new NotFoundException("Record not found.");

        var hasBooks = cacheSuffix switch
        {
            "genres" => await _context.Books.AnyAsync(b => b.GenreId == id, cancellationToken),
            "categories" => await _context.Books.AnyAsync(b => b.BookCategoryId == id, cancellationToken),
            "languages" => await _context.Books.AnyAsync(b => b.LanguageId == id, cancellationToken),
            "publishers" => await _context.Books.AnyAsync(b => b.PublisherId == id, cancellationToken),
            _ => false
        };

        if (hasBooks)
        {
            throw new BusinessException($"Cannot delete {label} that is used by books.");
        }

        _context.Remove(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache(cacheSuffix);
    }

    private async Task DeleteStatusLookupAsync(string cacheSuffix, int id, string label, CancellationToken cancellationToken)
    {
        var entity = cacheSuffix switch
        {
            "membership-statuses" => (object?)await _context.MembershipStatuses.FindAsync([id], cancellationToken),
            "loan-statuses" => await _context.LoanStatuses.FindAsync([id], cancellationToken),
            "reservation-statuses" => await _context.ReservationStatuses.FindAsync([id], cancellationToken),
            "activity-types" => await _context.ActivityTypes.FindAsync([id], cancellationToken),
            _ => null
        } ?? throw new NotFoundException("Record not found.");

        var isInUse = cacheSuffix switch
        {
            "membership-statuses" => await _context.MemberProfiles.AnyAsync(m => m.MembershipStatusId == id, cancellationToken),
            "loan-statuses" => await _context.Loans.AnyAsync(l => l.LoanStatusId == id, cancellationToken),
            "reservation-statuses" => await _context.Reservations.AnyAsync(r => r.ReservationStatusId == id, cancellationToken),
            "activity-types" => await _context.ActivityLogs.AnyAsync(a => a.ActivityTypeId == id, cancellationToken),
            _ => false
        };

        if (isInUse)
        {
            var usageLabel = cacheSuffix switch
            {
                "membership-statuses" => "members",
                "loan-statuses" => "loans",
                "reservation-statuses" => "reservations",
                "activity-types" => "activity logs",
                _ => "records"
            };
            throw new BusinessException($"Cannot delete {label} that is used by {usageLabel}.");
        }

        _context.Remove(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache(cacheSuffix);
    }

    private async Task EnsureCountryExistsAsync(int countryId, CancellationToken cancellationToken)
    {
        if (!await _context.Countries.AnyAsync(c => c.Id == countryId, cancellationToken))
        {
            throw new ValidationAppException("Country does not exist.");
        }
    }

    private void InvalidateCache(params string[] suffixes)
    {
        foreach (var suffix in suffixes)
        {
            _cache.Remove($"{CacheKeyPrefix}{suffix}");
            _cache.Remove($"{CacheKeyPrefix}{suffix}-all");
        }
        _cache.Remove($"{CacheKeyPrefix}cities-all");
    }

    private static int GetId(object entity) => entity switch
    {
        Genre g => g.Id,
        BookCategory c => c.Id,
        Language l => l.Id,
        Publisher p => p.Id,
        MembershipStatus ms => ms.Id,
        LoanStatus ls => ls.Id,
        ReservationStatus rs => rs.Id,
        ActivityType at => at.Id,
        _ => 0
    };

    private static string GetName(object entity) => entity switch
    {
        Genre g => g.Name,
        BookCategory c => c.Name,
        Language l => l.Name,
        Publisher p => p.Name,
        MembershipStatus ms => ms.Name,
        LoanStatus ls => ls.Name,
        ReservationStatus rs => rs.Name,
        ActivityType at => at.Name,
        Country c => c.Name,
        City c => c.Name,
        _ => string.Empty
    };

    private static void SetName(object entity, string name)
    {
        switch (entity)
        {
            case Genre g: g.Name = name; break;
            case BookCategory c: c.Name = name; break;
            case Language l: l.Name = name; break;
            case Publisher p: p.Name = name; break;
            case MembershipStatus ms: ms.Name = name; break;
            case LoanStatus ls: ls.Name = name; break;
            case ReservationStatus rs: rs.Name = name; break;
            case ActivityType at: at.Name = name; break;
        }
    }
}
