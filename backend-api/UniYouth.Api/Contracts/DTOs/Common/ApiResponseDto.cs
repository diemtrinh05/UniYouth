namespace UniYouth.Api.Contracts.DTOs.Common
{
    /// <summary>
    /// Envelope chuẩn cho response API.
    /// </summary>
    public class ApiResponseDto<T>
    {
        public bool Success { get; set; }

        public string Message { get; set; } = string.Empty;

        public T? Data { get; set; }

        public Dictionary<string, string[]>? Errors { get; set; }
    }
}

