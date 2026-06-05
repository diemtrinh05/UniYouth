using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Application.Jobs
{
    /// <summary>
    /// Background job:
    /// - Tự động chuyển trạng thái sự kiện theo thời gian (Open -> Ongoing -> Closed)
    /// - Dọn thông báo hết hạn định kỳ
    /// - Archive thông báo đã đọc cũ theo retention policy
    /// </summary>
    public class EventBackgroundService : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<EventBackgroundService> _logger;

        public EventBackgroundService(
            IServiceScopeFactory scopeFactory,
            ILogger<EventBackgroundService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            DateTime lastNotificationCleanupUtc = DateTime.MinValue;
            DateTime lastNotificationArchiveUtc = DateTime.MinValue;

            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await using var scope = _scopeFactory.CreateAsyncScope();
                    var dbContext = scope.ServiceProvider.GetRequiredService<UniYouthDbContext>();
                    var notificationService = scope.ServiceProvider.GetRequiredService<INotificationService>();

                    var now = DateTime.Now;

                    // ================================================================
                    // 1) AUTO UPDATE EVENT STATUS BY TIME
                    // - Open -> Ongoing: now between StartTime and EndTime
                    // - Ongoing/Open -> Closed: now after EndTime
                    // ================================================================
                    try
                    {
                        var movedToOngoing = await dbContext.Events
                            .Where(e =>
                                e.Status == (byte)EventStatus.Open &&
                                e.StartTime <= now &&
                                e.EndTime > now)
                            .ExecuteUpdateAsync(setters => setters
                                .SetProperty(e => e.Status, (byte)EventStatus.Ongoing)
                                .SetProperty(e => e.UpdatedDate, now), stoppingToken);

                        var movedToClosedFromOngoing = await dbContext.Events
                            .Where(e =>
                                e.Status == (byte)EventStatus.Ongoing &&
                                e.EndTime <= now)
                            .ExecuteUpdateAsync(setters => setters
                                .SetProperty(e => e.Status, (byte)EventStatus.Closed)
                                .SetProperty(e => e.UpdatedDate, now), stoppingToken);

                        var movedToClosedFromOpen = await dbContext.Events
                            .Where(e =>
                                e.Status == (byte)EventStatus.Open &&
                                e.EndTime <= now)
                            .ExecuteUpdateAsync(setters => setters
                                .SetProperty(e => e.Status, (byte)EventStatus.Closed)
                                .SetProperty(e => e.UpdatedDate, now), stoppingToken);

                        if (movedToOngoing > 0 || movedToClosedFromOngoing > 0 || movedToClosedFromOpen > 0)
                        {
                            _logger.LogInformation(
                                "Background job cập nhật trạng thái sự kiện: Open->Ongoing={ToOngoing}, Ongoing->Closed={ToClosedOngoing}, Open->Closed={ToClosedOpen}",
                                movedToOngoing, movedToClosedFromOngoing, movedToClosedFromOpen);
                        }
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Lỗi background job khi cập nhật trạng thái sự kiện");
                    }

                    // ================================================================
                    // 2) CLEANUP EXPIRED NOTIFICATIONS (định kỳ)
                    // ================================================================
                    if (now - lastNotificationCleanupUtc >= TimeSpan.FromHours(1))
                    {
                        try
                        {
                            var deletedCount = await notificationService.DeleteExpiredNotificationsAsync();
                            lastNotificationCleanupUtc = now;

                            if (deletedCount > 0)
                            {
                                _logger.LogInformation("Background job dọn thông báo hết hạn: Deleted={DeletedCount}", deletedCount);
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "Lỗi background job khi dọn thông báo hết hạn");
                        }
                    }

                    // ================================================================
                    // 3) ARCHIVE OLD READ NOTIFICATIONS (định kỳ)
                    // ================================================================
                    if (now - lastNotificationArchiveUtc >= TimeSpan.FromHours(6))
                    {
                        try
                        {
                            var archivedCount = await notificationService.ArchiveOldNotificationsAsync();
                            lastNotificationArchiveUtc = now;

                            if (archivedCount > 0)
                            {
                                _logger.LogInformation("Background job archive thông báo cũ: Archived={ArchivedCount}", archivedCount);
                            }
                        }
                        catch (Exception ex)
                        {
                            _logger.LogError(ex, "Lỗi background job khi archive thông báo cũ");
                        }
                    }
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Lỗi background job xử lý vòng đời sự kiện / dọn thông báo");
                }

                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
        }
    }
}
