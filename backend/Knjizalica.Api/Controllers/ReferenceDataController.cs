using Knjizalica.Api.Common;
using Knjizalica.Api.DTOs.ReferenceData;
using Knjizalica.Api.Services;
using Knjizalica.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjizalica.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public sealed class ReferenceDataController : ControllerBase
{
    private readonly IReferenceDataService _service;

    public ReferenceDataController(IReferenceDataService service)
    {
        _service = service;
    }

    [AllowAnonymous]
    [HttpGet("countries")]
    public async Task<ActionResult<IReadOnlyList<CountryDto>>> GetCountries(CancellationToken cancellationToken) =>
        Ok(await _service.GetCountriesAsync(cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("countries")]
    public async Task<ActionResult<CountryDto>> CreateCountry([FromBody] CreateCountryRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateCountryAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPut("countries/{id:int}")]
    public async Task<ActionResult<CountryDto>> UpdateCountry(int id, [FromBody] UpdateCountryRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdateCountryAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpDelete("countries/{id:int}")]
    public async Task<ActionResult<MessageResponse>> DeleteCountry(int id, CancellationToken cancellationToken)
    {
        await _service.DeleteCountryAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Country deleted." });
    }

    [AllowAnonymous]
    [HttpGet("cities")]
    public async Task<ActionResult<IReadOnlyList<CityDto>>> GetCities([FromQuery] int? countryId, CancellationToken cancellationToken) =>
        Ok(await _service.GetCitiesAsync(countryId, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("cities")]
    public async Task<ActionResult<CityDto>> CreateCity([FromBody] CreateCityRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateCityAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPut("cities/{id:int}")]
    public async Task<ActionResult<CityDto>> UpdateCity(int id, [FromBody] UpdateCityRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdateCityAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpDelete("cities/{id:int}")]
    public async Task<ActionResult<MessageResponse>> DeleteCity(int id, CancellationToken cancellationToken)
    {
        await _service.DeleteCityAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "City deleted." });
    }

    [HttpGet("genres")]
    public async Task<ActionResult<IReadOnlyList<LookupDto>>> GetGenres(CancellationToken cancellationToken) =>
        Ok(await _service.GetGenresAsync(cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("genres")]
    public async Task<ActionResult<LookupDto>> CreateGenre([FromBody] CreateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateGenreAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPut("genres/{id:int}")]
    public async Task<ActionResult<LookupDto>> UpdateGenre(int id, [FromBody] UpdateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdateGenreAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpDelete("genres/{id:int}")]
    public async Task<ActionResult<MessageResponse>> DeleteGenre(int id, CancellationToken cancellationToken)
    {
        await _service.DeleteGenreAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Genre deleted." });
    }

    [HttpGet("book-categories")]
    public async Task<ActionResult<IReadOnlyList<LookupDto>>> GetBookCategories(CancellationToken cancellationToken) =>
        Ok(await _service.GetBookCategoriesAsync(cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("book-categories")]
    public async Task<ActionResult<LookupDto>> CreateBookCategory([FromBody] CreateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateBookCategoryAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPut("book-categories/{id:int}")]
    public async Task<ActionResult<LookupDto>> UpdateBookCategory(int id, [FromBody] UpdateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdateBookCategoryAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpDelete("book-categories/{id:int}")]
    public async Task<ActionResult<MessageResponse>> DeleteBookCategory(int id, CancellationToken cancellationToken)
    {
        await _service.DeleteBookCategoryAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Book category deleted." });
    }

    [HttpGet("languages")]
    public async Task<ActionResult<IReadOnlyList<LookupDto>>> GetLanguages(CancellationToken cancellationToken) =>
        Ok(await _service.GetLanguagesAsync(cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("languages")]
    public async Task<ActionResult<LookupDto>> CreateLanguage([FromBody] CreateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateLanguageAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPut("languages/{id:int}")]
    public async Task<ActionResult<LookupDto>> UpdateLanguage(int id, [FromBody] UpdateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdateLanguageAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpDelete("languages/{id:int}")]
    public async Task<ActionResult<MessageResponse>> DeleteLanguage(int id, CancellationToken cancellationToken)
    {
        await _service.DeleteLanguageAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Language deleted." });
    }

    [HttpGet("publishers")]
    public async Task<ActionResult<IReadOnlyList<LookupDto>>> GetPublishers(CancellationToken cancellationToken) =>
        Ok(await _service.GetPublishersAsync(cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("publishers")]
    public async Task<ActionResult<LookupDto>> CreatePublisher([FromBody] CreateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreatePublisherAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPut("publishers/{id:int}")]
    public async Task<ActionResult<LookupDto>> UpdatePublisher(int id, [FromBody] UpdateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdatePublisherAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpDelete("publishers/{id:int}")]
    public async Task<ActionResult<MessageResponse>> DeletePublisher(int id, CancellationToken cancellationToken)
    {
        await _service.DeletePublisherAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Publisher deleted." });
    }

    [HttpGet("membership-statuses")]
    public async Task<ActionResult<IReadOnlyList<LookupDto>>> GetMembershipStatuses(CancellationToken cancellationToken) =>
        Ok(await _service.GetMembershipStatusesAsync(cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("membership-statuses")]
    public async Task<ActionResult<LookupDto>> CreateMembershipStatus([FromBody] CreateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateMembershipStatusAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPut("membership-statuses/{id:int}")]
    public async Task<ActionResult<LookupDto>> UpdateMembershipStatus(int id, [FromBody] UpdateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdateMembershipStatusAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpDelete("membership-statuses/{id:int}")]
    public async Task<ActionResult<MessageResponse>> DeleteMembershipStatus(int id, CancellationToken cancellationToken)
    {
        await _service.DeleteMembershipStatusAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Membership status deleted." });
    }

    [HttpGet("loan-statuses")]
    public async Task<ActionResult<IReadOnlyList<LookupDto>>> GetLoanStatuses(CancellationToken cancellationToken) =>
        Ok(await _service.GetLoanStatusesAsync(cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("loan-statuses")]
    public async Task<ActionResult<LookupDto>> CreateLoanStatus([FromBody] CreateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateLoanStatusAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPut("loan-statuses/{id:int}")]
    public async Task<ActionResult<LookupDto>> UpdateLoanStatus(int id, [FromBody] UpdateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdateLoanStatusAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpDelete("loan-statuses/{id:int}")]
    public async Task<ActionResult<MessageResponse>> DeleteLoanStatus(int id, CancellationToken cancellationToken)
    {
        await _service.DeleteLoanStatusAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Loan status deleted." });
    }

    [HttpGet("reservation-statuses")]
    public async Task<ActionResult<IReadOnlyList<LookupDto>>> GetReservationStatuses(CancellationToken cancellationToken) =>
        Ok(await _service.GetReservationStatusesAsync(cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("reservation-statuses")]
    public async Task<ActionResult<LookupDto>> CreateReservationStatus([FromBody] CreateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateReservationStatusAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPut("reservation-statuses/{id:int}")]
    public async Task<ActionResult<LookupDto>> UpdateReservationStatus(int id, [FromBody] UpdateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdateReservationStatusAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpDelete("reservation-statuses/{id:int}")]
    public async Task<ActionResult<MessageResponse>> DeleteReservationStatus(int id, CancellationToken cancellationToken)
    {
        await _service.DeleteReservationStatusAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Reservation status deleted." });
    }

    [HttpGet("activity-types")]
    public async Task<ActionResult<IReadOnlyList<LookupDto>>> GetActivityTypes(CancellationToken cancellationToken) =>
        Ok(await _service.GetActivityTypesAsync(cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPost("activity-types")]
    public async Task<ActionResult<LookupDto>> CreateActivityType([FromBody] CreateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.CreateActivityTypeAsync(request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpPut("activity-types/{id:int}")]
    public async Task<ActionResult<LookupDto>> UpdateActivityType(int id, [FromBody] UpdateLookupRequest request, CancellationToken cancellationToken) =>
        Ok(await _service.UpdateActivityTypeAsync(id, request, cancellationToken));

    [Authorize(Roles = RoleNames.Admin)]
    [HttpDelete("activity-types/{id:int}")]
    public async Task<ActionResult<MessageResponse>> DeleteActivityType(int id, CancellationToken cancellationToken)
    {
        await _service.DeleteActivityTypeAsync(id, cancellationToken);
        return Ok(new MessageResponse { Message = "Activity type deleted." });
    }
}
