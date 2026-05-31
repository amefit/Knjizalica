using System.Text;

namespace Knjizalica.Api.Services;

/// <summary>
/// Lightweight PDF 1.4 writer using built-in Helvetica (no external font files).
/// </summary>
internal static class MinimalPdfBuilder
{
    public static byte[] Build(string title, string subtitle, IReadOnlyList<string> lines)
    {
        var streamContent = new StringBuilder();
        streamContent.AppendLine("BT");

        var y = 770;
        AppendLine(streamContent, title, 40, y, 16);
        y -= 22;
        AppendLine(streamContent, subtitle, 40, y, 10);
        y -= 24;

        foreach (var line in lines)
        {
            if (y < 40)
            {
                break;
            }

            AppendLine(streamContent, line, 40, y, 9);
            y -= 14;
        }

        streamContent.AppendLine("ET");

        var contentBytes = Encoding.ASCII.GetBytes(streamContent.ToString());
        var objects = new List<string>
        {
            "<< /Type /Catalog /Pages 2 0 R >>",
            "<< /Type /Pages /Kids [3 0 R] /Count 1 >>",
            "<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>",
            $"<< /Length {contentBytes.Length} >>\nstream\n{Encoding.ASCII.GetString(contentBytes)}endstream",
            "<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>"
        };

        using var pdf = new MemoryStream();
        var writer = new StreamWriter(pdf, Encoding.ASCII) { NewLine = "\n" };
        writer.Write("%PDF-1.4\n");

        var offsets = new List<long> { 0 };
        for (var i = 0; i < objects.Count; i++)
        {
            offsets.Add(pdf.Position);
            writer.Write($"{i + 1} 0 obj\n{objects[i]}\nendobj\n");
            writer.Flush();
        }

        var xrefPos = pdf.Position;
        writer.Write($"xref\n0 {objects.Count + 1}\n");
        writer.Write("0000000000 65535 f \n");
        foreach (var offset in offsets.Skip(1))
        {
            writer.Write($"{offset:D10} 00000 n \n");
        }

        writer.Write($"trailer\n<< /Size {objects.Count + 1} /Root 1 0 R >>\n");
        writer.Write($"startxref\n{xrefPos}\n%%EOF\n");
        writer.Flush();

        return pdf.ToArray();
    }

    private static void AppendLine(StringBuilder stream, string text, int x, int y, int fontSize)
    {
        stream.AppendLine($"/F1 {fontSize} Tf {x} {y} Td ({Escape(text)}) Tj");
        stream.AppendLine("0 -14 Td");
    }

    private static string Escape(string text)
    {
        var sanitized = text
            .Replace("\\", "\\\\", StringComparison.Ordinal)
            .Replace("(", "\\(", StringComparison.Ordinal)
            .Replace(")", "\\)", StringComparison.Ordinal);

        var sb = new StringBuilder(sanitized.Length);
        foreach (var ch in sanitized)
        {
            sb.Append(ch < 127 ? ch : '?');
        }

        return sb.ToString();
    }
}
