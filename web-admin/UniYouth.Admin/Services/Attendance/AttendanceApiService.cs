using System.Net.Http;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using UniYouth.Admin.Models.DTOs.Attendance;
using UniYouth.Admin.Models.DTOs.Events.Responses;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Attendance
{
    /// <summary>
    /// Service xử lý các thao tác liên quan đến Đăng ký & Điểm danh
    /// Kế thừa từ ApiClientBase để tự động xử lý JWT token
    /// 
    /// LÝ DO PAGES LÀ READ-ONLY:
    /// 
    /// 1. DATA INTEGRITY (Tính toàn vẹn dữ liệu):
    ///    - Dữ liệu điểm danh đã được validate khi check-in
    ///    - Sửa/xóa sau này sẽ làm mất tính chính xác
    ///    - Cần audit trail đầy đủ cho mọi thay đổi
    /// 
    /// 2. ACCOUNTABILITY (Trách nhiệm):
    ///    - Mỗi check-in có timestamp, GPS, IP address
    ///    - Không thể thay đổi tùy tiện để tránh gian lận
    ///    - Admin chỉ XEM để kiểm tra, không SỬA
    /// 
    /// 3. WORKFLOW (Quy trình):
    ///    - Nếu có sai sót, phải có quy trình appeal chính thức
    ///    - Thay đổi phải được log và approve
    ///    - Không cho phép sửa trực tiếp trên giao diện
    /// 
    /// 4. REPORTING (Báo cáo):
    ///    - Pages này dùng cho mục đích báo cáo và thống kê
    ///    - Admin cần dữ liệu nguyên gốc để phân tích
    ///    - Sửa đổi sẽ làm sai lệch báo cáo
    /// 
    /// CÁCH HIỂN THỊ ATTENDANCE VALIDITY:
    /// 
    /// Valid Attendance (IsValid = true):
    /// - Highlight màu XANH LÁ (success)
    /// - Icon: check-circle
    /// - Hiển thị khoảng cách (nếu < AllowRadius)
    /// - Có thể tính điểm, cấp certificate
    /// 
    /// Invalid Attendance (IsValid = false):
    /// - Highlight màu ĐỎ (danger)
    /// - Icon: x-circle
    /// - Hiển thị InvalidReason rõ ràng (tooltip hoặc text nhỏ)
    /// - Ví dụ: "Vượt quá khoảng cách 500m", "Ngoài thời gian sự kiện"
    /// - KHÔNG tính điểm, KHÔNG cấp certificate
    /// 
    /// Validation Rules (do Backend thực hiện):
    /// - GPS: Distance <= AllowRadius
    /// - Time: CheckInTime trong khoảng [StartTime - buffer, EndTime + buffer]
    /// - QR: Token valid và chưa expired
    /// - User: Chưa check-in trước đó (no duplicates)
    /// </summary>
    public class AttendanceApiService : ApiClientBase, IAttendanceApiService
    {
        private readonly ILogger<AttendanceApiService> _logger;
        private readonly IConfiguration _configuration;

        public AttendanceApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<AttendanceApiService> logger,
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
        /// Lấy danh sách điểm danh của sự kiện
        /// GET: /api/events/{eventId}/attendances
        /// 
        /// Response bao gồm:
        /// - Thông tin user (Code, FullName, Email)
        /// - Thông tin check-in (CheckInTime, Method)
        /// - Thông tin validation (IsValid, InvalidReason, Distance)
        /// - Thông tin GPS (UserLatitude, UserLongitude)
        /// </summary>
        public async Task<ApiResult<EventAttendancesListResponseDto>> GetEventAttendancesAsync(
            int eventId,
            int pageNumber = 1,
            int pageSize = 10,
            string? q = null,
            bool? isValid = null,
            string? method = null,
            bool? faceVerified = null,
            string? faceVerificationStatus = null,
            string? riskLevel = null,
            bool? suspiciousOnly = null,
            DateTime? from = null,
            DateTime? to = null,
            string? sortBy = null,
            string? sortDir = null)
        {
            try
            {
                _logger.LogInformation("Đang lấy danh sách điểm danh cho sự kiện {EventId}", eventId);

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

                if (isValid.HasValue)
                {
                    query["IsValid"] = isValid.Value ? "true" : "false";
                }

                if (!string.IsNullOrWhiteSpace(method))
                {
                    query["Method"] = method;
                }

                if (faceVerified.HasValue)
                {
                    query["FaceVerified"] = faceVerified.Value ? "true" : "false";
                }

                if (!string.IsNullOrWhiteSpace(faceVerificationStatus))
                {
                    query["FaceVerificationStatus"] = faceVerificationStatus;
                }

                if (!string.IsNullOrWhiteSpace(riskLevel))
                {
                    query["RiskLevel"] = riskLevel;
                }

                if (suspiciousOnly.HasValue)
                {
                    query["SuspiciousOnly"] = suspiciousOnly.Value ? "true" : "false";
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

                var endpoint = QueryHelpers.AddQueryString($"api/events/{eventId}/attendances", query);
                var response = await _httpClient.GetAsync(endpoint);

                if (response.IsSuccessStatusCode)
                {
                    var content = await response.Content.ReadAsStringAsync();
                    var jsonOptions = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };

                    // swagger_v2.json:
                    // GET /api/events/{eventId}/attendances -> EventAttendancesListResponseDtoApiResponseDto
                    ApiResponseDto<EventAttendancesListResponseDto>? v2Wrapped = null;
                    try
                    {
                        v2Wrapped = JsonSerializer.Deserialize<ApiResponseDto<EventAttendancesListResponseDto>>(
                            content,
                            jsonOptions);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogDebug(
                            ex,
                            "V2 wrapper parse failed for attendances list. Fallback to legacy shapes. EventId={EventId}",
                            eventId);
                    }

                    if (v2Wrapped != null)
                    {
                        if (v2Wrapped.Success && v2Wrapped.Data != null)
                        {
                            v2Wrapped.Data.Attendances ??= new AttendanceDetailDtoPaginatedResultDto();
                            v2Wrapped.Data.Attendances.Items ??= new List<AttendanceDetailDto>();

                            return ApiResult<EventAttendancesListResponseDto>.SuccessResult(v2Wrapped.Data);
                        }

                        var message = ApiErrorReader.BuildErrorMessage(
                            v2Wrapped.Message ?? "Không thể tải danh sách điểm danh",
                            v2Wrapped.Errors);
                        return ApiResult<EventAttendancesListResponseDto>.FailureResult(message);
                    }

                    // Legacy fallback (v1 wrapper)
                    ApiResponseDto<AttendanceListResponseDto>? v1Wrapped = null;
                    try
                    {
                        v1Wrapped = JsonSerializer.Deserialize<ApiResponseDto<AttendanceListResponseDto>>(
                            content,
                            jsonOptions);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogDebug(
                            ex,
                            "V1 wrapper parse failed for attendances list. Fallback to direct list parsing. EventId={EventId}",
                            eventId);
                    }

                    if (v1Wrapped != null)
                    {
                        if (v1Wrapped.Success && v1Wrapped.Data != null)
                        {
                            var list = v1Wrapped.Data.Attendances ?? new List<AttendanceDetailDto>();
                            var legacyTotalPages = (int)Math.Ceiling(v1Wrapped.Data.TotalRecords / (double)(pageSize <= 0 ? 10 : pageSize));
                            legacyTotalPages = Math.Max(1, legacyTotalPages);

                            return ApiResult<EventAttendancesListResponseDto>.SuccessResult(
                                new EventAttendancesListResponseDto
                                {
                                    EventId = eventId,
                                    Summary = new EventAttendancesSummaryDto
                                    {
                                        TotalRecords = v1Wrapped.Data.TotalRecords,
                                        ValidCount = v1Wrapped.Data.ValidCount,
                                        InvalidCount = v1Wrapped.Data.InvalidCount
                                    },
                                    Attendances = new AttendanceDetailDtoPaginatedResultDto
                                    {
                                        Items = list,
                                        TotalCount = v1Wrapped.Data.TotalRecords,
                                        PageNumber = pageNumber <= 0 ? 1 : pageNumber,
                                        PageSize = pageSize <= 0 ? 10 : pageSize,
                                        TotalPages = legacyTotalPages,
                                        HasPreviousPage = (pageNumber <= 0 ? 1 : pageNumber) > 1,
                                        HasNextPage = (pageNumber <= 0 ? 1 : pageNumber) < legacyTotalPages
                                    }
                                });
                        }

                        var message = ApiErrorReader.BuildErrorMessage(
                            v1Wrapped.Message ?? "Không thể tải danh sách điểm danh",
                            v1Wrapped.Errors);
                        return ApiResult<EventAttendancesListResponseDto>.FailureResult(message);
                    }

                    // Legacy fallback (direct list)
                    List<AttendanceDetailDto>? attendances;
                    try
                    {
                        attendances = JsonSerializer.Deserialize<List<AttendanceDetailDto>>(
                            content,
                            jsonOptions);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(
                            ex,
                            "Không thể parse danh sách điểm danh cho event {EventId}. Response: {Content}",
                            eventId,
                            content);
                        return ApiResult<EventAttendancesListResponseDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    attendances ??= new List<AttendanceDetailDto>();

                    var effectivePageNumber = pageNumber <= 0 ? 1 : pageNumber;
                    var effectivePageSize = pageSize <= 0 ? 10 : pageSize;
                    var legacyTotalPages2 = (int)Math.Ceiling(attendances.Count / (double)effectivePageSize);
                    legacyTotalPages2 = Math.Max(1, legacyTotalPages2);

                    var legacyPageItems = attendances
                        .Skip((effectivePageNumber - 1) * effectivePageSize)
                        .Take(effectivePageSize)
                        .ToList();

                    return ApiResult<EventAttendancesListResponseDto>.SuccessResult(
                        new EventAttendancesListResponseDto
                        {
                            EventId = eventId,
                            Summary = null,
                            Attendances = new AttendanceDetailDtoPaginatedResultDto
                            {
                                Items = legacyPageItems,
                                TotalCount = attendances.Count,
                                PageNumber = effectivePageNumber,
                                PageSize = effectivePageSize,
                                TotalPages = legacyTotalPages2,
                                HasPreviousPage = effectivePageNumber > 1,
                                HasNextPage = effectivePageNumber < legacyTotalPages2
                            }
                        });
                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<EventAttendancesListResponseDto>.FailureResult("Không tìm thấy sự kiện");
                }

                _logger.LogWarning(
                    "Không thể lấy danh sách điểm danh. Status: {Status}",
                    response.StatusCode);

                var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(
                    response,
                    "Không thể tải danh sách điểm danh");

                return ApiResult<EventAttendancesListResponseDto>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy danh sách điểm danh cho sự kiện {EventId}", eventId);
                return ApiResult<EventAttendancesListResponseDto>.FailureResult("Đã xảy ra lỗi khi tải danh sách điểm danh");
            }
        }

        /// <summary>
        /// Lấy thống kê điểm danh của sự kiện
        /// GET: /api/events/{eventId}/attendance-stats
        /// </summary>
        public async Task<ApiResult<EventAttendanceStatsDto>> GetAttendanceStatsAsync(int eventId)
        {
            try
            {
                _logger.LogInformation("Đang lấy thống kê điểm danh cho sự kiện {EventId}", eventId);

                // Thêm Authorization header
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync($"api/events/{eventId}/attendance-stats");

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<EventAttendanceStatsDto>? apiResponse;
                    try
                    {
                        apiResponse = await ApiResponseReader.ReadAsync<EventAttendanceStatsDto>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse EventAttendanceStatsDtoApiResponseDto cho event {EventId}", eventId);
                        return ApiResult<EventAttendanceStatsDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (apiResponse?.Success == true && apiResponse.Data != null)
                    {
                        return ApiResult<EventAttendanceStatsDto>.SuccessResult(apiResponse.Data);
                    }

                    return ApiResult<EventAttendanceStatsDto>.FailureResult(
                        ApiErrorReader.BuildErrorMessage(
                            apiResponse?.Message ?? "Không thể tải thống kê điểm danh",
                            apiResponse?.Errors));

                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<EventAttendanceStatsDto>.FailureResult(
                        "Không tìm thấy sự kiện");
                }

                var message = await ApiErrorReader.ReadErrorMessageAsync(
                    response,
                    "Không thể tải thống kê điểm danh");

                return ApiResult<EventAttendanceStatsDto>.FailureResult(message);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy thống kê điểm danh cho sự kiện {EventId}", eventId);
                return ApiResult<EventAttendanceStatsDto>.FailureResult(
                    "Đã xảy ra lỗi khi tải thống kê");
            }
        }

        /// <summary>
        /// Lấy thông tin chi tiết sự kiện
        /// GET: /api/Events/{eventId}
        /// </summary>
        public async Task<ApiResult<EventDetailDto>> GetEventDetailAsync(int eventId)
        {
            try
            {
                _logger.LogInformation("Đang lấy thông tin sự kiện {EventId}", eventId);

                // Thêm Authorization header
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync($"api/Events/{eventId}");

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<EventDetailDto>? apiResponse;
                    try
                    {
                        apiResponse = await ApiResponseReader.ReadAsync<EventDetailDto>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse EventDetailDtoApiResponseDto cho event {EventId}", eventId);
                        return ApiResult<EventDetailDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (apiResponse?.Success == true && apiResponse.Data != null)
                    {
                        return ApiResult<EventDetailDto>.SuccessResult(apiResponse.Data);
                    }

                    return ApiResult<EventDetailDto>.FailureResult(
                        apiResponse?.Message ?? "Không thể tải thông tin sự kiện");
                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<EventDetailDto>.FailureResult("Không tìm thấy sự kiện");
                }

                return ApiResult<EventDetailDto>.FailureResult(
                    "Không thể tải thông tin sự kiện");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy thông tin sự kiện {EventId}", eventId);
                return ApiResult<EventDetailDto>.FailureResult(
                    "Đã xảy ra lỗi khi tải thông tin sự kiện");
            }
        }
    }
}

