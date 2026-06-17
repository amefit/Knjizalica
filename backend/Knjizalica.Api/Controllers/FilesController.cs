using Knjizalica.Api.DTOs.Files;
using Knjizalica.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Knjizalica.Shared.Constants;

namespace Knjizalica.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public sealed class FilesController : ControllerBase
{
    private readonly IFileStorageService _service;
    private static readonly HashSet<string> AllowedCategories = new(StringComparer.OrdinalIgnoreCase) { "books", "news" };

    public FilesController(IFileStorageService service)
    {
        _service = service;
    }

    [Authorize(Roles = $"{RoleNames.Admin},{RoleNames.Librarian}")]
    [HttpPost("upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(5 * 1024 * 1024)]
    public async Task<ActionResult<FileUploadResponse>> Upload([FromForm] UploadFileRequest request, [FromQuery] string category = "books", CancellationToken cancellationToken = default)
    {
        if (!AllowedCategories.Contains(category))
        {
            return BadRequest(new { Message = $"Category '{category}' is not allowed. Valid categories are: {string.Join(", ", AllowedCategories)}" });
        }

        return Ok(await _service.UploadImageAsync(request.File, category, cancellationToken));
    }
}
