using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.SupportChat;
using UniYouth.Api.Shared.Constants;
using UniYouth.Api.Shared.Extensions;

namespace UniYouth.Api.Controllers
{
    [ApiController]
    [Route("api/support-chat")]
    [Authorize]
    [Produces("application/json")]
    public class SupportChatController : ControllerBase
    {
        private readonly ISupportChatService _supportChatService;
        private readonly IWebHostEnvironment _environment;

        public SupportChatController(
            ISupportChatService supportChatService,
            IWebHostEnvironment environment)
        {
            _supportChatService = supportChatService;
            _environment = environment;
        }

        [HttpPost("conversations")]
        [Authorize(Roles = RoleNames.DoanVien + "," + RoleNames.HoiVien)]
        [ProducesResponseType(typeof(ApiResponseDto<SupportConversationDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> CreateConversation(
            [FromBody] CreateSupportConversationRequestDto request,
            CancellationToken cancellationToken)
        {
            var userId = User.GetUserId();
            var result = await _supportChatService.CreateConversationAsync(userId, request, cancellationToken);

            return Ok(new ApiResponseDto<SupportConversationDto>
            {
                Success = true,
                Message = "Tạo yêu cầu hỗ trợ thành công",
                Data = result
            });
        }

        [HttpGet("conversations/my")]
        [Authorize(Roles = RoleNames.DoanVien + "," + RoleNames.HoiVien)]
        [ProducesResponseType(typeof(ApiResponseDto<PaginatedResultDto<SupportConversationDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetMyConversations(
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 20,
            CancellationToken cancellationToken = default)
        {
            var userId = User.GetUserId();
            var result = await _supportChatService.GetMyConversationsAsync(userId, pageNumber, pageSize, cancellationToken);

            return Ok(new ApiResponseDto<PaginatedResultDto<SupportConversationDto>>
            {
                Success = true,
                Message = "Lấy danh sách yêu cầu hỗ trợ thành công",
                Data = result
            });
        }

        [HttpGet("conversations")]
        [Authorize(Roles = RoleNames.CanBo + "," + RoleNames.Admin)]
        [ProducesResponseType(typeof(ApiResponseDto<PaginatedResultDto<SupportConversationDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetConversations(
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] byte? status = null,
            [FromQuery] byte? priority = null,
            [FromQuery] int? assignedToUserId = null,
            [FromQuery] string? search = null,
            CancellationToken cancellationToken = default)
        {
            var userId = User.GetUserId();
            var result = await _supportChatService.GetAdminConversationsAsync(
                userId,
                pageNumber,
                pageSize,
                status,
                priority,
                assignedToUserId,
                search,
                cancellationToken);

            return Ok(new ApiResponseDto<PaginatedResultDto<SupportConversationDto>>
            {
                Success = true,
                Message = "Lấy danh sách hỗ trợ sinh viên thành công",
                Data = result
            });
        }

        [HttpGet("conversations/{conversationId:int}")]
        [ProducesResponseType(typeof(ApiResponseDto<SupportConversationDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetConversation(int conversationId, CancellationToken cancellationToken)
        {
            var userId = User.GetUserId();
            var result = await _supportChatService.GetConversationAsync(
                conversationId,
                userId,
                IsStaff(),
                cancellationToken);

            return Ok(new ApiResponseDto<SupportConversationDto>
            {
                Success = true,
                Message = "Lấy chi tiết yêu cầu hỗ trợ thành công",
                Data = result
            });
        }

        [HttpGet("conversations/{conversationId:int}/messages")]
        [ProducesResponseType(typeof(ApiResponseDto<PaginatedResultDto<SupportMessageDto>>), StatusCodes.Status200OK)]
        public async Task<IActionResult> GetMessages(
            int conversationId,
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 50,
            CancellationToken cancellationToken = default)
        {
            var userId = User.GetUserId();
            var result = await _supportChatService.GetConversationMessagesAsync(
                conversationId,
                userId,
                IsStaff(),
                pageNumber,
                pageSize,
                cancellationToken);

            return Ok(new ApiResponseDto<PaginatedResultDto<SupportMessageDto>>
            {
                Success = true,
                Message = "Lấy danh sách tin nhắn hỗ trợ thành công",
                Data = result
            });
        }

        [HttpPost("conversations/{conversationId:int}/messages")]
        [ProducesResponseType(typeof(ApiResponseDto<SupportMessageDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> SendMessage(
            int conversationId,
            [FromBody] SendSupportMessageRequestDto request,
            CancellationToken cancellationToken)
        {
            var userId = User.GetUserId();
            var result = await _supportChatService.SendMessageAsync(
                conversationId,
                userId,
                IsStaff(),
                request,
                cancellationToken);

            return Ok(new ApiResponseDto<SupportMessageDto>
            {
                Success = true,
                Message = "Gửi tin nhắn hỗ trợ thành công",
                Data = result
            });
        }

        [HttpPost("conversations/{conversationId:int}/attachments")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(typeof(ApiResponseDto<SupportMessageDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> SendAttachment(
            int conversationId,
            [FromForm] SendSupportAttachmentRequestDto request,
            CancellationToken cancellationToken)
        {
            var userId = User.GetUserId();
            var webRootPath = string.IsNullOrWhiteSpace(_environment.WebRootPath)
                ? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot")
                : _environment.WebRootPath;
            var result = await _supportChatService.SendAttachmentAsync(
                conversationId,
                userId,
                IsStaff(),
                request,
                webRootPath,
                cancellationToken);

            return Ok(new ApiResponseDto<SupportMessageDto>
            {
                Success = true,
                Message = "Gửi minh chứng hỗ trợ thành công",
                Data = result
            });
        }

        [HttpPost("conversations/{conversationId:int}/read")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        public async Task<IActionResult> MarkAsRead(int conversationId, CancellationToken cancellationToken)
        {
            var userId = User.GetUserId();
            var readCount = await _supportChatService.MarkAsReadAsync(
                conversationId,
                userId,
                IsStaff(),
                cancellationToken);

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Đánh dấu tin nhắn hỗ trợ đã đọc thành công",
                Data = new { readCount }
            });
        }

        [HttpPut("conversations/{conversationId:int}/assign")]
        [Authorize(Roles = RoleNames.Admin)]
        [ProducesResponseType(typeof(ApiResponseDto<SupportConversationDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> AssignConversation(
            int conversationId,
            [FromBody] AssignSupportConversationRequestDto request,
            CancellationToken cancellationToken)
        {
            var userId = User.GetUserId();
            var result = await _supportChatService.AssignConversationAsync(
                conversationId,
                userId,
                request.AssignedToUserId,
                cancellationToken);

            return Ok(new ApiResponseDto<SupportConversationDto>
            {
                Success = true,
                Message = "Phân công yêu cầu hỗ trợ thành công",
                Data = result
            });
        }

        [HttpPut("conversations/{conversationId:int}/status")]
        [Authorize(Roles = RoleNames.CanBo + "," + RoleNames.Admin)]
        [ProducesResponseType(typeof(ApiResponseDto<SupportConversationDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> UpdateStatus(
            int conversationId,
            [FromBody] UpdateSupportConversationStatusRequestDto request,
            CancellationToken cancellationToken)
        {
            var userId = User.GetUserId();
            var result = await _supportChatService.UpdateStatusAsync(
                conversationId,
                userId,
                isStaff: true,
                request.Status,
                cancellationToken);

            return Ok(new ApiResponseDto<SupportConversationDto>
            {
                Success = true,
                Message = "Cập nhật trạng thái yêu cầu hỗ trợ thành công",
                Data = result
            });
        }

        private bool IsStaff()
        {
            return User.IsInRole(RoleNames.Admin) || User.IsInRole(RoleNames.CanBo);
        }
    }
}
