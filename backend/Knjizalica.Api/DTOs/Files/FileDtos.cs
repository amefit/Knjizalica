namespace Knjizalica.Api.DTOs.Files;

public sealed class UploadFileRequest
{
    public IFormFile File { get; set; } = null!;
}

public sealed class FileUploadResponse
{
    public required string Path { get; init; }
    public required string FileName { get; init; }
    public required string ContentType { get; init; }
    public long SizeBytes { get; init; }
}
