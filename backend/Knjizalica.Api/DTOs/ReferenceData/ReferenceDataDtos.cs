using System.ComponentModel.DataAnnotations;

namespace Knjizalica.Api.DTOs.ReferenceData;

public sealed class CountryDto
{
    public int Id { get; init; }
    public required string Name { get; init; }
}

public sealed class CityDto
{
    public int Id { get; init; }
    public required string Name { get; init; }
    public int CountryId { get; init; }
    public string? CountryName { get; init; }
}

public sealed class CreateCountryRequest
{
    [Required, MaxLength(100)]
    public required string Name { get; init; }
}

public sealed class UpdateCountryRequest
{
    [Required, MaxLength(100)]
    public required string Name { get; init; }
}

public sealed class CreateCityRequest
{
    [Required, MaxLength(100)]
    public required string Name { get; init; }

    [Required]
    public int CountryId { get; init; }
}

public sealed class UpdateCityRequest
{
    [Required, MaxLength(100)]
    public required string Name { get; init; }

    [Required]
    public int CountryId { get; init; }
}

public sealed class CreateLookupRequest
{
    [Required, MaxLength(100)]
    public required string Name { get; init; }
}

public sealed class UpdateLookupRequest
{
    [Required, MaxLength(100)]
    public required string Name { get; init; }
}
