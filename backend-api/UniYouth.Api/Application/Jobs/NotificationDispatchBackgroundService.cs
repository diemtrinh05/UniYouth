using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Application.Jobs
{
    public class NotificationDispatchBackgroundService : BackgroundService
    {
        private const int BatchSize = 50;
        private static readonly TimeSpan PollInterval = TimeSpan.FromSeconds(5);
        private static readonly TimeSpan ProcessingTimeout = TimeSpan.FromMinutes(5);
        private static readonly TimeSpan GroupingWindow = TimeSpan.FromMinutes(2);
        private static readonly TimeSpan PushThrottleWindow = TimeSpan.FromSeconds(30);
        private static readonly TimeSpan RealtimeThrottleWindow = TimeSpan.FromSeconds(10);

        private readonly IServiceScopeFactory _scopeFactory;
        private readonly ILogger<NotificationDispatchBackgroundService> _logger;

        public NotificationDispatchBackgroundService(
            IServiceScopeFactory scopeFactory,
            ILogger<NotificationDispatchBackgroundService> logger)
        {
            _scopeFactory = scopeFactory;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    var processedCount = await ProcessBatchAsync(stoppingToken);
                    if (processedCount == 0)
                    {
                        await Task.Delay(PollInterval, stoppingToken);
                    }
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    // graceful shutdown
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Notification outbox worker gặp lỗi ngoài dự kiến.");
                    await Task.Delay(PollInterval, stoppingToken);
                }
            }
        }

        private async Task<int> ProcessBatchAsync(CancellationToken cancellationToken)
        {
            await using var scope = _scopeFactory.CreateAsyncScope();
            var dbContext = scope.ServiceProvider.GetRequiredService<UniYouthDbContext>();
            var pushService = scope.ServiceProvider.GetRequiredService<IPushNotificationService>();
            var realtimeDispatcher = scope.ServiceProvider.GetRequiredService<INotificationRealtimeDispatcher>();

            var now = DateTime.Now;
            await RecoverStuckProcessingEntriesAsync(dbContext, now, cancellationToken);

            var candidateIds = await dbContext.NotificationOutboxes
                .Where(o =>
                    o.Status == (byte)NotificationOutboxStatus.Pending &&
                    (!o.NextAttemptAt.HasValue || o.NextAttemptAt.Value <= now))
                .OrderBy(o => o.NextAttemptAt)
                .ThenBy(o => o.OutboxID)
                .Select(o => o.OutboxID)
                .Take(BatchSize)
                .ToListAsync(cancellationToken);

            if (candidateIds.Count == 0)
            {
                return 0;
            }

            var processedCount = 0;

            foreach (var outboxId in candidateIds)
            {
                var claimed = await TryClaimAsync(dbContext, outboxId, cancellationToken);
                if (!claimed)
                {
                    continue;
                }

                processedCount++;
                await ProcessOneAsync(
                    dbContext,
                    outboxId,
                    pushService,
                    realtimeDispatcher,
                    cancellationToken);
            }

            return processedCount;
        }

        private async Task<bool> TryClaimAsync(
            UniYouthDbContext dbContext,
            int outboxId,
            CancellationToken cancellationToken)
        {
            var now = DateTime.Now;

            var claimedRows = await dbContext.NotificationOutboxes
                .Where(o =>
                    o.OutboxID == outboxId &&
                    o.Status == (byte)NotificationOutboxStatus.Pending &&
                    (!o.NextAttemptAt.HasValue || o.NextAttemptAt.Value <= now))
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(o => o.Status, (byte)NotificationOutboxStatus.Processing)
                    .SetProperty(o => o.AttemptCount, o => o.AttemptCount + 1)
                    .SetProperty(o => o.LastAttemptAt, now)
                    .SetProperty(o => o.UpdatedDate, now), cancellationToken);

            return claimedRows > 0;
        }

        private async Task ProcessOneAsync(
            UniYouthDbContext dbContext,
            int outboxId,
            IPushNotificationService pushService,
            INotificationRealtimeDispatcher realtimeDispatcher,
            CancellationToken cancellationToken)
        {
            var outbox = await dbContext.NotificationOutboxes
                .FirstAsync(o => o.OutboxID == outboxId, cancellationToken);

            var notification = await dbContext.Notifications
                .AsNoTracking()
                .FirstOrDefaultAsync(n => n.NotificationID == outbox.NotificationID, cancellationToken);

            if (notification == null)
            {
                await MarkFailureAsync(
                    dbContext,
                    outbox,
                    "Notification không tồn tại khi xử lý outbox.",
                    cancellationToken);
                return;
            }

            var dispatchDecision = await EvaluateDispatchDecisionAsync(
                dbContext,
                outbox,
                notification,
                cancellationToken);

            if (dispatchDecision.Action == DispatchAction.SuppressGrouped)
            {
                await MarkGroupedSuppressedAsync(
                    dbContext,
                    outbox,
                    dispatchDecision.Reason,
                    cancellationToken);
                return;
            }

            if (dispatchDecision.Action == DispatchAction.DeferThrottled)
            {
                await MarkThrottledDeferredAsync(
                    dbContext,
                    outbox,
                    dispatchDecision.Reason,
                    dispatchDecision.NextAttemptAt ?? DateTime.Now.AddSeconds(5),
                    cancellationToken);
                return;
            }

            try
            {
                await DispatchAsync(
                    dbContext,
                    notification,
                    outbox,
                    pushService,
                    realtimeDispatcher,
                    cancellationToken);

                var now = DateTime.Now;
                outbox.Status = (byte)NotificationOutboxStatus.Succeeded;
                outbox.ProcessedAt = now;
                outbox.UpdatedDate = now;
                outbox.LastError = null;

                dbContext.NotificationDeliveryLogs.Add(new NotificationDeliveryLog
                {
                    OutboxID = outbox.OutboxID,
                    NotificationID = outbox.NotificationID,
                    UserID = outbox.UserID,
                    Channel = outbox.Channel,
                    AttemptNumber = outbox.AttemptCount,
                    IsSuccess = true,
                    ErrorMessage = null,
                    CreatedDate = now
                });

                await dbContext.SaveChangesAsync(cancellationToken);
            }
            catch (Exception ex)
            {
                await MarkFailureAsync(dbContext, outbox, ex.Message, cancellationToken);
            }
        }

        private async Task<DispatchDecision> EvaluateDispatchDecisionAsync(
            UniYouthDbContext dbContext,
            NotificationOutbox outbox,
            Notification notification,
            CancellationToken cancellationToken)
        {
            var channel = (NotificationChannel)outbox.Channel;
            if (channel is not NotificationChannel.Push and not NotificationChannel.Realtime)
            {
                return DispatchDecision.Dispatch();
            }

            var notificationCreatedAt = notification.CreatedDate ?? DateTime.Now;

            var hasNewerInWindow = await dbContext.NotificationOutboxes
                .Join(
                    dbContext.Notifications,
                    o => o.NotificationID,
                    n => n.NotificationID,
                    (o, n) => new { Outbox = o, Notification = n })
                .Where(x =>
                    x.Outbox.OutboxID != outbox.OutboxID &&
                    x.Outbox.UserID == outbox.UserID &&
                    x.Outbox.Channel == outbox.Channel &&
                    (x.Outbox.Status == (byte)NotificationOutboxStatus.Pending
                     || x.Outbox.Status == (byte)NotificationOutboxStatus.Processing
                     || x.Outbox.Status == (byte)NotificationOutboxStatus.Succeeded) &&
                    x.Notification.NotificationTypeID == notification.NotificationTypeID &&
                    x.Notification.EventID == notification.EventID &&
                    (x.Notification.CreatedDate ?? notificationCreatedAt) > notificationCreatedAt &&
                    (x.Notification.CreatedDate ?? notificationCreatedAt) <= notificationCreatedAt.Add(GroupingWindow))
                .AnyAsync(cancellationToken);

            if (hasNewerInWindow)
            {
                return DispatchDecision.SuppressGrouped(
                    "Grouped by window: newer notification exists in grouping window.");
            }

            var throttleWindow = channel == NotificationChannel.Push
                ? PushThrottleWindow
                : RealtimeThrottleWindow;
            var now = DateTime.Now;

            var lastSuccessfulDispatchAt = await dbContext.NotificationDeliveryLogs
                .Join(
                    dbContext.NotificationOutboxes,
                    log => log.OutboxID,
                    ob => ob.OutboxID,
                    (log, ob) => new { Log = log, Outbox = ob })
                .Join(
                    dbContext.Notifications,
                    combined => combined.Outbox.NotificationID,
                    n => n.NotificationID,
                    (combined, n) => new { combined.Log, combined.Outbox, Notification = n })
                .Where(x =>
                    x.Log.IsSuccess &&
                    x.Outbox.UserID == outbox.UserID &&
                    x.Outbox.Channel == outbox.Channel &&
                    x.Notification.NotificationTypeID == notification.NotificationTypeID &&
                    x.Notification.EventID == notification.EventID)
                .Select(x => (DateTime?)x.Log.CreatedDate)
                .OrderByDescending(x => x)
                .FirstOrDefaultAsync(cancellationToken);

            if (lastSuccessfulDispatchAt.HasValue)
            {
                var elapsed = now - lastSuccessfulDispatchAt.Value;
                if (elapsed < throttleWindow)
                {
                    var nextAttemptAt = lastSuccessfulDispatchAt.Value.Add(throttleWindow);
                    return DispatchDecision.DeferThrottled(
                        $"Throttled by window: wait until {nextAttemptAt:O}.",
                        nextAttemptAt);
                }
            }

            return DispatchDecision.Dispatch();
        }

        private async Task MarkGroupedSuppressedAsync(
            UniYouthDbContext dbContext,
            NotificationOutbox outbox,
            string reason,
            CancellationToken cancellationToken)
        {
            var now = DateTime.Now;
            var message = Truncate(reason, 1000);

            outbox.Status = (byte)NotificationOutboxStatus.Succeeded;
            outbox.ProcessedAt = now;
            outbox.UpdatedDate = now;
            outbox.LastError = message;

            dbContext.NotificationDeliveryLogs.Add(new NotificationDeliveryLog
            {
                OutboxID = outbox.OutboxID,
                NotificationID = outbox.NotificationID,
                UserID = outbox.UserID,
                Channel = outbox.Channel,
                AttemptNumber = outbox.AttemptCount,
                IsSuccess = true,
                ErrorMessage = message,
                CreatedDate = now
            });

            await dbContext.SaveChangesAsync(cancellationToken);
        }

        private async Task MarkThrottledDeferredAsync(
            UniYouthDbContext dbContext,
            NotificationOutbox outbox,
            string reason,
            DateTime nextAttemptAt,
            CancellationToken cancellationToken)
        {
            var now = DateTime.Now;
            var message = Truncate(reason, 1000);

            outbox.Status = (byte)NotificationOutboxStatus.Pending;
            outbox.NextAttemptAt = nextAttemptAt;
            outbox.AttemptCount = Math.Max(0, outbox.AttemptCount - 1);
            outbox.ProcessedAt = null;
            outbox.UpdatedDate = now;
            outbox.LastError = message;

            dbContext.NotificationDeliveryLogs.Add(new NotificationDeliveryLog
            {
                OutboxID = outbox.OutboxID,
                NotificationID = outbox.NotificationID,
                UserID = outbox.UserID,
                Channel = outbox.Channel,
                AttemptNumber = outbox.AttemptCount,
                IsSuccess = false,
                ErrorMessage = message,
                CreatedDate = now
            });

            await dbContext.SaveChangesAsync(cancellationToken);
        }

        private static async Task DispatchAsync(
            UniYouthDbContext dbContext,
            Notification notification,
            NotificationOutbox outbox,
            IPushNotificationService pushService,
            INotificationRealtimeDispatcher realtimeDispatcher,
            CancellationToken cancellationToken)
        {
            var channel = (NotificationChannel)outbox.Channel;
            var notificationType = ResolveNotificationTypeName(notification.NotificationTypeID);

            if (channel == NotificationChannel.Push)
            {
                await pushService.SendToUserAsync(
                    notification.UserID,
                    new PushMessage(
                        Title: notification.Title,
                        Body: notification.Content,
                        Data: new Dictionary<string, string?>
                        {
                            ["notificationId"] = notification.NotificationID.ToString(),
                            ["eventId"] = notification.EventID?.ToString() ?? string.Empty,
                            ["actionUrl"] = notification.ActionUrl ?? string.Empty,
                            ["type"] = notificationType,
                            ["audience"] = notification.Audience,
                            ["targetRole"] = notification.TargetRole
                        }
                        .Where(kvp => !string.IsNullOrWhiteSpace(kvp.Value))
                        .ToDictionary(kvp => kvp.Key, kvp => kvp.Value!)),
                    cancellationToken);
                return;
            }

            if (channel == NotificationChannel.Realtime)
            {
                var unreadCount = await dbContext.Notifications
                    .Where(n => n.UserID == notification.UserID && n.IsRead != true)
                    .CountAsync(cancellationToken);

                await realtimeDispatcher.DispatchCreatedAsync(
                    new NotificationRealtimePayload(
                        NotificationId: notification.NotificationID,
                        UserId: notification.UserID,
                        EventId: notification.EventID,
                        Title: notification.Title,
                        Content: notification.Content,
                        Type: notificationType,
                        Priority: notification.Priority ?? 0,
                        ActionUrl: notification.ActionUrl,
                        CreatedDate: notification.CreatedDate ?? DateTime.Now,
                        Audience: notification.Audience,
                        TargetRole: notification.TargetRole,
                        UnreadCount: unreadCount),
                    cancellationToken);
                return;
            }

            throw new InvalidOperationException($"Channel outbox không hợp lệ: {outbox.Channel}");
        }

        private async Task MarkFailureAsync(
            UniYouthDbContext dbContext,
            NotificationOutbox outbox,
            string errorMessage,
            CancellationToken cancellationToken)
        {
            var now = DateTime.Now;
            var sanitizedError = Truncate(errorMessage, 1000);
            var hasMoreAttempts = outbox.AttemptCount < outbox.MaxAttempts;

            outbox.Status = hasMoreAttempts
                ? (byte)NotificationOutboxStatus.Pending
                : (byte)NotificationOutboxStatus.Failed;
            outbox.NextAttemptAt = hasMoreAttempts
                ? now.Add(GetRetryDelay(outbox.AttemptCount))
                : now;
            outbox.ProcessedAt = hasMoreAttempts ? null : now;
            outbox.UpdatedDate = now;
            outbox.LastError = sanitizedError;

            dbContext.NotificationDeliveryLogs.Add(new NotificationDeliveryLog
            {
                OutboxID = outbox.OutboxID,
                NotificationID = outbox.NotificationID,
                UserID = outbox.UserID,
                Channel = outbox.Channel,
                AttemptNumber = outbox.AttemptCount,
                IsSuccess = false,
                ErrorMessage = sanitizedError,
                CreatedDate = now
            });

            await dbContext.SaveChangesAsync(cancellationToken);
        }

        private static async Task RecoverStuckProcessingEntriesAsync(
            UniYouthDbContext dbContext,
            DateTime now,
            CancellationToken cancellationToken)
        {
            var staleThreshold = now.Subtract(ProcessingTimeout);

            await dbContext.NotificationOutboxes
                .Where(o =>
                    o.Status == (byte)NotificationOutboxStatus.Processing &&
                    o.LastAttemptAt.HasValue &&
                    o.LastAttemptAt.Value <= staleThreshold)
                .ExecuteUpdateAsync(setters => setters
                    .SetProperty(o => o.Status, (byte)NotificationOutboxStatus.Pending)
                    .SetProperty(o => o.NextAttemptAt, now)
                    .SetProperty(o => o.UpdatedDate, now), cancellationToken);
        }

        private static string ResolveNotificationTypeName(int notificationTypeId)
        {
            return Enum.IsDefined(typeof(NotificationTypeEnum), notificationTypeId)
                ? ((NotificationTypeEnum)notificationTypeId).ToString()
                : notificationTypeId.ToString();
        }

        private static TimeSpan GetRetryDelay(int attemptCount)
        {
            var seconds = Math.Clamp(attemptCount * 30, 30, 300);
            return TimeSpan.FromSeconds(seconds);
        }

        private static string Truncate(string value, int maxLength)
        {
            if (string.IsNullOrWhiteSpace(value))
            {
                return string.Empty;
            }

            return value.Length <= maxLength ? value : value[..maxLength];
        }

        private enum DispatchAction : byte
        {
            Dispatch = 0,
            SuppressGrouped = 1,
            DeferThrottled = 2
        }

        private sealed record DispatchDecision(
            DispatchAction Action,
            string Reason,
            DateTime? NextAttemptAt = null)
        {
            public static DispatchDecision Dispatch() =>
                new(DispatchAction.Dispatch, string.Empty);

            public static DispatchDecision SuppressGrouped(string reason) =>
                new(DispatchAction.SuppressGrouped, reason);

            public static DispatchDecision DeferThrottled(string reason, DateTime nextAttemptAt) =>
                new(DispatchAction.DeferThrottled, reason, nextAttemptAt);
        }
    }
}
