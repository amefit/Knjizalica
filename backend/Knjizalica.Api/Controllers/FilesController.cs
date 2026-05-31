using Knjizalica.Api.DTOs.Files;
using Knjizalica.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Knjizalica.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/[controller]")]
public sealed class FilesController : ControllerBase
{
    private readonly IFileStorageService _service;

    public FilesController(IFileStorageService service)
    {
        _service = service;
    }

    [HttpPost("upload")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(5 * 1024 * 1024)]
    public async Task<ActionResult<FileUploadResponse>> Upload([FromForm] UploadFileRequest request, [FromQuery] string category = "general", CancellationToken cancellationToken = default) =>
        Ok(await _service.UploadImageAsync(request.File, category, cancellationToken));
}
