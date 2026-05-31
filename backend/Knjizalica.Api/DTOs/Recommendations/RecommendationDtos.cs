using Knjizalica.Api.DTOs.Books;

namespace Knjizalica.Api.DTOs.Recommendations;

public sealed class RecommendationDto
{
    public required BookListDto Book { get; init; }
    public required string Reason { get; init; }
    public required string Source { get; init; }
    public double Score { get; init; }
}

public sealed class RecommendationsResponse
{
    public IReadOnlyList<RecommendationDto> ContentBased { get; init; } = [];
    public IReadOnlyList<RecommendationDto> Popular { get; init; } = [];
}
