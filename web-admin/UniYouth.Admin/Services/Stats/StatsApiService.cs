using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using UniYouth.Admin.Models.DTOs.Reports;
using UniYouth.Admin.Models.DTOs.Stats;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Stats
{
    public class StatsApiService : ApiClientBase, IStatsApiService
    {
        private readonly ILogger<StatsApiService> _logger;

        public StatsApiService(
            HttpClient httpClient,
            IHttpContextAccessor accessor,
            ILogger<StatsApiService> logger,
            IConfiguration configuration)
            : base(httpClient, accessor)
        {
            _logger = logger;

            // Cấu hình HttpClient
            var baseUrl = configuration["ApiSettings:BaseUrl"];
            if (string.IsNullOrEmpty(baseUrl))
            {
                throw new InvalidOperationException("API Base URL chưa được cấu hình");
            }

            _httpClient.BaseAddress = new Uri(baseUrl);
            _httpClient.DefaultRequestHeaders.Accept.Add(
                new MediaTypeWithQualityHeaderValue("application/json"));
        }

        #region Stats APIs
        /// <summary>
        /// Lấy thống kê điểm danh của một sự kiện
        /// Endpoint: GET /api/events/{eventId}/attendance-stats
        /// </summary>
        public async Task<EventAttendanceStats?> GetEventAttendanceStatsAsync(int eventId)
        {
            try
            {
                var endpoint = $"/api/events/{eventId}/attendance-stats";

                _logger.LogDebug("Calling API: GET {Endpoint}", endpoint);

                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync(endpoint);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("Failed to get attendance stats for event {EventId}", eventId);
                    return null;
                }

                var content = await response.Content.ReadAsStringAsync();

                // swagger: ApiResponseDto<EventAttendanceStats>
                try
                {
                    var wrapped = JsonSerializer.Deserialize<ApiResponseDto<EventAttendanceStats>>(
                        content,
                        new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                    if (wrapped?.Success == true && wrapped.Data != null)
                    {
                        return wrapped.Data;
                    }
                }
                catch (JsonException)
                {
                    // ignore and fallback below
                }

                // Fallback: direct DTO
                return JsonSerializer.Deserialize<EventAttendanceStats>(
                    content,
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting attendance stats for event {EventId}", eventId);
                return null;
            }
        }

        /// <summary>
        /// Lấy thống kê tất cả events
        /// Endpoint: GET /api/events/all/attendance-stats
        /// </summary>
        public async Task<List<EventStatsListItem>?> GetAllEventsStatsAsync()
        {
            try
            {
                AddAuthorizationHeader();

                const int pageSize = 100;
                var pageNumber = 1;
                var allItems = new List<EventStatsListItem>();

                while (true)
                {
                    var pageResult = await GetAllEventsStatsPageAsync(pageNumber, pageSize);
                    if (pageResult == null)
                    {
                        return pageNumber == 1 ? null : allItems;
                    }

                    var (items, hasNextPage) = pageResult.Value;

                    if (items.Count == 0)
                    {
                        break;
                    }

                    allItems.AddRange(items);

                    if (!hasNextPage)
                    {
                        break;
                    }

                    pageNumber++;
                }

                _logger.LogInformation(
                    "Successfully retrieved stats for {Count} events across {PageCount} pages",
                    allItems.Count,
                    pageNumber);

                return allItems;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error getting all events stats");
                return null;
            }
        }

        private async Task<(List<EventStatsListItem> Items, bool HasNextPage)?> GetAllEventsStatsPageAsync(
            int pageNumber,
            int pageSize)
        {
            var endpoint = QueryHelpers.AddQueryString(
                "/api/events/all/attendance-stats",
                new Dictionary<string, string?>
                {
                    ["PageNumber"] = pageNumber.ToString(),
                    ["PageSize"] = pageSize.ToString()
                });

            _logger.LogInformation("Calling API: GET {Endpoint}", endpoint);

            var response = await _httpClient.GetAsync(endpoint);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Failed to get all events stats page {PageNumber}. Status: {StatusCode}",
                    pageNumber,
                    response.StatusCode);
                return null;
            }

            var rawContent = await response.Content.ReadAsStringAsync();
            var options = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };

            try
            {
                var apiResponse = JsonSerializer.Deserialize<ApiResponseDto>(rawContent, options);
                if (apiResponse?.Success == true && apiResponse.Data.HasValue)
                {
                    if (apiResponse.Data.Value.ValueKind == JsonValueKind.Array)
                    {
                        var directItems = JsonSerializer.Deserialize<List<EventStatsListItem>>(
                            apiResponse.Data.Value.GetRawText(),
                            options) ?? new List<EventStatsListItem>();
                        return (directItems, false);
                    }

                    if (apiResponse.Data.Value.ValueKind == JsonValueKind.Object)
                    {
                        var wrappedData = JsonSerializer.Deserialize<AllEventsAttendanceStatsResponseDto>(
                            apiResponse.Data.Value.GetRawText(),
                            options);

                        if (wrappedData?.Items != null)
                        {
                            var items = wrappedData.Items
                                .Select(item => new EventStatsListItem
                                {
                                    EventID = item.EventID,
                                    EventName = item.EventName,
                                    StartTime = item.StartTime,
                                    Status = item.Status,
                                    MaxParticipants = item.MaxParticipants,
                                    TotalRegistrations = item.TotalRegistrations,
                                    ValidAttendances = item.ValidAttendances,
                                    InvalidAttendances = item.InvalidAttendances,
                                    AttendanceRate = item.AttendanceRate,
                                    NotCheckedIn = item.NotCheckedIn
                                })
                                .ToList();

                            return (items, wrappedData.Pagination?.HasNextPage ?? false);
                        }
                    }
                }
            }
            catch (JsonException ex)
            {
                _logger.LogWarning(
                    ex,
                    "Failed to parse wrapped attendance stats page {PageNumber}. Falling back.",
                    pageNumber);
            }

            try
            {
                var typedWrapped = JsonSerializer.Deserialize<ApiResponseDto<List<EventStatsListItem>>>(rawContent, options);
                if (typedWrapped?.Success == true && typedWrapped.Data != null)
                {
                    return (typedWrapped.Data, false);
                }
            }
            catch (JsonException)
            {
                // Ignore and try direct array parsing below.
            }

            var fallbackItems = JsonSerializer.Deserialize<List<EventStatsListItem>>(rawContent, options)
                ?? new List<EventStatsListItem>();
            return (fallbackItems, false);
        }
        #endregion
    }
}
