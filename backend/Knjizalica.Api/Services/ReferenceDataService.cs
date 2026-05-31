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
        var entity = new Country { Name = request.Name.Trim() };
        _context.Countries.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("countries");
        return new CountryDto { Id = entity.Id, Name = entity.Name };
    }

    public async Task<CountryDto> UpdateCountryAsync(int id, UpdateCountryRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _context.Countries.FindAsync([id], cancellationToken)
            ?? throw new NotFoundException("Country not found.");
        entity.Name = request.Name.Trim();
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
        var entity = new City { Name = request.Name.Trim(), CountryId = request.CountryId };
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
        entity.Name = request.Name.Trim();
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

    private async Task<LookupDto> CreateGenreInternalAsync(CreateLookupRequest request, CancellationToken cancellationToken)
    {
        var entity = new Genre { Name = request.Name.Trim() };
        _context.Genres.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("genres");
        return new LookupDto { Id = entity.Id, Name = entity.Name };
    }

    private async Task<LookupDto> CreateBookCategoryInternalAsync(CreateLookupRequest request, CancellationToken cancellationToken)
    {
        var entity = new BookCategory { Name = request.Name.Trim() };
        _context.BookCategories.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("categories");
        return new LookupDto { Id = entity.Id, Name = entity.Name };
    }

    private async Task<LookupDto> CreateLanguageInternalAsync(CreateLookupRequest request, CancellationToken cancellationToken)
    {
        var entity = new Language { Name = request.Name.Trim() };
        _context.Languages.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("languages");
        return new LookupDto { Id = entity.Id, Name = entity.Name };
    }

    private async Task<LookupDto> CreatePublisherInternalAsync(CreateLookupRequest request, CancellationToken cancellationToken)
    {
        var entity = new Publisher { Name = request.Name.Trim() };
        _context.Publishers.Add(entity);
        await _context.SaveChangesAsync(cancellationToken);
        InvalidateCache("publishers");
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
                _ => []
            };
        }) ?? [];
    }

    private async Task<LookupDto> UpdateLookupAsync(string cacheSuffix, int id, UpdateLookupRequest request, CancellationToken cancellationToken)
    {
        var entity = cacheSuffix switch
        {
            "genres" => (object?)await _context.Genres.FindAsync([id], cancellationToken),
            "categories" => await _context.BookCategories.FindAsync([id], cancellationToken),
            "languages" => await _context.Languages.FindAsync([id], cancellationToken),
            "publishers" => await _context.Publishers.FindAsync([id], cancellationToken),
            _ => null
        } ?? throw new NotFoundException("Record not found.");

        SetName(entity, request.Name.Trim());
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
        _ => 0
    };

    private static string GetName(object entity) => entity switch
    {
        Genre g => g.Name,
        BookCategory c => c.Name,
        Language l => l.Name,
        Publisher p => p.Name,
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
        }
    }
}
