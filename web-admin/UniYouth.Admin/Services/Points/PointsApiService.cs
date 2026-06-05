using System.Net.Http.Headers;
using System.Text.Json;
using UniYouth.Admin.Models.DTOs.Points;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Points
{
    public class PointsApiService : ApiClientBase, IPointsApiService
    {
        private readonly ILogger<PointsApiService> _logger;

        public PointsApiService(
            HttpClient httpClient,
            IHttpContextAccessor accessor,
            ILogger<PointsApiService> logger,
            IConfiguration configuration)
            : base(httpClient, accessor)
        {
            _logger = logger;

            var baseUrl = configuration["ApiSettings:BaseUrl"];
            if (string.IsNullOrEmpty(baseUrl))
            {
                throw new InvalidOperationException("API Base URL chưa được cấu hình");
            }

            _httpClient.BaseAddress = new Uri(baseUrl);
            _httpClient.DefaultRequestHeaders.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/json"));
        }

        /// <summary>
        /// GET /api/users/me/points
        /// Swagger: UserPointSummaryDtoApiResponseDto
        /// </summary>
        public async Task<UserPointSummaryDto?> GetMyPointsSummaryAsync()
        {
            var endpoint = "/api/users/me/points";

            try
            {
                _logger.LogInformation("Calling API: GET {Endpoint}", endpoint);

                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync(endpoint);
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning(
                        "Failed to get my points summary. Status: {StatusCode}",
                        response.StatusCode);
                    return null;
                }

                var json = await response.Content.ReadAsStringAsync();
                if (string.IsNullOrWhiteSpace(json))
                {
                    return null;
                }

                // Parse wrapper first (swagger)
                try
                {
                    var wrapped = JsonSerializer.Deserialize<ApiResponseDto<UserPointSummaryDto>>(
                        json,
                        new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                    if (wrapped?.Success == true && wrapped.Data != null)
                    {
                        return wrapped.Data;
                    }

                    if (wrapped != null)
                    {
                        _logger.LogWarning(
                            "Points summary API returned success=false or data=null. Message: {Message}",
                            wrapped.Message);
                        return null;
                    }
                }
                catch (JsonException)
                {
                    // ignore and fallback
                }

                // Fallback: direct DTO (older format)
                return JsonSerializer.Deserialize<UserPointSummaryDto>(
                    json,
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error calling {Endpoint}", endpoint);
                return null;
            }
        }
    }
}

