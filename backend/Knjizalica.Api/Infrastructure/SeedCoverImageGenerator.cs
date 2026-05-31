using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Drawing.Text;
using System.Runtime.Versioning;

namespace Knjizalica.Api.Infrastructure;

[SupportedOSPlatform("windows")]
public static class SeedCoverImageGenerator
{
    private sealed record CoverSpec(string FileName, string Title, string Author, Color Background);

    private static readonly CoverSpec[] Covers =
    [
        new("1984.png", "1984", "George Orwell", Color.FromArgb(55, 71, 79)),
        new("don-quijote.png", "Don Quijote", "Miguel de Cervantes", Color.FromArgb(121, 85, 72)),
        new("na-drini-cuprija.png", "Na Drini cuprija", "Ivo Andric", Color.FromArgb(94, 53, 177)),
        new("travnicka-hronika.png", "Travnicka hronika", "Ivo Andric", Color.FromArgb(0, 105, 92)),
        new("prokleto-pleme.png", "Prokleto pleme", "Nelson Algren", Color.FromArgb(183, 28, 28)),
        new("dervis-i-smrt.png", "Dervis i smrt", "Mesa Selimovic", Color.FromArgb(21, 101, 192)),
        new("news-welcome.png", "Welcome", "Knjizalica", Color.FromArgb(69, 90, 100)),
        new("default-member.png", "Member", "Knjizalica", Color.FromArgb(84, 110, 122)),
    ];

    public static void EnsureSeedCovers(string webRoot)
    {
        var seedDir = Path.Combine(webRoot, "uploads", "seed");
        Directory.CreateDirectory(seedDir);

        foreach (var cover in Covers)
        {
            var path = Path.Combine(seedDir, cover.FileName);
            // Never overwrite: drop your own PNGs here to replace auto-generated covers.
            if (File.Exists(path))
            {
                continue;
            }

            GenerateCover(path, cover);
        }
    }

    private static void GenerateCover(string path, CoverSpec cover)
    {
        const int width = 240;
        const int height = 340;

        using var bitmap = new Bitmap(width, height);
        using var graphics = Graphics.FromImage(bitmap);
        graphics.SmoothingMode = SmoothingMode.AntiAlias;
        graphics.TextRenderingHint = TextRenderingHint.AntiAliasGridFit;
        graphics.Clear(cover.Background);

        using (var accent = new LinearGradientBrush(
                   new Rectangle(0, height - 130, width, 130),
                   Color.FromArgb(210, 0, 0, 0),
                   Color.FromArgb(240, 0, 0, 0),
                   LinearGradientMode.Vertical))
        {
            graphics.FillRectangle(accent, 0, height - 130, width, 130);
        }

        using var titleFont = new Font("Segoe UI", 17, FontStyle.Bold, GraphicsUnit.Point);
        using var authorFont = new Font("Segoe UI", 11, FontStyle.Regular, GraphicsUnit.Point);
        using var textBrush = new SolidBrush(Color.White);

        var titleRect = new RectangleF(14, height - 118, width - 28, 72);
        var authorRect = new RectangleF(14, height - 44, width - 28, 30);

        var format = new StringFormat
        {
            Alignment = StringAlignment.Center,
            LineAlignment = StringAlignment.Near,
            Trimming = StringTrimming.EllipsisWord,
        };

        graphics.DrawString(cover.Title, titleFont, textBrush, titleRect, format);
        graphics.DrawString(cover.Author, authorFont, textBrush, authorRect, format);

        bitmap.Save(path, ImageFormat.Png);
    }
}
