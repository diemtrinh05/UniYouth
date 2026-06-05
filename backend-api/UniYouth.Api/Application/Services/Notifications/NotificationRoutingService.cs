using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Constants;
using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Application.Services.NotificationsSupport;

public sealed class NotificationRoutingService
{
    private readonly UniYouthDbContext _context;

    public NotificationRoutingService(UniYouthDbContext context)
    {
        _context = context;
    }

    public async Task<(NotificationAudience Audience, string? TargetRole)> ResolveAudienceAndTargetRoleAsync(
        int userId,
        NotificationAudience? requestedAudience,
        string? requestedTargetRole)
    {
        if (requestedAudience.HasValue)
        {
            return (requestedAudience.Value, string.IsNullOrWhiteSpace(requestedTargetRole) ? null : requestedTargetRole.Trim());
        }

        var roleNames = await _context.UserRoles
            .AsNoTracking()
            .Where(ur => ur.UserID == userId)
            .Select(ur => ur.Role.RoleName)
            .ToListAsync();

        if (roleNames.Contains(RoleNames.Admin, StringComparer.OrdinalIgnoreCase))
        {
            return (NotificationAudience.Admin, RoleNames.Admin);
        }

        if (roleNames.Contains(RoleNames.CanBo, StringComparer.OrdinalIgnoreCase))
        {
            return (NotificationAudience.WebOfficer, RoleNames.CanBo);
        }

        if (roleNames.Contains(RoleNames.HoiVien, StringComparer.OrdinalIgnoreCase))
        {
            return (NotificationAudience.MobileMember, RoleNames.HoiVien);
        }

        if (roleNames.Contains(RoleNames.DoanVien, StringComparer.OrdinalIgnoreCase))
        {
            return (NotificationAudience.MobileMember, RoleNames.DoanVien);
        }

        return (NotificationAudience.MobileMember, null);
    }

    public List<NotificationOutbox> BuildOutboxEntries(Notification notification, NotificationAudience audience)
    {
        var now = DateTime.Now;
        return GetDispatchChannels(audience)
            .Select(channel => new NotificationOutbox
            {
                Notification = notification,
                UserID = notification.UserID,
                Channel = (byte)channel,
                Status = (byte)NotificationOutboxStatus.Pending,
                AttemptCount = 0,
                MaxAttempts = 5,
                NextAttemptAt = now,
                CreatedDate = now,
                UpdatedDate = now
            })
            .ToList();
    }

    public void DetachPendingOutboxEntriesFor(Notification notification)
    {
        var trackedOutboxEntries = _context.ChangeTracker
            .Entries<NotificationOutbox>()
            .Where(entry => entry.State == EntityState.Added && ReferenceEquals(entry.Entity.Notification, notification))
            .ToList();

        foreach (var outboxEntry in trackedOutboxEntries)
        {
            outboxEntry.State = EntityState.Detached;
        }
    }

    public static bool IsNotificationDedupConflict(DbUpdateException ex)
    {
        if (ex.InnerException is SqlException sqlEx && sqlEx.Number is 2601 or 2627)
        {
            return true;
        }

        return ex.InnerException?.Message.Contains("UX_Notifications_DedupKey_NotNull", StringComparison.OrdinalIgnoreCase) == true
            || ex.Message.Contains("UX_Notifications_DedupKey_NotNull", StringComparison.OrdinalIgnoreCase);
    }

    public async Task<List<int>> GetWebAlertRecipientUserIdsAsync(int eventId)
    {
        var eventOwnerUserId = await _context.Events
            .AsNoTracking()
            .Where(e => e.EventID == eventId)
            .Select(e => (int?)e.CreatedBy)
            .FirstOrDefaultAsync();

        if (!eventOwnerUserId.HasValue)
        {
            return new List<int>();
        }

        var adminUserIds = await _context.UserRoles
            .AsNoTracking()
            .Where(ur => ur.Role.RoleName == RoleNames.Admin)
            .Select(ur => ur.UserID)
            .Distinct()
            .ToListAsync();

        adminUserIds.Add(eventOwnerUserId.Value);
        return adminUserIds.Distinct().ToList();
    }

    public Task<List<int>> GetAdminAlertRecipientUserIdsAsync()
    {
        return _context.UserRoles
            .AsNoTracking()
            .Where(ur => ur.Role.RoleName == RoleNames.Admin)
            .Select(ur => ur.UserID)
            .Distinct()
            .ToListAsync();
    }

    private static IReadOnlyList<NotificationChannel> GetDispatchChannels(NotificationAudience audience)
    {
        return audience == NotificationAudience.MobileMember
            ? new[] { NotificationChannel.Realtime, NotificationChannel.Push }
            : new[] { NotificationChannel.Realtime };
    }
}
