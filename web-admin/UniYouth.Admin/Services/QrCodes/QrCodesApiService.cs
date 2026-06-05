using System.Net.Http;
using System.Text;
using System.Text.Json;
using Microsoft.AspNetCore.WebUtilities;
using UniYouth.Admin.Models.DTOs.Events.Responses;
using UniYouth.Admin.Models.DTOs.QrCodes;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.QrCodes
{
    /// <summary>
    /// Service xử lý các thao tác liên quan đến QR Codes
    /// Kế thừa từ ApiClientBase để tự động xử lý JWT token
    /// 
    /// QR CODE LIFECYCLE:
    /// 1. Generate: Admin tạo QR code với thời gian hiệu lực
    /// 2. Active: QR code sẵn sàng để scan (trong khoảng ValidFrom - ValidUntil)
    /// 3. Scanning: Users scan QR để điểm danh (xử lý bởi mobile app/attendance system)
    /// 4. Deactivate: Admin có thể vô hiệu hóa QR trước khi hết hạn
    /// 5. Expired: QR tự động hết hiệu lực khi qua ValidUntil
    /// 
    /// INTERACTION VỚI ATTENDANCE:
    /// - QR Code chứa token để validate attendance check-in
    /// - Khi user scan QR, backend verify token và tạo attendance record
    /// - Admin web chỉ quản lý QR lifecycle, không xử lý scanning
    /// - CurrentScans được backend tự động tăng khi có người scan thành công
    /// </summary>
    public class QrCodesApiService : ApiClientBase, IQrCodesApiService
    {
        private readonly ILogger<QrCodesApiService> _logger;
        private readonly IConfiguration _configuration;

        public QrCodesApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<QrCodesApiService> logger,
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
        /// Lấy danh sách QR codes của sự kiện
        /// GET: /api/events/{eventId}/qrcode
        /// </summary>
        public async Task<ApiResult<EventQrListItemDtoPaginatedResultDto>> GetEventQrCodesAsync(
            int eventId,
            int pageNumber = 1,
            int pageSize = 10,
            bool? isActive = null,
            bool? validNow = null)
        {
            try
            {
                _logger.LogInformation("Đang lấy danh sách QR codes cho sự kiện {EventId}", eventId);

                // Thêm Authorization header
                AddAuthorizationHeader();

                var query = new Dictionary<string, string?>
                {
                    ["PageNumber"] = (pageNumber <= 0 ? 1 : pageNumber).ToString(),
                    ["PageSize"] = (pageSize <= 0 ? 10 : pageSize).ToString()
                };

                if (isActive.HasValue)
                {
                    query["IsActive"] = isActive.Value ? "true" : "false";
                }

                if (validNow.HasValue)
                {
                    query["ValidNow"] = validNow.Value ? "true" : "false";
                }

                var endpoint = QueryHelpers.AddQueryString($"api/events/{eventId}/qrcode", query);
                var response = await _httpClient.GetAsync(endpoint);

                if (response.IsSuccessStatusCode)
                {
                    var content = await response.Content.ReadAsStringAsync();
                    var jsonOptions = new JsonSerializerOptions { PropertyNameCaseInsensitive = true };

                    // swagger_v2.json:
                    // GET /api/events/{eventId}/qrcode -> EventQrListItemDtoPaginatedResultDtoApiResponseDto
                    // data: { items: [...], totalCount, pageNumber, pageSize, totalPages, hasPreviousPage, hasNextPage }
                    ApiResponseDto<EventQrListItemDtoPaginatedResultDto>? v2Wrapped = null;
                    try
                    {
                        v2Wrapped = JsonSerializer.Deserialize<ApiResponseDto<EventQrListItemDtoPaginatedResultDto>>(
                            content,
                            jsonOptions);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogDebug(
                            ex,
                            "V2 wrapper parse failed for QR list. Fallback to legacy shapes. EventId={EventId}",
                            eventId);
                    }

                    if (v2Wrapped != null)
                    {
                        if (v2Wrapped.Success && v2Wrapped.Data != null)
                        {
                            v2Wrapped.Data.Items ??= new List<EventQrListItemDto>();
                            _logger.LogInformation(
                                "Đã tải {Count} QR codes cho sự kiện {EventId}. TotalCount={TotalCount} (v2 wrapper)",
                                v2Wrapped.Data.Items.Count,
                                eventId,
                                v2Wrapped.Data.TotalCount);
                            return ApiResult<EventQrListItemDtoPaginatedResultDto>.SuccessResult(v2Wrapped.Data);
                        }

                        var message = ApiErrorReader.BuildErrorMessage(
                            v2Wrapped.Message ?? "Không thể tải danh sách QR codes",
                            v2Wrapped.Errors);
                        return ApiResult<EventQrListItemDtoPaginatedResultDto>.FailureResult(message);
                    }

                    // Legacy wrapper (v1)
                    ApiResponseDto<List<EventQrListItemDto>>? v1Wrapped = null;
                    try
                    {
                        v1Wrapped = JsonSerializer.Deserialize<ApiResponseDto<List<EventQrListItemDto>>>(
                            content,
                            jsonOptions);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogDebug(
                            ex,
                            "V1 wrapper parse failed for QR list. Fallback to direct list parsing. EventId={EventId}",
                            eventId);
                    }

                    if (v1Wrapped != null)
                    {
                        if (v1Wrapped.Success && v1Wrapped.Data != null)
                        {
                            var items = v1Wrapped.Data;
                            var effectivePageNumber = pageNumber <= 0 ? 1 : pageNumber;
                            var effectivePageSize = pageSize <= 0 ? 10 : pageSize;
                            var totalPages = (int)Math.Ceiling(items.Count / (double)effectivePageSize);
                            totalPages = Math.Max(1, totalPages);

                            var pageItems = items
                                .Skip((effectivePageNumber - 1) * effectivePageSize)
                                .Take(effectivePageSize)
                                .ToList();

                            return ApiResult<EventQrListItemDtoPaginatedResultDto>.SuccessResult(
                                new EventQrListItemDtoPaginatedResultDto
                                {
                                    Items = pageItems,
                                    TotalCount = items.Count,
                                    PageNumber = effectivePageNumber,
                                    PageSize = effectivePageSize,
                                    TotalPages = totalPages,
                                    HasPreviousPage = effectivePageNumber > 1,
                                    HasNextPage = effectivePageNumber < totalPages
                                });
                        }

                        var message = ApiErrorReader.BuildErrorMessage(
                            v1Wrapped.Message ?? "Không thể tải danh sách QR codes",
                            v1Wrapped.Errors);
                        return ApiResult<EventQrListItemDtoPaginatedResultDto>.FailureResult(message);
                    }

                    List<EventQrListItemDto>? qrCodes;
                    try
                    {
                        // Swagger: GET /api/events/{eventId}/qrcode trả về EventQrListItemDto[]
                        qrCodes = JsonSerializer.Deserialize<List<EventQrListItemDto>>(
                            content,
                            jsonOptions);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(
                            ex,
                            "Không thể parse danh sách QR codes cho event {EventId}. Response: {Content}",
                            eventId,
                            content);
                        return ApiResult<EventQrListItemDtoPaginatedResultDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    qrCodes ??= new List<EventQrListItemDto>();
                    var effectivePageNumber2 = pageNumber <= 0 ? 1 : pageNumber;
                    var effectivePageSize2 = pageSize <= 0 ? 10 : pageSize;
                    var totalPages2 = (int)Math.Ceiling(qrCodes.Count / (double)effectivePageSize2);
                    totalPages2 = Math.Max(1, totalPages2);

                    var pageItems2 = qrCodes
                        .Skip((effectivePageNumber2 - 1) * effectivePageSize2)
                        .Take(effectivePageSize2)
                        .ToList();

                    return ApiResult<EventQrListItemDtoPaginatedResultDto>.SuccessResult(
                        new EventQrListItemDtoPaginatedResultDto
                        {
                            Items = pageItems2,
                            TotalCount = qrCodes.Count,
                            PageNumber = effectivePageNumber2,
                            PageSize = effectivePageSize2,
                            TotalPages = totalPages2,
                            HasPreviousPage = effectivePageNumber2 > 1,
                            HasNextPage = effectivePageNumber2 < totalPages2
                        });

                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<EventQrListItemDtoPaginatedResultDto>.FailureResult(
                        "Không tìm thấy sự kiện");
                }

                _logger.LogWarning(
                    "Không thể lấy QR codes. Status: {Status}",
                    response.StatusCode);

                var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(
                    response,
                    "Không thể tải danh sách QR codes");

                _logger.LogWarning(
                    "Không thể lấy danh sách QR codes. Status: {Status}. Message: {Message}",
                    response.StatusCode,
                    errorMessage);

                return ApiResult<EventQrListItemDtoPaginatedResultDto>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy danh sách QR codes cho sự kiện {EventId}", eventId);
                return ApiResult<EventQrListItemDtoPaginatedResultDto>.FailureResult(
                    "Đã xảy ra lỗi khi tải danh sách QR codes");
            }
        }

        /// <summary>
        /// Tạo QR code mới cho sự kiện
        /// POST: /api/events/{eventId}/qrcode
        /// 
        /// QR code được tạo sẽ chứa unique token để validate attendance
        /// Backend tự động generate token, admin chỉ cần chỉ định thời gian hiệu lực
        /// </summary>
        public async Task<ApiResult<EventQrResponseDto>> GenerateQrCodeAsync(
            int eventId,
            GenerateEventQrRequestDto request)
        {
            try
            {
                _logger.LogInformation(
                    "Đang tạo QR code cho sự kiện {EventId}. ValidFrom: {From}, ValidUntil: {Until}",
                    eventId,
                    request.ValidFrom,
                    request.ValidUntil);

                // Thêm Authorization header
                AddAuthorizationHeader();

                // Serialize request
                var json = JsonSerializer.Serialize(request, new JsonSerializerOptions
                {
                    PropertyNamingPolicy = JsonNamingPolicy.CamelCase
                });

                var content = new StringContent(json, Encoding.UTF8, "application/json");

                var response = await _httpClient.PostAsync(
                    $"api/events/{eventId}/qrcode",
                    content);

                if (response.IsSuccessStatusCode)
                {
                    var responseContent = await response.Content.ReadAsStringAsync();
                    EventQrResponseDto? qrResponse;
                    try
                    {
                        // Swagger: POST /api/events/{eventId}/qrcode trả về EventQrResponseDto (không wrapper)
                        qrResponse = JsonSerializer.Deserialize<EventQrResponseDto>(
                            responseContent,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex,
                            "Không thể parse EventQrResponseDto cho event {EventId}. Response: {Content}",
                            eventId,
                            responseContent);

                        return ApiResult<EventQrResponseDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (qrResponse == null)
                    {
                        return ApiResult<EventQrResponseDto>.FailureResult("Không thể tạo QR code");
                    }

                    _logger.LogInformation(
                        "Đã tạo QR code {QrId} cho sự kiện {EventId}",
                        qrResponse.Qrid,
                        eventId);

                    return ApiResult<EventQrResponseDto>.SuccessResult(qrResponse);
                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<EventQrResponseDto>.FailureResult(
                        "Không tìm thấy sự kiện");
                }

                if (response.StatusCode == System.Net.HttpStatusCode.BadRequest)
                {
                    var errorContent = await response.Content.ReadAsStringAsync();
                    _logger.LogWarning(
                        "Tạo QR code thất bại. BadRequest: {Error}",
                        errorContent);

                    try
                    {
                        var envelope = JsonSerializer.Deserialize<ApiResponseDto>(
                            errorContent,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

                        if (!string.IsNullOrWhiteSpace(envelope?.Message))
                        {
                            var message = ApiErrorReader.BuildErrorMessage(
                                envelope!.Message!,
                                envelope.Errors);
                            return ApiResult<EventQrResponseDto>.FailureResult(message);
                        }
                    }
                    catch (JsonException)
                    {
                        // ignore parse errors and fallback to generic message below
                    }

                    return ApiResult<EventQrResponseDto>.FailureResult(
                        "Dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin.");
                }

                _logger.LogWarning(
                    "Tạo QR code thất bại. Status: {Status}",
                    response.StatusCode);

                return ApiResult<EventQrResponseDto>.FailureResult(
                    "Không thể tạo QR code. Vui lòng thử lại.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tạo QR code cho sự kiện {EventId}", eventId);
                return ApiResult<EventQrResponseDto>.FailureResult(
                    "Đã xảy ra lỗi khi tạo QR code");
            }
        }

        /// <summary>
        /// Vô hiệu hóa QR code
        /// PUT: /api/events/qrcode/{qrId}/deactivate
        /// 
        /// Deactivate được sử dụng khi:
        /// - Admin muốn ngừng cho phép check-in trước thời gian hết hạn
        /// - QR bị lộ hoặc cần thay thế
        /// - Sự kiện kết thúc sớm
        /// 
        /// Sau khi deactivate, QR không thể được reactivate
        /// </summary>
        public async Task<ApiResult<DeactivateQrResponseDto>> DeactivateQrCodeAsync(int qrId)
        {
            try
            {
                _logger.LogInformation("Đang deactivate QR code {QrId}", qrId);

                // Thêm Authorization header
                AddAuthorizationHeader();

                var response = await _httpClient.PutAsync(
                    $"api/events/qrcode/{qrId}/deactivate",
                    null);

                if (response.IsSuccessStatusCode)
                {
                    var responseContent = await response.Content.ReadAsStringAsync();
                    DeactivateQrResponseDto? result;
                    try
                    {
                        // Swagger: PUT /api/events/qrcode/{qrId}/deactivate trả về DeactivateQrResponseDto (không wrapper)
                        result = JsonSerializer.Deserialize<DeactivateQrResponseDto>(
                            responseContent,
                            new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex,
                            "Không thể parse DeactivateQrResponseDto cho qrId {QrId}. Response: {Content}",
                            qrId,
                            responseContent);
                        return ApiResult<DeactivateQrResponseDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (result == null)
                    {
                        return ApiResult<DeactivateQrResponseDto>.FailureResult("Không thể vô hiệu hóa QR code");
                    }

                    _logger.LogInformation("Đã deactivate QR code {QrId}", qrId);
                    return ApiResult<DeactivateQrResponseDto>.SuccessResult(result);

                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<DeactivateQrResponseDto>.FailureResult(
                        "Không tìm thấy QR code");
                }

                if (response.StatusCode == System.Net.HttpStatusCode.BadRequest)
                {
                    var message = await ApiErrorReader.ReadErrorMessageAsync(
                        response,
                        "QR code đã bị vô hiệu hóa hoặc đã hết hạn");
                    return ApiResult<DeactivateQrResponseDto>.FailureResult(message);
                }

                _logger.LogWarning(
                    "Deactivate QR code thất bại. Status: {Status}",
                    response.StatusCode);

                return ApiResult<DeactivateQrResponseDto>.FailureResult(
                    "Không thể vô hiệu hóa QR code");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi deactivate QR code {QrId}", qrId);
                return ApiResult<DeactivateQrResponseDto>.FailureResult(
                    "Đã xảy ra lỗi khi vô hiệu hóa QR code");
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

        /// <summary>
        /// Xem chi tiết QR code
        /// GET: /api/events/qrcode/{qrId}
        /// </summary>
        public async Task<ApiResult<QrCodeDetailResponseDto>> GetQrCodeDetailAsync(int qrId)
        {
            try
            {
                _logger.LogInformation("Đang lấy chi tiết QR code {QrId}", qrId);

                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync($"api/events/qrcode/{qrId}");

                if (response.IsSuccessStatusCode)
                {
                    ApiResponseDto<QrCodeDetailResponseDto>? apiResponse;
                    try
                    {
                        apiResponse = await ApiResponseReader.ReadAsync<QrCodeDetailResponseDto>(response);
                    }
                    catch (JsonException ex)
                    {
                        _logger.LogError(ex, "Không thể parse QrCodeDetailResponseDtoApiResponseDto cho qrId {QrId}", qrId);
                        return ApiResult<QrCodeDetailResponseDto>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                    }

                    if (apiResponse?.Success == true && apiResponse.Data != null)
                    {
                        return ApiResult<QrCodeDetailResponseDto>.SuccessResult(apiResponse.Data);
                    }

                    return ApiResult<QrCodeDetailResponseDto>.FailureResult(
                        apiResponse?.Message ?? "Không thể tải chi tiết QR code");
                }

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
                {
                    return ApiResult<QrCodeDetailResponseDto>.FailureResult("Không tìm thấy QR code");
                }

                var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(
                    response,
                    "Không thể tải chi tiết QR code");
                return ApiResult<QrCodeDetailResponseDto>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy chi tiết QR code {QrId}", qrId);
                return ApiResult<QrCodeDetailResponseDto>.FailureResult(
                    "Đã xảy ra lỗi khi tải chi tiết QR code");
            }
        }
    }

}
