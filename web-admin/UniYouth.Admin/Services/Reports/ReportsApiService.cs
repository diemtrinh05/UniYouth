using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using UniYouth.Admin.Models.DTOs.Reports;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Reports
{
    /// <summary>
    /// Service xử lý các request liên quan đến báo cáo và thống kê
    /// Kế thừa từ ApiClientBase để sử dụng chung logic xác thực
    /// 
    /// QUAN TRỌNG:
    /// - Tất cả dữ liệu báo cáo đều READ-ONLY
    /// - Dữ liệu được lấy từ database view vw_EventAttendanceStats
    /// - Service này CHỈ CÓ các method GET, KHÔNG CÓ POST/PUT/DELETE
    /// </summary>
    public class ReportsApiService : ApiClientBase, IReportsApiService
    {
        private readonly ILogger<ReportsApiService> _logger;
        private readonly IConfiguration _configuration;

        public ReportsApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<ReportsApiService> logger,
            IConfiguration configuration)
            : base(httpClient, httpContextAccessor)
        {
            _logger = logger;
            _configuration = configuration;

            // Cấu hình HttpClient
            var baseUrl = configuration["ApiSettings:BaseUrl"];
            if (string.IsNullOrEmpty(baseUrl))
            {
                throw new InvalidOperationException(
                    "API Base URL không được cấu hình trong appsettings.json");
            }

            _httpClient.BaseAddress = new Uri(baseUrl);
            _httpClient.Timeout = TimeSpan.FromSeconds(30);
        }

        /// <summary>
        /// Lấy danh sách thống kê điểm danh của tất cả sự kiện
        /// 
        /// Endpoint: GET /api/events/all/attendance-stats
        /// Database view: vw_EventAttendanceStats
        /// 
        /// Dữ liệu trả về bao gồm:
        /// - Thông tin cơ bản của sự kiện
        /// - Tổng số đăng ký
        /// - Số lượng điểm danh hợp lệ/không hợp lệ
        /// - Tỷ lệ tham gia (%)
        /// </summary>
        public async Task<AllEventsAttendanceStatsResponseDto?> GetAllEventStatsAsync(
            int pageNumber = 1,
            int pageSize = 10,
            string? q = null,
            int? status = null,
            DateTime? from = null,
            DateTime? to = null,
            string? sortBy = null,
            string? sortDir = null)
        {
            try
            {
                _logger.LogInformation("Đang lấy danh sách thống kê sự kiện");

                AddAuthorizationHeader();

                var query = new Dictionary<string, string?>
                {
                    ["PageNumber"] = (pageNumber <= 0 ? 1 : pageNumber).ToString(),
                    ["PageSize"] = (pageSize <= 0 ? 10 : pageSize).ToString()
                };

                if (!string.IsNullOrWhiteSpace(q))
                {
                    query["Q"] = q;
                }

                if (status.HasValue)
                {
                    query["Status"] = status.Value.ToString();
                }

                if (from.HasValue)
                {
                    query["From"] = from.Value.ToString("O");
                }

                if (to.HasValue)
                {
                    query["To"] = to.Value.ToString("O");
                }

                if (!string.IsNullOrWhiteSpace(sortBy))
                {
                    query["SortBy"] = sortBy;
                }

                if (!string.IsNullOrWhiteSpace(sortDir))
                {
                    query["SortDir"] = sortDir;
                }

                var endpoint = QueryHelpers.AddQueryString("api/events/all/attendance-stats", query);
                var response = await _httpClient.GetAsync(endpoint);

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning(
                        "Không thể lấy thống kê sự kiện. Status: {Status}",
                        response.StatusCode);

                    var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "Không thể tải danh sách báo cáo");
                    _logger.LogWarning("Reports list API error message: {Message}", errorMessage);
                    return null;
                }

                var content = await response.Content.ReadAsStringAsync();

                // swagger: ApiResponseDto<AllEventsAttendanceStatsResponseDto>
                ApiResponseDto<AllEventsAttendanceStatsResponseDto>? wrapped;
                try
                {
                    wrapped = JsonSerializer.Deserialize<ApiResponseDto<AllEventsAttendanceStatsResponseDto>>(
                        content,
                        new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Failed to parse AllEventsAttendanceStatsResponseDtoApiResponseDto for /api/events/all/attendance-stats");
                    wrapped = null;
                }

                if (wrapped != null)
                {
                    if (wrapped.Success && wrapped.Data != null)
                    {
                        wrapped.Data.Items ??= new List<EventStatsListItemDto>();
                        return wrapped.Data;
                    }

                    _logger.LogWarning(
                        "API trả success=false khi lấy thống kê sự kiện. Message: {Message}",
                        wrapped.Message);
                    return null;
                }

                // swagger_v3.json defines a wrapped response (AllEventsAttendanceStatsResponseDtoApiResponseDto).
                // If parsing fails, do not guess/compute summary client-side.
                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy danh sách thống kê sự kiện");
                return null;
            }
        }

        /// <summary>
        /// Lấy thống kê chi tiết điểm danh của một sự kiện
        /// 
        /// Endpoint: GET /api/events/{eventId}/attendance-stats
        /// Database view: vw_EventAttendanceStats
        /// 
        /// Dữ liệu trả về bao gồm:
        /// - Tất cả thông tin trong danh sách
        /// - Tổng số lượt check-in (valid + invalid)
        /// - Số người đăng ký nhưng chưa check-in
        /// </summary>
        public async Task<EventAttendanceStatsDto?> GetEventAttendanceStatsAsync(int eventId)
        {
            try
            {
                _logger.LogInformation(
                    "Đang lấy thống kê chi tiết cho sự kiện {EventId}", eventId);

                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync(
                    $"api/events/{eventId}/attendance-stats");

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return null;
                }

                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning(
                        "Không thể lấy thống kê sự kiện {EventId}. Status: {Status}",
                        eventId, response.StatusCode);
                    return null;
                }

                var content = await response.Content.ReadAsStringAsync();

                // swagger: ApiResponseDto<EventAttendanceStatsDto>
                try
                {
                    var wrapped = JsonSerializer.Deserialize<ApiResponseDto<EventAttendanceStatsDto>>(
                        content,
                        new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                    if (wrapped?.Success == true && wrapped.Data != null)
                    {
                        return wrapped.Data;
                    }
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Failed to parse EventAttendanceStatsDtoApiResponseDto for eventId={EventId}", eventId);
                }

                // Fallback: direct DTO (nếu backend trả không wrapper)
                try
                {
                    return JsonSerializer.Deserialize<EventAttendanceStatsDto>(
                        content,
                        new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Failed to parse EventAttendanceStatsDto (direct) for eventId={EventId}", eventId);
                    return null;
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex, "Lỗi khi lấy thống kê sự kiện {EventId}", eventId);
                return null;
            }
        }

        public async Task<BiometricTelemetryListResponseDto?> GetBiometricTelemetryAsync(
            int pageNumber = 1,
            int pageSize = 20,
            string? q = null,
            int? eventId = null,
            DateTime? from = null,
            DateTime? to = null,
            string? faceStatus = null,
            string? livenessStatus = null,
            bool? onlyInvalid = null)
        {
            try
            {
                AddAuthorizationHeader();

                var query = new Dictionary<string, string?>
                {
                    ["PageNumber"] = (pageNumber <= 0 ? 1 : pageNumber).ToString(),
                    ["PageSize"] = (pageSize <= 0 ? 20 : pageSize).ToString()
                };

                if (!string.IsNullOrWhiteSpace(q))
                {
                    query["Q"] = q;
                }

                if (eventId.HasValue)
                {
                    query["EventId"] = eventId.Value.ToString();
                }

                if (from.HasValue)
                {
                    query["From"] = from.Value.ToString("O");
                }

                if (to.HasValue)
                {
                    query["To"] = to.Value.ToString("O");
                }

                if (!string.IsNullOrWhiteSpace(faceStatus))
                {
                    query["FaceStatus"] = faceStatus;
                }

                if (!string.IsNullOrWhiteSpace(livenessStatus))
                {
                    query["LivenessStatus"] = livenessStatus;
                }

                if (onlyInvalid.HasValue)
                {
                    query["OnlyInvalid"] = onlyInvalid.Value ? "true" : "false";
                }

                var endpoint = QueryHelpers.AddQueryString("api/events/biometric-telemetry", query);
                var response = await _httpClient.GetAsync(endpoint);
                if (!response.IsSuccessStatusCode)
                {
                    _logger.LogWarning("Không thể tải biometric telemetry. Status: {Status}", response.StatusCode);
                    return null;
                }

                var content = await response.Content.ReadAsStringAsync();
                var wrapped = JsonSerializer.Deserialize<ApiResponseDto<BiometricTelemetryListResponseDto>>(
                    content,
                    new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                if (wrapped?.Success == true && wrapped.Data != null)
                {
                    wrapped.Data.Telemetry ??= new BiometricTelemetryPaginatedResultDto();
                    wrapped.Data.Telemetry.Items ??= new List<BiometricTelemetryItemDto>();
                    return wrapped.Data;
                }

                return null;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải biometric telemetry");
                return null;
            }
        }
    }
}
