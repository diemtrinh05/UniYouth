using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.Http;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Notifications;
using UniYouth.Api.Contracts.DTOs.SupportChat;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Constants;
using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Application.Services
{
    public interface ISupportChatService
    {
        Task<SupportConversationDto> CreateConversationAsync(int studentUserId, CreateSupportConversationRequestDto request, CancellationToken cancellationToken = default);
        Task<PaginatedResultDto<SupportConversationDto>> GetMyConversationsAsync(int userId, int pageNumber, int pageSize, CancellationToken cancellationToken = default);
        Task<PaginatedResultDto<SupportConversationDto>> GetAdminConversationsAsync(int actorUserId, int pageNumber, int pageSize, byte? status, byte? priority, int? assignedToUserId, string? search, CancellationToken cancellationToken = default);
        Task<SupportConversationDto> GetConversationAsync(int conversationId, int actorUserId, bool isStaff, CancellationToken cancellationToken = default);
        Task<PaginatedResultDto<SupportMessageDto>> GetConversationMessagesAsync(int conversationId, int actorUserId, bool isStaff, int pageNumber, int pageSize, CancellationToken cancellationToken = default);
        Task<SupportMessageDto> SendMessageAsync(int conversationId, int senderUserId, bool isStaff, SendSupportMessageRequestDto request, CancellationToken cancellationToken = default);
        Task<SupportMessageDto> SendAttachmentAsync(int conversationId, int senderUserId, bool isStaff, SendSupportAttachmentRequestDto request, string webRootPath, CancellationToken cancellationToken = default);
        Task<SupportConversationDto> AssignConversationAsync(int conversationId, int actorUserId, int? assignedToUserId, CancellationToken cancellationToken = default);
        Task<SupportConversationDto> UpdateStatusAsync(int conversationId, int actorUserId, bool isStaff, byte status, CancellationToken cancellationToken = default);
        Task<int> MarkAsReadAsync(int conversationId, int userId, bool isStaff, CancellationToken cancellationToken = default);
    }

    public class SupportChatService : ISupportChatService
    {
        private const byte StatusOpen = 1;
        private const byte StatusInProgress = 2;
        private const byte StatusClosed = 3;
        private const byte MessageTypeText = 1;
        private const byte MessageTypeAttachment = 2;
        private const long MaxAttachmentSizeBytes = 5 * 1024 * 1024;
        private static readonly HashSet<string> AllowedAttachmentExtensions = new(StringComparer.OrdinalIgnoreCase)
        {
            ".jpg",
            ".jpeg",
            ".png",
            ".webp",
            ".pdf"
        };

        private readonly UniYouthDbContext _context;
        private readonly ISupportChatRealtimeDispatcher _realtimeDispatcher;
        private readonly INotificationService _notificationService;
        private readonly ILogger<SupportChatService> _logger;

        public SupportChatService(
            UniYouthDbContext context,
            ISupportChatRealtimeDispatcher realtimeDispatcher,
            INotificationService notificationService,
            ILogger<SupportChatService> logger)
        {
            _context = context;
            _realtimeDispatcher = realtimeDispatcher;
            _notificationService = notificationService;
            _logger = logger;
        }

        public async Task<SupportConversationDto> CreateConversationAsync(
            int studentUserId,
            CreateSupportConversationRequestDto request,
            CancellationToken cancellationToken = default)
        {
            var subject = NormalizeRequiredText(request.Subject, "Tiêu đề là bắt buộc", 255);
            var content = NormalizeRequiredText(request.Content, "Nội dung hỗ trợ là bắt buộc", 4000);
            ValidatePriority(request.Priority);

            var studentExists = await _context.Users
                .AsNoTracking()
                .AnyAsync(user => user.UserID == studentUserId && user.Status != 0, cancellationToken);

            if (!studentExists)
            {
                throw new KeyNotFoundException("Không tìm thấy sinh viên");
            }

            var now = DateTime.Now;
            var conversation = new SupportConversation
            {
                StudentUserID = studentUserId,
                Subject = subject,
                Status = StatusOpen,
                Priority = request.Priority,
                LastMessageAt = now,
                CreatedDate = now,
                UpdatedDate = now
            };

            conversation.SupportMessages.Add(new SupportMessage
            {
                SenderUserID = studentUserId,
                MessageType = MessageTypeText,
                Content = content,
                CreatedDate = now
            });

            _context.SupportConversations.Add(conversation);
            await _context.SaveChangesAsync(cancellationToken);

            var result = await GetConversationAsync(conversation.ConversationID, studentUserId, isStaff: false, cancellationToken);
            await NotifyStaffAsync("Yêu cầu hỗ trợ mới", $"{result.StudentFullName} vừa tạo yêu cầu hỗ trợ: {result.Subject}", result.ConversationId, studentUserId, cancellationToken);
            await _realtimeDispatcher.DispatchConversationCreatedAsync(result, cancellationToken);

            return result;
        }

        public async Task<PaginatedResultDto<SupportConversationDto>> GetMyConversationsAsync(
            int userId,
            int pageNumber,
            int pageSize,
            CancellationToken cancellationToken = default)
        {
            NormalizePaging(ref pageNumber, ref pageSize);

            var query = _context.SupportConversations
                .AsNoTracking()
                .Include(conversation => conversation.StudentUser)
                .Include(conversation => conversation.AssignedToUser)
                .Where(conversation => conversation.StudentUserID == userId);

            return await BuildConversationPageAsync(query, userId, pageNumber, pageSize, cancellationToken);
        }

        public async Task<PaginatedResultDto<SupportConversationDto>> GetAdminConversationsAsync(
            int actorUserId,
            int pageNumber,
            int pageSize,
            byte? status,
            byte? priority,
            int? assignedToUserId,
            string? search,
            CancellationToken cancellationToken = default)
        {
            NormalizePaging(ref pageNumber, ref pageSize);

            var query = _context.SupportConversations
                .AsNoTracking()
                .Include(conversation => conversation.StudentUser)
                .Include(conversation => conversation.AssignedToUser)
                .AsQueryable();

            if (status.HasValue)
            {
                ValidateStatus(status.Value);
                query = query.Where(conversation => conversation.Status == status.Value);
            }

            if (priority.HasValue)
            {
                ValidatePriority(priority.Value);
                query = query.Where(conversation => conversation.Priority == priority.Value);
            }

            if (assignedToUserId.HasValue)
            {
                query = query.Where(conversation => conversation.AssignedToUserID == assignedToUserId.Value);
            }

            if (!string.IsNullOrWhiteSpace(search))
            {
                var keyword = search.Trim();
                query = query.Where(conversation =>
                    EF.Functions.Like(conversation.Subject, $"%{keyword}%") ||
                    EF.Functions.Like(conversation.StudentUser.FullName, $"%{keyword}%") ||
                    EF.Functions.Like(conversation.StudentUser.Code, $"%{keyword}%") ||
                    EF.Functions.Like(conversation.StudentUser.Email, $"%{keyword}%"));
            }

            return await BuildConversationPageAsync(query, actorUserId, pageNumber, pageSize, cancellationToken);
        }

        public async Task<SupportConversationDto> GetConversationAsync(
            int conversationId,
            int actorUserId,
            bool isStaff,
            CancellationToken cancellationToken = default)
        {
            var conversation = await _context.SupportConversations
                .AsNoTracking()
                .Include(item => item.StudentUser)
                .Include(item => item.AssignedToUser)
                .FirstOrDefaultAsync(item => item.ConversationID == conversationId, cancellationToken);

            if (conversation == null)
            {
                throw new KeyNotFoundException("Không tìm thấy cuộc trò chuyện hỗ trợ");
            }

            EnsureConversationAccess(conversation, actorUserId, isStaff);

            var unreadCount = await CountUnreadMessagesAsync(conversationId, actorUserId, cancellationToken);
            var lastMessage = await GetLastMessagePreviewAsync(new[] { conversationId }, cancellationToken);

            return MapConversation(conversation, actorUserId, unreadCount, lastMessage.GetValueOrDefault(conversationId));
        }

        public async Task<PaginatedResultDto<SupportMessageDto>> GetConversationMessagesAsync(
            int conversationId,
            int actorUserId,
            bool isStaff,
            int pageNumber,
            int pageSize,
            CancellationToken cancellationToken = default)
        {
            NormalizePaging(ref pageNumber, ref pageSize);
            await EnsureConversationAccessAsync(conversationId, actorUserId, isStaff, cancellationToken);

            var query = _context.SupportMessages
                .AsNoTracking()
                .Include(message => message.SenderUser)
                .Where(message => message.ConversationID == conversationId && !message.IsDeleted)
                .OrderBy(message => message.CreatedDate)
                .ThenBy(message => message.MessageID);

            var totalCount = await query.CountAsync(cancellationToken);
            var messages = await query
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .Select(message => new SupportMessageDto
                {
                    MessageId = message.MessageID,
                    ConversationId = message.ConversationID,
                    SenderUserId = message.SenderUserID,
                    SenderFullName = message.SenderUser.FullName,
                    SenderCode = message.SenderUser.Code,
                    MessageType = message.MessageType,
                    Content = message.Content,
                    AttachmentUrl = message.AttachmentUrl,
                    IsMine = message.SenderUserID == actorUserId,
                    CreatedDate = message.CreatedDate
                })
                .ToListAsync(cancellationToken);

            return new PaginatedResultDto<SupportMessageDto>
            {
                Items = messages,
                TotalCount = totalCount,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }

        public async Task<SupportMessageDto> SendMessageAsync(
            int conversationId,
            int senderUserId,
            bool isStaff,
            SendSupportMessageRequestDto request,
            CancellationToken cancellationToken = default)
        {
            var content = NormalizeRequiredText(request.Content, "Nội dung tin nhắn là bắt buộc", 4000);
            var conversation = await GetConversationEntityAsync(conversationId, cancellationToken);
            EnsureConversationAccess(conversation, senderUserId, isStaff);

            if (conversation.Status == StatusClosed)
            {
                throw new InvalidOperationException("Cuộc trò chuyện đã đóng, không thể gửi thêm tin nhắn");
            }

            var now = DateTime.Now;
            var message = new SupportMessage
            {
                ConversationID = conversationId,
                SenderUserID = senderUserId,
                MessageType = MessageTypeText,
                Content = content,
                CreatedDate = now
            };

            if (isStaff && conversation.Status == StatusOpen)
            {
                conversation.Status = StatusInProgress;
            }

            conversation.LastMessageAt = now;
            conversation.UpdatedDate = now;
            _context.SupportMessages.Add(message);
            await _context.SaveChangesAsync(cancellationToken);

            var messageDto = await GetMessageDtoAsync(message.MessageID, senderUserId, cancellationToken);
            var recipientUserIds = await ResolveMessageRecipientUserIdsAsync(conversation, senderUserId, isStaff, cancellationToken);

            await NotifyMessageRecipientsAsync(conversation, senderUserId, isStaff, recipientUserIds, cancellationToken);
            await _realtimeDispatcher.DispatchMessageCreatedAsync(messageDto, recipientUserIds, cancellationToken);

            return messageDto;
        }

        public async Task<SupportMessageDto> SendAttachmentAsync(
            int conversationId,
            int senderUserId,
            bool isStaff,
            SendSupportAttachmentRequestDto request,
            string webRootPath,
            CancellationToken cancellationToken = default)
        {
            ValidateAttachment(request.File);
            var content = string.IsNullOrWhiteSpace(request.Content)
                ? $"Đã gửi minh chứng: {request.File.FileName}"
                : NormalizeRequiredText(request.Content, "Nội dung ghi chú không hợp lệ", 1000);

            var conversation = await GetConversationEntityAsync(conversationId, cancellationToken);
            EnsureConversationAccess(conversation, senderUserId, isStaff);

            if (conversation.Status == StatusClosed)
            {
                throw new InvalidOperationException("Cuộc trò chuyện đã đóng, không thể gửi thêm minh chứng");
            }

            var attachmentUrl = await SaveAttachmentAsync(conversationId, request.File, webRootPath, cancellationToken);
            var now = DateTime.Now;
            var message = new SupportMessage
            {
                ConversationID = conversationId,
                SenderUserID = senderUserId,
                MessageType = MessageTypeAttachment,
                Content = content,
                AttachmentUrl = attachmentUrl,
                CreatedDate = now
            };

            if (isStaff && conversation.Status == StatusOpen)
            {
                conversation.Status = StatusInProgress;
            }

            conversation.LastMessageAt = now;
            conversation.UpdatedDate = now;
            _context.SupportMessages.Add(message);
            await _context.SaveChangesAsync(cancellationToken);

            var messageDto = await GetMessageDtoAsync(message.MessageID, senderUserId, cancellationToken);
            var recipientUserIds = await ResolveMessageRecipientUserIdsAsync(conversation, senderUserId, isStaff, cancellationToken);

            await NotifyMessageRecipientsAsync(conversation, senderUserId, isStaff, recipientUserIds, cancellationToken);
            await _realtimeDispatcher.DispatchMessageCreatedAsync(messageDto, recipientUserIds, cancellationToken);

            return messageDto;
        }

        public async Task<SupportConversationDto> AssignConversationAsync(
            int conversationId,
            int actorUserId,
            int? assignedToUserId,
            CancellationToken cancellationToken = default)
        {
            var conversation = await GetConversationEntityAsync(conversationId, cancellationToken);

            if (assignedToUserId.HasValue)
            {
                var assignedUserIsStaff = await IsStaffUserAsync(assignedToUserId.Value, cancellationToken);
                if (!assignedUserIsStaff)
                {
                    throw new InvalidOperationException("Người phụ trách phải là Admin hoặc Cán bộ");
                }
            }

            conversation.AssignedToUserID = assignedToUserId;
            if (conversation.Status == StatusOpen && assignedToUserId.HasValue)
            {
                conversation.Status = StatusInProgress;
            }

            conversation.UpdatedDate = DateTime.Now;
            await _context.SaveChangesAsync(cancellationToken);

            var result = await GetConversationAsync(conversationId, actorUserId, isStaff: true, cancellationToken);
            await _realtimeDispatcher.DispatchConversationUpdatedAsync(result, cancellationToken);

            if (assignedToUserId.HasValue)
            {
                await NotifyUserAsync(
                    assignedToUserId.Value,
                    "Bạn được phân công hỗ trợ",
                    $"Bạn được phân công xử lý yêu cầu hỗ trợ: {result.Subject}",
                    result.ConversationId,
                    cancellationToken);
            }

            return result;
        }

        public async Task<SupportConversationDto> UpdateStatusAsync(
            int conversationId,
            int actorUserId,
            bool isStaff,
            byte status,
            CancellationToken cancellationToken = default)
        {
            ValidateStatus(status);

            var conversation = await GetConversationEntityAsync(conversationId, cancellationToken);
            EnsureConversationAccess(conversation, actorUserId, isStaff);

            if (!isStaff)
            {
                throw new UnauthorizedAccessException("Bạn không có quyền cập nhật trạng thái hỗ trợ");
            }

            conversation.Status = status;
            conversation.ClosedAt = status == StatusClosed ? DateTime.Now : null;
            conversation.UpdatedDate = DateTime.Now;
            await _context.SaveChangesAsync(cancellationToken);

            var result = await GetConversationAsync(conversationId, actorUserId, isStaff: true, cancellationToken);
            await NotifyUserAsync(
                result.StudentUserId,
                "Trạng thái hỗ trợ đã cập nhật",
                $"Yêu cầu hỗ trợ \"{result.Subject}\" đã chuyển sang trạng thái {result.StatusName}.",
                result.ConversationId,
                cancellationToken);
            await _realtimeDispatcher.DispatchConversationUpdatedAsync(result, cancellationToken);

            return result;
        }

        public async Task<int> MarkAsReadAsync(
            int conversationId,
            int userId,
            bool isStaff,
            CancellationToken cancellationToken = default)
        {
            await EnsureConversationAccessAsync(conversationId, userId, isStaff, cancellationToken);

            var unreadMessageIds = await _context.SupportMessages
                .AsNoTracking()
                .Where(message =>
                    message.ConversationID == conversationId &&
                    message.SenderUserID != userId &&
                    !message.IsDeleted &&
                    !message.SupportMessageReads.Any(read => read.UserID == userId))
                .Select(message => message.MessageID)
                .ToListAsync(cancellationToken);

            if (unreadMessageIds.Count == 0)
            {
                return 0;
            }

            var now = DateTime.Now;
            var reads = unreadMessageIds.Select(messageId => new SupportMessageRead
            {
                MessageID = messageId,
                UserID = userId,
                ReadAt = now
            });

            _context.SupportMessageReads.AddRange(reads);
            await _context.SaveChangesAsync(cancellationToken);
            await _realtimeDispatcher.DispatchMessagesReadAsync(conversationId, userId, unreadMessageIds.Count, cancellationToken);

            return unreadMessageIds.Count;
        }

        private async Task<PaginatedResultDto<SupportConversationDto>> BuildConversationPageAsync(
            IQueryable<SupportConversation> query,
            int actorUserId,
            int pageNumber,
            int pageSize,
            CancellationToken cancellationToken)
        {
            var totalCount = await query.CountAsync(cancellationToken);
            var conversations = await query
                .OrderByDescending(conversation => conversation.LastMessageAt ?? conversation.CreatedDate)
                .ThenByDescending(conversation => conversation.ConversationID)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var conversationIds = conversations.Select(conversation => conversation.ConversationID).ToArray();
            var unreadCounts = await GetUnreadCountsAsync(conversationIds, actorUserId, cancellationToken);
            var lastMessages = await GetLastMessagePreviewAsync(conversationIds, cancellationToken);

            return new PaginatedResultDto<SupportConversationDto>
            {
                Items = conversations
                    .Select(conversation => MapConversation(
                        conversation,
                        actorUserId,
                        unreadCounts.GetValueOrDefault(conversation.ConversationID),
                        lastMessages.GetValueOrDefault(conversation.ConversationID)))
                    .ToList(),
                TotalCount = totalCount,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }

        private async Task<SupportConversation> GetConversationEntityAsync(int conversationId, CancellationToken cancellationToken)
        {
            var conversation = await _context.SupportConversations
                .Include(item => item.StudentUser)
                .Include(item => item.AssignedToUser)
                .FirstOrDefaultAsync(item => item.ConversationID == conversationId, cancellationToken);

            if (conversation == null)
            {
                throw new KeyNotFoundException("Không tìm thấy cuộc trò chuyện hỗ trợ");
            }

            return conversation;
        }

        private async Task EnsureConversationAccessAsync(
            int conversationId,
            int actorUserId,
            bool isStaff,
            CancellationToken cancellationToken)
        {
            var conversation = await _context.SupportConversations
                .AsNoTracking()
                .FirstOrDefaultAsync(item => item.ConversationID == conversationId, cancellationToken);

            if (conversation == null)
            {
                throw new KeyNotFoundException("Không tìm thấy cuộc trò chuyện hỗ trợ");
            }

            EnsureConversationAccess(conversation, actorUserId, isStaff);
        }

        private static void EnsureConversationAccess(SupportConversation conversation, int actorUserId, bool isStaff)
        {
            if (isStaff)
            {
                return;
            }

            if (conversation.StudentUserID != actorUserId)
            {
                throw new UnauthorizedAccessException("Bạn không có quyền truy cập cuộc trò chuyện này");
            }
        }

        private async Task<SupportMessageDto> GetMessageDtoAsync(int messageId, int actorUserId, CancellationToken cancellationToken)
        {
            var message = await _context.SupportMessages
                .AsNoTracking()
                .Include(item => item.SenderUser)
                .Where(item => item.MessageID == messageId)
                .Select(item => new SupportMessageDto
                {
                    MessageId = item.MessageID,
                    ConversationId = item.ConversationID,
                    SenderUserId = item.SenderUserID,
                    SenderFullName = item.SenderUser.FullName,
                    SenderCode = item.SenderUser.Code,
                    MessageType = item.MessageType,
                    Content = item.Content,
                    AttachmentUrl = item.AttachmentUrl,
                    IsMine = item.SenderUserID == actorUserId,
                    CreatedDate = item.CreatedDate
                })
                .FirstOrDefaultAsync(cancellationToken);

            return message ?? throw new KeyNotFoundException("Không tìm thấy tin nhắn hỗ trợ");
        }

        private async Task<Dictionary<int, int>> GetUnreadCountsAsync(
            IReadOnlyCollection<int> conversationIds,
            int userId,
            CancellationToken cancellationToken)
        {
            if (conversationIds.Count == 0)
            {
                return new Dictionary<int, int>();
            }

            return await _context.SupportMessages
                .AsNoTracking()
                .Where(message =>
                    conversationIds.Contains(message.ConversationID) &&
                    message.SenderUserID != userId &&
                    !message.IsDeleted &&
                    !message.SupportMessageReads.Any(read => read.UserID == userId))
                .GroupBy(message => message.ConversationID)
                .Select(group => new { ConversationId = group.Key, Count = group.Count() })
                .ToDictionaryAsync(item => item.ConversationId, item => item.Count, cancellationToken);
        }

        private async Task<int> CountUnreadMessagesAsync(int conversationId, int userId, CancellationToken cancellationToken)
        {
            return await _context.SupportMessages
                .AsNoTracking()
                .CountAsync(message =>
                    message.ConversationID == conversationId &&
                    message.SenderUserID != userId &&
                    !message.IsDeleted &&
                    !message.SupportMessageReads.Any(read => read.UserID == userId),
                    cancellationToken);
        }

        private async Task<Dictionary<int, string>> GetLastMessagePreviewAsync(
            IReadOnlyCollection<int> conversationIds,
            CancellationToken cancellationToken)
        {
            if (conversationIds.Count == 0)
            {
                return new Dictionary<int, string>();
            }

            var messages = await _context.SupportMessages
                .AsNoTracking()
                .Where(message => conversationIds.Contains(message.ConversationID) && !message.IsDeleted)
                .OrderByDescending(message => message.CreatedDate)
                .ThenByDescending(message => message.MessageID)
                .Select(message => new
                {
                    message.ConversationID,
                    message.Content
                })
                .ToListAsync(cancellationToken);

            return messages
                .GroupBy(message => message.ConversationID)
                .ToDictionary(
                    group => group.Key,
                    group => Truncate(group.First().Content, 120));
        }

        private async Task<IReadOnlyCollection<int>> ResolveMessageRecipientUserIdsAsync(
            SupportConversation conversation,
            int senderUserId,
            bool senderIsStaff,
            CancellationToken cancellationToken)
        {
            if (senderIsStaff)
            {
                return conversation.StudentUserID == senderUserId
                    ? Array.Empty<int>()
                    : new[] { conversation.StudentUserID };
            }

            if (conversation.AssignedToUserID.HasValue)
            {
                return new[] { conversation.AssignedToUserID.Value };
            }

            return await GetStaffUserIdsAsync(senderUserId, cancellationToken);
        }

        private async Task NotifyMessageRecipientsAsync(
            SupportConversation conversation,
            int senderUserId,
            bool senderIsStaff,
            IReadOnlyCollection<int> recipientUserIds,
            CancellationToken cancellationToken)
        {
            var title = senderIsStaff ? "Phản hồi hỗ trợ mới" : "Tin nhắn hỗ trợ mới";
            var content = senderIsStaff
                ? $"Yêu cầu hỗ trợ \"{conversation.Subject}\" đã có phản hồi mới."
                : $"{conversation.StudentUser.FullName} vừa gửi tin nhắn trong yêu cầu hỗ trợ: {conversation.Subject}";

            foreach (var recipientUserId in recipientUserIds.Distinct().Where(userId => userId != senderUserId))
            {
                await NotifyUserAsync(recipientUserId, title, content, conversation.ConversationID, cancellationToken);
            }
        }

        private async Task NotifyStaffAsync(
            string title,
            string content,
            int conversationId,
            int excludedUserId,
            CancellationToken cancellationToken)
        {
            var staffUserIds = await GetStaffUserIdsAsync(excludedUserId, cancellationToken);
            foreach (var staffUserId in staffUserIds)
            {
                await NotifyUserAsync(staffUserId, title, content, conversationId, cancellationToken);
            }
        }

        private async Task NotifyUserAsync(
            int userId,
            string title,
            string content,
            int conversationId,
            CancellationToken cancellationToken)
        {
            try
            {
                await _notificationService.CreateNotificationAsync(new CreateNotificationDto
                {
                    UserID = userId,
                    Title = title,
                    Content = content,
                    NotificationType = NotificationTypeEnum.System,
                    Priority = NotificationPriority.Normal,
                    ActionUrl = $"/support-chat/{conversationId}",
                    DedupKey = $"support-chat:{conversationId}:{userId}:{DateTimeOffset.Now.ToUnixTimeMilliseconds()}"
                });
            }
            catch (Exception ex)
            {
                _logger.LogWarning(
                    ex,
                    "Tạo thông báo chat hỗ trợ thất bại. UserID={UserId}, ConversationID={ConversationId}",
                    userId,
                    conversationId);
            }
        }

        private async Task<IReadOnlyCollection<int>> GetStaffUserIdsAsync(int excludedUserId, CancellationToken cancellationToken)
        {
            return await _context.UserRoles
                .AsNoTracking()
                .Where(userRole =>
                    userRole.UserID != excludedUserId &&
                    (userRole.Role.RoleName == RoleNames.Admin || userRole.Role.RoleName == RoleNames.CanBo))
                .Select(userRole => userRole.UserID)
                .Distinct()
                .ToListAsync(cancellationToken);
        }

        private async Task<bool> IsStaffUserAsync(int userId, CancellationToken cancellationToken)
        {
            return await _context.UserRoles
                .AsNoTracking()
                .AnyAsync(userRole =>
                    userRole.UserID == userId &&
                    (userRole.Role.RoleName == RoleNames.Admin || userRole.Role.RoleName == RoleNames.CanBo),
                    cancellationToken);
        }

        private static SupportConversationDto MapConversation(
            SupportConversation conversation,
            int actorUserId,
            int unreadCount,
            string? lastMessagePreview)
        {
            return new SupportConversationDto
            {
                ConversationId = conversation.ConversationID,
                StudentUserId = conversation.StudentUserID,
                StudentCode = conversation.StudentUser.Code,
                StudentFullName = conversation.StudentUser.FullName,
                AssignedToUserId = conversation.AssignedToUserID,
                AssignedToFullName = conversation.AssignedToUser?.FullName,
                Subject = conversation.Subject,
                Status = conversation.Status,
                StatusName = GetStatusName(conversation.Status),
                Priority = conversation.Priority,
                PriorityName = GetPriorityName(conversation.Priority),
                LastMessagePreview = lastMessagePreview,
                UnreadCount = unreadCount,
                LastMessageAt = conversation.LastMessageAt,
                ClosedAt = conversation.ClosedAt,
                CreatedDate = conversation.CreatedDate,
                UpdatedDate = conversation.UpdatedDate
            };
        }

        private static void NormalizePaging(ref int pageNumber, ref int pageSize)
        {
            pageNumber = Math.Max(1, pageNumber);
            pageSize = Math.Clamp(pageSize, 1, 100);
        }

        private static string NormalizeRequiredText(string? value, string errorMessage, int maxLength)
        {
            var normalized = value?.Trim();
            if (string.IsNullOrWhiteSpace(normalized))
            {
                throw new InvalidOperationException(errorMessage);
            }

            if (normalized.Length > maxLength)
            {
                throw new InvalidOperationException($"Nội dung không được vượt quá {maxLength} ký tự");
            }

            return normalized;
        }

        private static void ValidateStatus(byte status)
        {
            if (status is not (StatusOpen or StatusInProgress or StatusClosed))
            {
                throw new InvalidOperationException("Trạng thái hỗ trợ không hợp lệ");
            }
        }

        private static void ValidatePriority(byte priority)
        {
            if (priority is not (1 or 2 or 3))
            {
                throw new InvalidOperationException("Mức ưu tiên không hợp lệ");
            }
        }

        private static void ValidateAttachment(IFormFile? file)
        {
            if (file == null || file.Length == 0)
            {
                throw new InvalidOperationException("File minh chứng là bắt buộc");
            }

            if (file.Length > MaxAttachmentSizeBytes)
            {
                throw new InvalidOperationException("File minh chứng không được vượt quá 5MB");
            }

            var extension = Path.GetExtension(file.FileName);
            if (string.IsNullOrWhiteSpace(extension) || !AllowedAttachmentExtensions.Contains(extension))
            {
                throw new InvalidOperationException("File minh chứng chỉ hỗ trợ JPG, PNG, WebP hoặc PDF");
            }
        }

        private static async Task<string> SaveAttachmentAsync(
            int conversationId,
            IFormFile file,
            string webRootPath,
            CancellationToken cancellationToken)
        {
            var rootPath = string.IsNullOrWhiteSpace(webRootPath)
                ? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot")
                : webRootPath;
            var uploadDirectory = Path.Combine(rootPath, "uploads", "support-chat", conversationId.ToString());
            Directory.CreateDirectory(uploadDirectory);

            var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
            var fileName = $"{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}_{Guid.NewGuid():N}{extension}";
            var filePath = Path.Combine(uploadDirectory, fileName);

            await using var stream = new FileStream(filePath, FileMode.CreateNew, FileAccess.Write, FileShare.None);
            await file.CopyToAsync(stream, cancellationToken);

            return $"/uploads/support-chat/{conversationId}/{fileName}";
        }

        private static string GetStatusName(byte status)
        {
            return status switch
            {
                StatusOpen => "Mới",
                StatusInProgress => "Đang xử lý",
                StatusClosed => "Đã đóng",
                _ => "Không xác định"
            };
        }

        private static string GetPriorityName(byte priority)
        {
            return priority switch
            {
                1 => "Bình thường",
                2 => "Cao",
                3 => "Khẩn cấp",
                _ => "Không xác định"
            };
        }

        private static string Truncate(string content, int maxLength)
        {
            if (content.Length <= maxLength)
            {
                return content;
            }

            return content[..maxLength] + "...";
        }
    }
}
