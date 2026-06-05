using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Notifications;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Helpers;

namespace UniYouth.Api.Application.Services.NotificationsSupport;

public sealed class NotificationInboxService
{
    private readonly UniYouthDbContext _context;
    private readonly ILogger _logger;

    public NotificationInboxService(UniYouthDbContext context, ILogger logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<NotificationListResponseDto> GetUserNotificationsAsync(int userId, int pageNumber = 1, int pageSize = 20)
    {
        if (pageNumber < 1) pageNumber = 1;
        if (pageSize < 1) pageSize = 20;
        if (pageSize > 100) pageSize = 100;

        var totalCount = await _context.Notifications
            .Where(n => n.UserID == userId)
            .CountAsync();

        var unreadCount = await _context.Notifications
            .Where(n => n.UserID == userId && n.IsRead != true)
            .CountAsync();

        var notifications = await _context.Notifications
            .Where(n => n.UserID == userId)
            .Include(n => n.NotificationType)
            .Include(n => n.Event)
            .OrderByDescending(n => n.CreatedDate)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(n => new NotificationDto
            {
                NotificationID = n.NotificationID,
                Title = n.Title,
                Content = n.Content,
                NotificationType = n.NotificationType.TypeName,
                Priority = n.Priority,
                IsRead = n.IsRead,
                ReadDate = n.ReadDate,
                ActionUrl = n.ActionUrl,
                EventID = n.EventID,
                EventName = n.Event != null ? n.Event.EventName : null,
                CreatedDate = n.CreatedDate.HasValue ? DateTimeHelper.ToVietnamTime(n.CreatedDate.Value) : null,
                ExpiryDate = n.ExpiryDate.HasValue ? DateTimeHelper.ToVietnamTime(n.ExpiryDate.Value) : null
            })
            .ToListAsync();

        var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);

        return new NotificationListResponseDto
        {
            Notifications = notifications,
            TotalCount = totalCount,
            PageNumber = pageNumber,
            PageSize = pageSize,
            TotalPages = totalPages,
            HasPreviousPage = pageNumber > 1,
            HasNextPage = pageNumber < totalPages,
            UnreadCount = unreadCount
        };
    }

    public async Task<bool> MarkAsReadAsync(int notificationId, int userId)
    {
        var notification = await _context.Notifications.FirstOrDefaultAsync(n => n.NotificationID == notificationId);
        if (notification == null)
        {
            throw new KeyNotFoundException($"Không tìm thấy thông báo với ID {notificationId}");
        }

        if (notification.UserID != userId)
        {
            throw new UnauthorizedAccessException("Bạn không có quyền truy cập thông báo này");
        }

        if (notification.IsRead == true)
        {
            return false;
        }

        notification.IsRead = true;
        notification.ReadDate = DateTime.Now;
        await _context.SaveChangesAsync();

        _logger.LogInformation(
            "Đã đánh dấu thông báo đã đọc: NotificationID={NotificationId}, UserID={UserId}",
            notificationId,
            userId);

        return true;
    }

    public async Task<int> MarkAllAsReadAsync(int userId)
    {
        var unreadNotifications = await _context.Notifications
            .Where(n => n.UserID == userId && n.IsRead != true)
            .ToListAsync();

        if (!unreadNotifications.Any())
        {
            return 0;
        }

        var now = DateTime.Now;
        foreach (var notification in unreadNotifications)
        {
            notification.IsRead = true;
            notification.ReadDate = now;
        }

        await _context.SaveChangesAsync();

        _logger.LogInformation(
            "Đã đánh dấu tất cả thông báo là đã đọc: Count={Count}, UserID={UserId}",
            unreadNotifications.Count,
            userId);

        return unreadNotifications.Count;
    }

    public Task<int> GetUnreadCountAsync(int userId)
    {
        return _context.Notifications
            .Where(n => n.UserID == userId && n.IsRead != true)
            .CountAsync();
    }
}
