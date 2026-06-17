using System.Text;

namespace Knjizalica.Api.Services;

/// <summary>
/// PDF 1.4 writer with multi-page support.
/// Note: Helvetica has limited support for Croatian characters in standard WinAnsiEncoding.
/// </summary>
internal static class MinimalPdfBuilder
{
    private const int PageHeight = 792;
    private const int Margin = 40;
    private const int LineHeight = 14;

    public static byte[] Build(string title, string subtitle, IReadOnlyList<string> lines)
    {
        var pagesContent = new List<string>();
        var currentY = PageHeight - Margin;

        var currentStream = new StringBuilder();
        currentStream.AppendLine("BT");
        
        // Header on first page
        AppendLine(currentStream, title, Margin, currentY, 16);
        currentY -= 22;
        AppendLine(currentStream, subtitle, Margin, currentY, 10);
        currentY -= 24;

        foreach (var line in lines)
        {
            if (currentY < Margin + LineHeight)
            {
                currentStream.AppendLine("ET");
                pagesContent.Add(currentStream.ToString());
                
                currentStream = new StringBuilder();
                currentStream.AppendLine("BT");
                currentY = PageHeight - Margin;
            }

            AppendLine(currentStream, line, Margin, currentY, 9);
            currentY -= LineHeight;
        }

        currentStream.AppendLine("ET");
        pagesContent.Add(currentStream.ToString());

        using var pdf = new MemoryStream();
        var writer = new StreamWriter(pdf, Encoding.GetEncoding("ISO-8859-1")) { NewLine = "\n" };
        writer.Write("%PDF-1.4\n");

        var objects = new List<string>();
        var pageRefs = new List<int>();
        
        // 1. Catalog
        // 2. Pages Parent
        // 3... Page objects
        // ... Content streams
        // ... Font

        var catalogIdx = 1;
        var pagesParentIdx = 2;
        var fontIdx = 0; // To be determined

        var currentObjIdx = 3;
        var contentStreamStartIdx = currentObjIdx + pagesContent.Count;
        fontIdx = contentStreamStartIdx + pagesContent.Count;

        objects.Add($"<< /Type /Catalog /Pages {pagesParentIdx} 0 R >>");
        
        var kids = string.Join(" ", Enumerable.Range(3, pagesContent.Count).Select(i => $"{i} 0 R"));
        objects.Add($"<< /Type /Pages /Kids [{kids}] /Count {pagesContent.Count} >>");

        for (int i = 0; i < pagesContent.Count; i++)
        {
            objects.Add($"<< /Type /Page /Parent {pagesParentIdx} 0 R /MediaBox [0 0 612 792] /Contents {contentStreamStartIdx + i} 0 R /Resources << /Font << /F1 {fontIdx} 0 R >> >> >>");
        }

        foreach (var content in pagesContent)
        {
            var bytes = Encoding.GetEncoding("ISO-8859-1").GetBytes(content);
            objects.Add($"<< /Length {bytes.Length} >>\nstream\n{content}endstream");
        }

        objects.Add("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>");

        var offsets = new List<long>();
        for (var i = 0; i < objects.Count; i++)
        {
            offsets.Add(pdf.Position);
            writer.Write($"{i + 1} 0 obj\n{objects[i]}\nendobj\n");
            writer.Flush();
        }

        var xrefPos = pdf.Position;
        writer.Write($"xref\n0 {objects.Count + 1}\n");
        writer.Write("0000000000 65535 f \n");
        foreach (var offset in offsets)
        {
            writer.Write($"{offset:D10} 00000 n \n");
        }

        writer.Write($"trailer\n<< /Size {objects.Count + 1} /Root {catalogIdx} 0 R >>\n");
        writer.Write($"startxref\n{xrefPos}\n%%EOF\n");
        writer.Flush();

        return pdf.ToArray();
    }

    private static void AppendLine(StringBuilder stream, string text, int x, int y, int fontSize)
    {
        stream.AppendLine($"/F1 {fontSize} Tf {x} {y} Td ({Escape(text)}) Tj");
        stream.AppendLine($"0 0 Td"); // Reset relative Td if needed, but we use absolute Y logic
    }

    private static string Escape(string text)
    {
        var sb = new StringBuilder();
        foreach (var c in text)
        {
            switch (c)
            {
                case '\\': sb.Append("\\\\"); break;
                case '(': sb.Append("\\("); break;
                case ')': sb.Append("\\)"); break;
                // Basic Croatian support for WinAnsiEncoding (some chars map to similar ones if not exact)
                case 'š': sb.Append("\u00B9"); break; // Use octal or hex if needed, but stream is ISO-8859-1
                case 'Š': sb.Append("\u00A9"); break;
                case 'ž': sb.Append("\u00BB"); break;
                case 'Ž': sb.Append("\u00AE"); break;
                case 'ć': sb.Append("c"); break; // Helvetica WinAnsi doesn't have ć
                case 'č': sb.Append("c"); break;
                case 'đ': sb.Append("d"); break;
                case 'Ć': sb.Append("C"); break;
                case 'Č': sb.Append("C"); break;
                case 'Đ': sb.Append("D"); break;
                default:
                    if (c < 128) sb.Append(c);
                    else sb.Append('?');
                    break;
            }
        }
        return sb.ToString();
    }
}
