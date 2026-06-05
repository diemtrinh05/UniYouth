using System.Text.Json;

namespace UniYouth.Admin.Services.Common
{
    public static class ApiResponseReader
    {
        private static readonly JsonSerializerOptions DefaultJsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        public static async Task<ApiResponseDto<T>?> ReadAsync<T>(
            HttpResponseMessage response,
            JsonSerializerOptions? options = null)
        {
            if (response.Content == null)
            {
                return null;
            }

            var json = await response.Content.ReadAsStringAsync();
            if (string.IsNullOrWhiteSpace(json))
            {
                return null;
            }

            return JsonSerializer.Deserialize<ApiResponseDto<T>>(
                json,
                options ?? DefaultJsonOptions);
        }

        public static async Task<ApiResponseDto?> ReadUntypedAsync(
            HttpResponseMessage response,
            JsonSerializerOptions? options = null)
        {
            if (response.Content == null)
            {
                return null;
            }

            var json = await response.Content.ReadAsStringAsync();
            if (string.IsNullOrWhiteSpace(json))
            {
                return null;
            }

            return JsonSerializer.Deserialize<ApiResponseDto>(
                json,
                options ?? DefaultJsonOptions);
        }
    }
}

