using System.Text;
using System.Text.Json;
using UniYouth.Admin.Models.DTOs.SupportChat;
using UniYouth.Admin.Services.Base;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.SupportChat
{
    public class SupportChatApiService : ApiClientBase, ISupportChatApiService
    {
        private readonly ILogger<SupportChatApiService> _logger;

        private static readonly JsonSerializerOptions JsonOptions = new()
        {
            PropertyNameCaseInsensitive = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        };

        public SupportChatApiService(
            HttpClient httpClient,
            IHttpContextAccessor httpContextAccessor,
            ILogger<SupportChatApiService> logger,
            IConfiguration configuration)
            : base(httpClient, httpContextAccessor)
        {
            _logger = logger;

            var baseUrl = configuration["ApiSettings:BaseUrl"];
            if (string.IsNullOrWhiteSpace(baseUrl))
            {
                throw new InvalidOperationException("API Base URL chưa được cấu hình");
            }

            _httpClient.BaseAddress = new Uri(baseUrl);
            _httpClient.Timeout = TimeSpan.FromSeconds(30);
        }

        public async Task<ApiResult<SupportConversationDtoPaginatedResultDto>> GetConversationsAsync(
            int pageNumber = 1,
            int pageSize = 20,
            byte? status = null,
            byte? priority = null,
            int? assignedToUserId = null,
            string? search = null)
        {
            try
            {
                AddAuthorizationHeader();

                var query = new List<string>
                {
                    $"pageNumber={Math.Max(1, pageNumber)}",
                    $"pageSize={Math.Clamp(pageSize, 1, 100)}"
                };

                if (status.HasValue) query.Add($"status={status.Value}");
                if (priority.HasValue) query.Add($"priority={priority.Value}");
                if (assignedToUserId.HasValue) query.Add($"assignedToUserId={assignedToUserId.Value}");
                if (!string.IsNullOrWhiteSpace(search)) query.Add($"search={Uri.EscapeDataString(search.Trim())}");

                var response = await _httpClient.GetAsync("/api/support-chat/conversations?" + string.Join("&", query));
                return await ReadTypedAsync<SupportConversationDtoPaginatedResultDto>(response, "Không thể tải danh sách hỗ trợ sinh viên.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải danh sách hỗ trợ sinh viên.");
                return ApiResult<SupportConversationDtoPaginatedResultDto>.FailureResult("Đã xảy ra lỗi khi tải danh sách hỗ trợ sinh viên.");
            }
        }

        public async Task<ApiResult<SupportConversationDto>> GetConversationAsync(int conversationId)
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync($"/api/support-chat/conversations/{conversationId}");
                return await ReadTypedAsync<SupportConversationDto>(response, "Không thể tải chi tiết hỗ trợ.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải chi tiết hỗ trợ ConversationID={ConversationId}.", conversationId);
                return ApiResult<SupportConversationDto>.FailureResult("Đã xảy ra lỗi khi tải chi tiết hỗ trợ.");
            }
        }

        public async Task<ApiResult<SupportMessageDtoPaginatedResultDto>> GetMessagesAsync(
            int conversationId,
            int pageNumber = 1,
            int pageSize = 100)
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.GetAsync(
                    $"/api/support-chat/conversations/{conversationId}/messages?pageNumber={Math.Max(1, pageNumber)}&pageSize={Math.Clamp(pageSize, 1, 100)}");

                return await ReadTypedAsync<SupportMessageDtoPaginatedResultDto>(response, "Không thể tải tin nhắn hỗ trợ.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải tin nhắn hỗ trợ ConversationID={ConversationId}.", conversationId);
                return ApiResult<SupportMessageDtoPaginatedResultDto>.FailureResult("Đã xảy ra lỗi khi tải tin nhắn hỗ trợ.");
            }
        }

        public async Task<ApiResult<SupportMessageDto>> SendMessageAsync(int conversationId, SendSupportMessageRequestDto request)
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.PostAsync(
                    $"/api/support-chat/conversations/{conversationId}/messages",
                    CreateJsonContent(request));

                return await ReadTypedAsync<SupportMessageDto>(response, "Không thể gửi tin nhắn hỗ trợ.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi gửi tin nhắn hỗ trợ ConversationID={ConversationId}.", conversationId);
                return ApiResult<SupportMessageDto>.FailureResult("Đã xảy ra lỗi khi gửi tin nhắn hỗ trợ.");
            }
        }

        public async Task<ApiResult<SupportMessageDto>> SendAttachmentAsync(int conversationId, string? content, IFormFile file)
        {
            try
            {
                AddAuthorizationHeader();

                await using var fileStream = file.OpenReadStream();
                using var form = new MultipartFormDataContent();
                if (!string.IsNullOrWhiteSpace(content))
                {
                    form.Add(new StringContent(content.Trim(), Encoding.UTF8), "Content");
                }

                var fileContent = new StreamContent(fileStream);
                if (!string.IsNullOrWhiteSpace(file.ContentType))
                {
                    fileContent.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(file.ContentType);
                }
                form.Add(fileContent, "File", file.FileName);

                var response = await _httpClient.PostAsync(
                    $"/api/support-chat/conversations/{conversationId}/attachments",
                    form);

                return await ReadTypedAsync<SupportMessageDto>(response, "Không thể gửi file minh chứng.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi gửi file minh chứng ConversationID={ConversationId}.", conversationId);
                return ApiResult<SupportMessageDto>.FailureResult("Đã xảy ra lỗi khi gửi file minh chứng.");
            }
        }

        public async Task<ApiResult<SupportConversationDto>> AssignConversationAsync(int conversationId, AssignSupportConversationRequestDto request)
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.PutAsync(
                    $"/api/support-chat/conversations/{conversationId}/assign",
                    CreateJsonContent(request));

                return await ReadTypedAsync<SupportConversationDto>(response, "Không thể phân công yêu cầu hỗ trợ.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi phân công hỗ trợ ConversationID={ConversationId}.", conversationId);
                return ApiResult<SupportConversationDto>.FailureResult("Đã xảy ra lỗi khi phân công yêu cầu hỗ trợ.");
            }
        }

        public async Task<ApiResult<SupportConversationDto>> UpdateStatusAsync(int conversationId, UpdateSupportConversationStatusRequestDto request)
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.PutAsync(
                    $"/api/support-chat/conversations/{conversationId}/status",
                    CreateJsonContent(request));

                return await ReadTypedAsync<SupportConversationDto>(response, "Không thể cập nhật trạng thái hỗ trợ.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật trạng thái hỗ trợ ConversationID={ConversationId}.", conversationId);
                return ApiResult<SupportConversationDto>.FailureResult("Đã xảy ra lỗi khi cập nhật trạng thái hỗ trợ.");
            }
        }

        public async Task<ApiResult<string?>> MarkAsReadAsync(int conversationId)
        {
            try
            {
                AddAuthorizationHeader();

                var response = await _httpClient.PostAsync($"/api/support-chat/conversations/{conversationId}/read", null);
                if (response.IsSuccessStatusCode)
                {
                    return ApiResult<string?>.SuccessResult(null, "Đã đánh dấu tin nhắn là đã đọc.");
                }

                var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(response, "Không thể đánh dấu đã đọc.");
                return ApiResult<string?>.FailureResult(errorMessage);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi đánh dấu đã đọc ConversationID={ConversationId}.", conversationId);
                return ApiResult<string?>.FailureResult("Đã xảy ra lỗi khi đánh dấu đã đọc.");
            }
        }

        private static StringContent CreateJsonContent<T>(T request)
        {
            var json = JsonSerializer.Serialize(request, JsonOptions);
            return new StringContent(json, Encoding.UTF8, "application/json");
        }

        private async Task<ApiResult<T>> ReadTypedAsync<T>(HttpResponseMessage response, string fallbackMessage)
        {
            if (response.IsSuccessStatusCode)
            {
                ApiResponseDto<T>? apiResponse;
                try
                {
                    apiResponse = await ApiResponseReader.ReadAsync<T>(response);
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse API response cho {DtoType}.", typeof(T).Name);
                    return ApiResult<T>.FailureResult("Lỗi xử lý dữ liệu từ server.");
                }

                if (apiResponse?.Success == true && apiResponse.Data != null)
                {
                    return ApiResult<T>.SuccessResult(apiResponse.Data, apiResponse.Message ?? string.Empty);
                }

                var message = ApiErrorReader.BuildErrorMessage(apiResponse?.Message ?? fallbackMessage, apiResponse?.Errors);
                return ApiResult<T>.FailureResult(message);
            }

            var errorMessage = await ApiErrorReader.ReadErrorMessageAsync(response, fallbackMessage);
            return ApiResult<T>.FailureResult(errorMessage);
        }
    }
}
