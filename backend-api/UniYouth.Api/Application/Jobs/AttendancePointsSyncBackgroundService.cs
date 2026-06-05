using UniYouth.Api.Application.Services;

namespace UniYouth.Api.Application.Jobs
{
    /// <summary>
    /// Background job tiêu thụ queue để đồng bộ điểm Attendance theo EventPoints(Participant).
    /// Trigger chính: khi admin tạo/cập nhật EventPoints cho event.
    /// </summary>
    public class AttendancePointsSyncBackgroundService : BackgroundService
    {
        private readonly IServiceScopeFactory _scopeFactory;
        private readonly IAttendancePointsSyncQueue _queue;
        private readonly ILogger<AttendancePointsSyncBackgroundService> _logger;

        public AttendancePointsSyncBackgroundService(
            IServiceScopeFactory scopeFactory,
            IAttendancePointsSyncQueue queue,
            ILogger<AttendancePointsSyncBackgroundService> logger)
        {
            _scopeFactory = scopeFactory;
            _queue = queue;
            _logger = logger;
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                int eventId = 0;
                try
                {
                    eventId = await _queue.DequeueAsync(stoppingToken);

                    await using var scope = _scopeFactory.CreateAsyncScope();
                    var syncService = scope.ServiceProvider.GetRequiredService<IAttendancePointsSyncService>();

                    var result = await syncService.SyncAttendancePointsForEventAsync(eventId, stoppingToken);
                    _logger.LogInformation(
                        "AttendancePointsSync job finished. EventId={EventId}, HasConfig={HasConfig}, Updated={Updated}, Inserted={Inserted}",
                        result.EventId, result.HasParticipantPointConfig, result.UpdatedCount, result.InsertedCount);
                }
                catch (OperationCanceledException) when (stoppingToken.IsCancellationRequested)
                {
                    // graceful shutdown
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex,
                        "AttendancePointsSync job failed. EventId={EventId}",
                        eventId);
                }
                finally
                {
                    if (eventId > 0)
                    {
                        _queue.TryMarkDone(eventId);
                    }
                }
            }
        }
    }
}

