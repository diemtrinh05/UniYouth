using System.Text;

namespace UniYouth.Api.Shared.Helpers;

public static class TextEncodingNormalizer
{
    private static readonly char[] MojibakeMarkers =
    [
        'Ã', 'Â', 'Ä', 'Å', 'Æ', 'Ð', 'á', '¢', '€', '™'
    ];

    public static string? NormalizeVietnameseText(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return value;
        }

        var normalized = value.Trim();
        for (var i = 0; i < 2; i++)
        {
            var decoded = TryDecodeUtf8Mojibake(normalized);
            if (decoded == normalized)
            {
                break;
            }

            normalized = decoded;
        }

        return normalized;
    }

    private static string TryDecodeUtf8Mojibake(string input)
    {
        if (!LooksLikeMojibake(input))
        {
            return input;
        }

        try
        {
            var bytes = Encoding.Latin1.GetBytes(input);
            var decoded = Encoding.UTF8.GetString(bytes);
            return Score(decoded) > Score(input) ? decoded : input;
        }
        catch
        {
            return input;
        }
    }

    private static bool LooksLikeMojibake(string input) =>
        input.IndexOfAny(MojibakeMarkers) >= 0;

    private static int Score(string input)
    {
        var score = 0;
        foreach (var character in input)
        {
            if ("ăâđêôơưáàảãạắằẳẵặấầẩẫậéèẻẽẹếềểễệíìỉĩịóòỏõọốồổỗộớờởỡợúùủũụứừửữựýỳỷỹỵĂÂĐÊÔƠƯÁÀẢÃẠẮẰẲẴẶẤẦẨẪẬÉÈẺẼẸẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌỐỒỔỖỘỚỜỞỠỢÚÙỦŨỤỨỪỬỮỰÝỲỶỸỴ".Contains(character))
            {
                score += 4;
                continue;
            }

            if (char.IsLetterOrDigit(character) || char.IsWhiteSpace(character))
            {
                score += 1;
                continue;
            }

            if (MojibakeMarkers.Contains(character) || character == '�')
            {
                score -= 6;
            }
        }

        return score;
    }
}
