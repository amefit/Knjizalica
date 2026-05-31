using Knjizalica.Api.DTOs.Files;
using Knjizalica.Shared.Exceptions;

namespace Knjizalica.Api.Services;

public interface IFileStorageService
{
    Task<FileUploadResponse> UploadImageAsync(IFormFile file, string category, CancellationToken cancellationToken = default);
}

public sealed class FileStorageService : IFileStorageService
{
    private static readonly Dictionary<string, byte[][]> AllowedMagicBytes = new()
    {
        ["image/jpeg"] = [[0xFF, 0xD8, 0xFF]],
        ["image/png"] = [[0x89, 0x50, 0x4E, 0x47]],
        ["image/webp"] = [[0x52, 0x49, 0x46, 0x46]]
    };

    private static readonly HashSet<string> AllowedContentTypes = ["image/jpeg", "image/png", "image/webp"];
    private const long MaxFileSizeBytes = 5 * 1024 * 1024;

    private readonly IWebHostEnvironment _environment;

    public FileStorageService(IWebHostEnvironment environment)
    {
        _environment = environment;
    }

    public async Task<FileUploadResponse> UploadImageAsync(IFormFile file, string category, CancellationToken cancellationToken = default)
    {
        if (file.Length == 0)
        {
            throw new ValidationAppException("File is empty.");
        }

        if (file.Length > MaxFileSizeBytes)
        {
            throw new ValidationAppException("File exceeds maximum size of 5 MB.");
        }

        var contentType = file.ContentType.ToLowerInvariant();
        if (!AllowedContentTypes.Contains(contentType))
        {
            throw new ValidationAppException("Only JPEG, PNG, and WebP images are allowed.");
        }

        await using var stream = file.OpenReadStream();
        var header = new byte[12];
        var read = await stream.ReadAsync(header.AsMemory(0, header.Length), cancellationToken);
        if (!ValidateMagicBytes(contentType, header.AsSpan(0, read)))
        {
            throw new ValidationAppException("File content does not match the declared image type.");
        }

        var safeCategory = SanitizeCategory(category);
        var extension = contentType switch
        {
            "image/jpeg" => ".jpg",
            "image/png" => ".png",
            "image/webp" => ".webp",
            _ => throw new ValidationAppException("Unsupported image type.")
        };

        var uploadsRoot = Path.Combine(_environment.WebRootPath ?? Path.Combine(_environment.ContentRootPath, "wwwroot"), "uploads", safeCategory);
        Directory.CreateDirectory(uploadsRoot);

        var fileName = $"{Guid.NewGuid():N}{extension}";
        var fullPath = Path.Combine(uploadsRoot, fileName);

        stream.Position = 0;
        await using var output = File.Create(fullPath);
        await file.CopyToAsync(output, cancellationToken);

        var relativePath = $"/uploads/{safeCategory}/{fileName}";
        return new FileUploadResponse
        {
            Path = relativePath,
            FileName = fileName,
            ContentType = contentType,
            SizeBytes = file.Length
        };
    }

    private static bool ValidateMagicBytes(string contentType, ReadOnlySpan<byte> header)
    {
        if (!AllowedMagicBytes.TryGetValue(contentType, out var signatures))
        {
            return false;
        }

        foreach (var signature in signatures)
        {
            if (header.Length >= signature.Length && header[..signature.Length].SequenceEqual(signature))
            {
                if (contentType == "image/webp" && header.Length >= 12)
                {
                    return header[8..12].SequenceEqual("WEBP"u8);
                }

                return true;
            }
        }

        return false;
    }

    private static string SanitizeCategory(string category)
    {
        var safe = new string(category.Where(char.IsLetterOrDigit).ToArray()).ToLowerInvariant();
        return string.IsNullOrWhiteSpace(safe) ? "general" : safe;
    }
}
