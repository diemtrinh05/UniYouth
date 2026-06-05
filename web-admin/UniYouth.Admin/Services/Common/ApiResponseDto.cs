using System.Text.Json;

namespace UniYouth.Admin.Services.Common
{
    /// <summary>
    /// API response envelope theo swagger:
    /// { success, message, data, errors }
    /// </summary>
    public class ApiResponseDto<T>
    {
        public bool Success { get; set; }
        public string? Message { get; set; }
        public T? Data { get; set; }
        public Dictionary<string, string[]?>? Errors { get; set; }
    }

    /// <summary>
    /// Dùng cho các endpoint có data không typed trong swagger (ObjectApiResponseDto).
    /// </summary>
    public class ApiResponseDto
    {
        public bool Success { get; set; }
        public string? Message { get; set; }
        public JsonElement? Data { get; set; }
        public Dictionary<string, string[]?>? Errors { get; set; }
    }
}

