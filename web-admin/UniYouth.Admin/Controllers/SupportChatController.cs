using Microsoft.AspNetCore.Mvc;
using UniYouth.Admin.Helpers;
using UniYouth.Admin.Models.DTOs.SupportChat;
using UniYouth.Admin.Models.ViewModels.SupportChat;
using UniYouth.Admin.Services.SupportChat;

namespace UniYouth.Admin.Controllers
{
    public class SupportChatController : BaseController
    {
        private readonly ISupportChatApiService _supportChatApiService;

        public SupportChatController(ISupportChatApiService supportChatApiService)
        {
            _supportChatApiService = supportChatApiService;
        }

        [HttpGet]
        public IActionResult RealtimeToken()
        {
            if (!Request.Cookies.TryGetValue(AuthCookieHelper.AccessTokenCookieName, out var token)
                || string.IsNullOrWhiteSpace(token))
            {
                return Unauthorized(new { success = false, message = "Phiên đăng nhập không hợp lệ." });
            }

            return Json(new { success = true, token });
        }

        [HttpGet("/support-chat")]
        public async Task<IActionResult> Index(
            int pageNumber = 1,
            int pageSize = 20,
            byte? status = null,
            byte? priority = null,
            int? assignedToUserId = null,
            string? search = null)
        {
            var viewModel = new SupportChatIndexViewModel
            {
                Status = status,
                Priority = priority,
                AssignedToUserId = assignedToUserId,
                Search = string.IsNullOrWhiteSpace(search) ? null : search.Trim()
            };

            var result = await _supportChatApiService.GetConversationsAsync(
                pageNumber,
                pageSize,
                status,
                priority,
                assignedToUserId,
                viewModel.Search);

            if (result.Success && result.Data != null)
            {
                result.Data.Items ??= new List<SupportConversationDto>();
                viewModel.ConversationsPage = result.Data;
                return View(viewModel);
            }

            SetErrorMessage(result.ErrorMessage ?? "Không thể tải danh sách hỗ trợ sinh viên.");
            return View(viewModel);
        }

        [HttpGet("/support-chat/{id:int}")]
        public async Task<IActionResult> Detail(int id, int pageNumber = 1, int pageSize = 100)
        {
            var conversationResult = await _supportChatApiService.GetConversationAsync(id);
            if (!conversationResult.Success || conversationResult.Data == null)
            {
                SetErrorMessage(conversationResult.ErrorMessage ?? "Không thể tải chi tiết hỗ trợ.");
                return RedirectToAction(nameof(Index));
            }

            var messagesResult = await _supportChatApiService.GetMessagesAsync(id, pageNumber, pageSize);
            if (!messagesResult.Success || messagesResult.Data == null)
            {
                SetErrorMessage(messagesResult.ErrorMessage ?? "Không thể tải tin nhắn hỗ trợ.");
                messagesResult.Data = new SupportMessageDtoPaginatedResultDto
                {
                    Items = new List<SupportMessageDto>(),
                    PageNumber = pageNumber,
                    PageSize = pageSize,
                    TotalPages = 1
                };
            }

            await _supportChatApiService.MarkAsReadAsync(id);

            var viewModel = new SupportChatDetailViewModel
            {
                Conversation = conversationResult.Data,
                MessagesPage = messagesResult.Data,
                Assign = new AssignSupportConversationRequestDto
                {
                    AssignedToUserId = conversationResult.Data.AssignedToUserId
                },
                UpdateStatus = new UpdateSupportConversationStatusRequestDto
                {
                    Status = conversationResult.Data.Status
                }
            };

            return View(viewModel);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SendMessage(int conversationId, SupportChatDetailViewModel model)
        {
            if (conversationId <= 0)
            {
                SetErrorMessage("Cuộc trò chuyện không hợp lệ.");
                return RedirectToAction(nameof(Index));
            }

            if (string.IsNullOrWhiteSpace(model.SendMessage.Content))
            {
                SetErrorMessage("Nội dung tin nhắn là bắt buộc.");
                return RedirectToAction(nameof(Detail), new { id = conversationId });
            }

            var result = await _supportChatApiService.SendMessageAsync(conversationId, model.SendMessage);
            if (result.Success)
            {
                SetSuccessMessage("Đã gửi tin nhắn hỗ trợ.");
            }
            else
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể gửi tin nhắn hỗ trợ.");
            }

            return RedirectToAction(nameof(Detail), new { id = conversationId });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> SendAttachment(int conversationId, string? content, IFormFile file)
        {
            if (conversationId <= 0)
            {
                SetErrorMessage("Cuộc trò chuyện không hợp lệ.");
                return RedirectToAction(nameof(Index));
            }

            if (file == null || file.Length == 0)
            {
                SetErrorMessage("Vui lòng chọn file minh chứng.");
                return RedirectToAction(nameof(Detail), new { id = conversationId });
            }

            var result = await _supportChatApiService.SendAttachmentAsync(conversationId, content, file);
            if (result.Success)
            {
                SetSuccessMessage("Đã gửi file minh chứng.");
            }
            else
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể gửi file minh chứng.");
            }

            return RedirectToAction(nameof(Detail), new { id = conversationId });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Assign(int conversationId, SupportChatDetailViewModel model)
        {
            var accessDenied = RequireAdmin();
            if (accessDenied != null)
            {
                return accessDenied;
            }

            var result = await _supportChatApiService.AssignConversationAsync(conversationId, model.Assign);
            if (result.Success)
            {
                SetSuccessMessage("Đã phân công yêu cầu hỗ trợ.");
            }
            else
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể phân công yêu cầu hỗ trợ.");
            }

            return RedirectToAction(nameof(Detail), new { id = conversationId });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateStatus(int conversationId, SupportChatDetailViewModel model)
        {
            var result = await _supportChatApiService.UpdateStatusAsync(conversationId, model.UpdateStatus);
            if (result.Success)
            {
                SetSuccessMessage("Đã cập nhật trạng thái hỗ trợ.");
            }
            else
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể cập nhật trạng thái hỗ trợ.");
            }

            return RedirectToAction(nameof(Detail), new { id = conversationId });
        }
    }
}
