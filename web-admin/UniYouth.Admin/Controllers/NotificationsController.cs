using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Admin.Models.DTOs.Notifications;
using UniYouth.Admin.Models.ViewModels.Notifications;
using UniYouth.Admin.Services.Common;
using UniYouth.Admin.Services.Notifications;

namespace UniYouth.Admin.Controllers
{
    public class NotificationsController : BaseController
    {
        private static readonly string[] AllowedActionRoutePrefixes =
        {
            "/account",
            "/attendance",
            "/events",
            "/home",
            "/notifications",
            "/points",
            "/qrcodes",
            "/registrations",
            "/reports",
            "/roles",
            "/support-chat",
            "/units",
            "/users"
        };

        private readonly INotificationApiService _notificationApiService;
        private readonly ILogger<NotificationsController> _logger;

        public NotificationsController(
            INotificationApiService notificationApiService,
            ILogger<NotificationsController> logger)
        {
            _notificationApiService = notificationApiService;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> Index(
            int pageNumber = 1,
            int pageSize = 20,
            bool? isRead = null,
            int? priority = null,
            string? q = null)
        {
            if (pageNumber < 1) pageNumber = 1;
            if (pageSize < 1) pageSize = 20;

            var viewModel = new NotificationListViewModel
            {
                PageNumber = pageNumber,
                PageSize = pageSize,
                IsRead = isRead,
                Priority = priority,
                Query = string.IsNullOrWhiteSpace(q) ? null : q.Trim()
            };

            try
            {
                var apiResult = await _notificationApiService.GetNotificationsAsync(pageNumber, pageSize);
                if (!apiResult.Success || apiResult.Data == null)
                {
                    SetErrorMessage(apiResult.ErrorMessage ?? "Không thể tải danh sách thông báo.");
                    return View(viewModel);
                }

                if (!apiResult.Data.Data.HasValue)
                {
                    SetErrorMessage(apiResult.Data.Message ?? "Không thể tải dữ liệu thông báo.");
                    return View(viewModel);
                }

                NotificationListResponseDto? data;
                try
                {
                    data = JsonSerializer.Deserialize<NotificationListResponseDto>(
                        apiResult.Data.Data.Value.GetRawText(),
                        new JsonSerializerOptions { PropertyNameCaseInsensitive = true });
                }
                catch (JsonException ex)
                {
                    _logger.LogError(ex, "Không thể parse NotificationListResponseDto từ API.");
                    SetErrorMessage("Lỗi xử lý dữ liệu thông báo từ server.");
                    return View(viewModel);
                }

                if (data == null)
                {
                    SetErrorMessage("Không thể tải dữ liệu thông báo.");
                    return View(viewModel);
                }

                viewModel.Notifications = (data.Notifications ?? new List<NotificationDto>())
                    .Select(MapToListItemViewModel)
                    .ToList();
                viewModel.TotalCount = data.TotalCount;
                viewModel.PageNumber = data.PageNumber > 0 ? data.PageNumber : pageNumber;
                viewModel.PageSize = data.PageSize > 0 ? data.PageSize : pageSize;
                viewModel.TotalPages = data.TotalPages > 0 ? data.TotalPages : 1;
                viewModel.HasPreviousPage = data.HasPreviousPage;
                viewModel.HasNextPage = data.HasNextPage;
                viewModel.UnreadCount = data.UnreadCount;

                return View(viewModel);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải trang danh sách thông báo.");
                SetErrorMessage("Đã xảy ra lỗi khi tải danh sách thông báo.");
                return View(viewModel);
            }
        }

        [HttpGet("Notifications/ajax/list")]
        public async Task<IActionResult> ListAjax(int pageNumber = 1, int pageSize = 20)
        {
            if (pageNumber < 1) pageNumber = 1;
            if (pageSize < 1) pageSize = 20;

            try
            {
                var apiResult = await _notificationApiService.GetNotificationsAsync(pageNumber, pageSize);
                return BuildAjaxResult(apiResult, "Không thể tải danh sách thông báo.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi gọi endpoint ajax list thông báo.");
                return StatusCode(500, new
                {
                    success = false,
                    message = "Đã xảy ra lỗi khi tải danh sách thông báo."
                });
            }
        }

        [HttpGet("Notifications/ajax/unread-count")]
        public async Task<IActionResult> UnreadCountAjax()
        {
            try
            {
                var apiResult = await _notificationApiService.GetUnreadCountAsync();
                return BuildAjaxResult(apiResult, "Không thể tải số thông báo chưa đọc.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi gọi endpoint ajax unread-count.");
                return StatusCode(500, new
                {
                    success = false,
                    message = "Đã xảy ra lỗi khi tải số thông báo chưa đọc."
                });
            }
        }

        [HttpPut("Notifications/ajax/{id:int}/read")]
        public async Task<IActionResult> MarkReadAjax(int id)
        {
            if (id <= 0)
            {
                return BadRequest(new
                {
                    success = false,
                    message = "ID thông báo không hợp lệ."
                });
            }

            try
            {
                var apiResult = await _notificationApiService.MarkAsReadAsync(id);
                return BuildAjaxResult(apiResult, "Không thể đánh dấu thông báo đã đọc.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi gọi endpoint ajax mark-read id={NotificationId}.", id);
                return StatusCode(500, new
                {
                    success = false,
                    message = "Đã xảy ra lỗi khi đánh dấu thông báo đã đọc."
                });
            }
        }

        [HttpPut("Notifications/ajax/read-all")]
        public async Task<IActionResult> MarkAllReadAjax()
        {
            try
            {
                var apiResult = await _notificationApiService.MarkAllAsReadAsync();
                return BuildAjaxResult(apiResult, "Không thể đánh dấu tất cả thông báo đã đọc.");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi gọi endpoint ajax mark-all-read.");
                return StatusCode(500, new
                {
                    success = false,
                    message = "Đã xảy ra lỗi khi đánh dấu tất cả thông báo đã đọc."
                });
            }
        }

        private static NotificationListItemViewModel MapToListItemViewModel(NotificationDto dto)
        {
            return new NotificationListItemViewModel
            {
                NotificationId = dto.NotificationId,
                Title = dto.Title ?? string.Empty,
                Content = dto.Content ?? string.Empty,
                NotificationType = dto.NotificationType,
                Priority = dto.Priority,
                IsRead = dto.IsRead ?? false,
                ReadDate = dto.ReadDate,
                ActionUrl = SanitizeActionUrl(dto.ActionUrl),
                EventId = dto.EventId,
                EventName = dto.EventName,
                CreatedDate = dto.CreatedDate,
                ExpiryDate = dto.ExpiryDate
            };
        }

        private static string? SanitizeActionUrl(string? actionUrl)
        {
            if (string.IsNullOrWhiteSpace(actionUrl))
            {
                return null;
            }

            var value = actionUrl.Trim();
            if (value.Length > 2048)
            {
                return null;
            }

            if (value.StartsWith("//", StringComparison.Ordinal))
            {
                return null;
            }

            if (value.StartsWith("javascript:", StringComparison.OrdinalIgnoreCase) ||
                value.StartsWith("data:", StringComparison.OrdinalIgnoreCase) ||
                value.StartsWith("vbscript:", StringComparison.OrdinalIgnoreCase))
            {
                return null;
            }

            if (Uri.TryCreate(value, UriKind.Absolute, out _))
            {
                return null;
            }

            if (!value.StartsWith("/", StringComparison.Ordinal))
            {
                return null;
            }

            var pathOnly = value;
            var queryStart = value.IndexOfAny(new[] { '?', '#' });
            if (queryStart >= 0)
            {
                pathOnly = value[..queryStart];
            }

            if (string.IsNullOrWhiteSpace(pathOnly))
            {
                return null;
            }

            pathOnly = pathOnly.TrimEnd('/');
            if (string.IsNullOrWhiteSpace(pathOnly))
            {
                pathOnly = "/";
            }

            if (string.Equals(pathOnly, "/", StringComparison.Ordinal))
            {
                return value;
            }

            var normalizedKnownUrl = NormalizeKnownActionUrl(value, pathOnly);
            if (!string.Equals(normalizedKnownUrl, value, StringComparison.Ordinal))
            {
                value = normalizedKnownUrl;
                pathOnly = value;
                var normalizedQueryStart = value.IndexOfAny(new[] { '?', '#' });
                if (normalizedQueryStart >= 0)
                {
                    pathOnly = value[..normalizedQueryStart];
                }

                pathOnly = pathOnly.TrimEnd('/');
                if (string.IsNullOrWhiteSpace(pathOnly))
                {
                    pathOnly = "/";
                }
            }

            foreach (var prefix in AllowedActionRoutePrefixes)
            {
                if (pathOnly.Equals(prefix, StringComparison.OrdinalIgnoreCase) ||
                    pathOnly.StartsWith(prefix + "/", StringComparison.OrdinalIgnoreCase))
                {
                    return value;
                }
            }

            return null;
        }

        private static string NormalizeKnownActionUrl(string value, string pathOnly)
        {
            if (pathOnly.StartsWith("/events/", StringComparison.OrdinalIgnoreCase))
            {
                var idPart = pathOnly["/events/".Length..];
                if (int.TryParse(idPart, out var eventId) && eventId > 0)
                {
                    var suffixStart = value.IndexOfAny(new[] { '?', '#' });
                    var suffix = suffixStart >= 0 ? value[suffixStart..] : string.Empty;
                    return $"/Events/Details/{eventId}{suffix}";
                }
            }

            return value;
        }

        private IActionResult BuildAjaxResult(
            ApiResult<ApiResponseDto> apiResult,
            string fallbackMessage)
        {
            var envelope = BuildAjaxEnvelope(apiResult, fallbackMessage);
            var statusCode = ExtractStatusCode(apiResult);

            if (statusCode == 401)
            {
                _logger.LogWarning("Notification AJAX unauthorized (401).");
                return StatusCode(401, envelope);
            }

            if (statusCode == 403)
            {
                _logger.LogWarning("Notification AJAX forbidden (403).");
                return StatusCode(403, envelope);
            }

            return Ok(envelope);
        }

        private static object BuildAjaxEnvelope(
            ApiResult<ApiResponseDto> apiResult,
            string fallbackMessage)
        {
            if (apiResult.Success && apiResult.Data != null)
            {
                return new
                {
                    success = true,
                    message = apiResult.Data.Message,
                    data = apiResult.Data.Data
                };
            }

            return new
            {
                success = false,
                message = apiResult.ErrorMessage ?? fallbackMessage,
                data = (object?)null
            };
        }

        private static int? ExtractStatusCode(ApiResult<ApiResponseDto> apiResult)
        {
            if (apiResult.Summary is int statusInt)
            {
                return statusInt;
            }

            if (apiResult.Summary is short statusShort)
            {
                return statusShort;
            }

            if (apiResult.Summary is long statusLong &&
                statusLong >= int.MinValue &&
                statusLong <= int.MaxValue)
            {
                return (int)statusLong;
            }

            return null;
        }
    }
}
