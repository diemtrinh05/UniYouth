using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Infrastructure.Data;

namespace UniYouth.Api.Application.Services.NotificationsSupport;

public sealed class NotificationMaintenanceService
{
    private readonly UniYouthDbContext _context;
    private readonly ILogger _logger;

    public NotificationMaintenanceService(UniYouthDbContext context, ILogger logger)
    {
        _context = context;
        _logger = logger;
    }

    public async Task<int> DeleteExpiredNotificationsAsync()
    {
        var now = DateTime.Now;
        var deletedCount = await _context.Notifications
            .Where(n => n.ExpiryDate.HasValue && n.ExpiryDate.Value < now)
            .ExecuteDeleteAsync();

        if (deletedCount > 0)
        {
            _logger.LogInformation("Đã xóa {Count} thông báo hết hạn", deletedCount);
        }

        return deletedCount;
    }

    public async Task<int> ArchiveOldNotificationsAsync(int batchSize = 500, int retentionDays = 90)
    {
        if (batchSize < 1) batchSize = 500;
        if (retentionDays < 1) retentionDays = 90;

        var archiveBefore = DateTime.Now.AddDays(-retentionDays);
        var candidates = await _context.Notifications
            .AsNoTracking()
            .Where(n => n.IsRead == true && n.CreatedDate.HasValue && n.CreatedDate.Value < archiveBefore)
            .OrderBy(n => n.NotificationID)
            .Take(batchSize)
            .ToListAsync();

        if (candidates.Count == 0)
        {
            return 0;
        }

        var candidateIds = candidates.Select(n => n.NotificationID).ToList();
        var executionStrategy = _context.Database.CreateExecutionStrategy();
        var deletedCount = 0;

        await executionStrategy.ExecuteAsync(async () =>
        {
            await using var transaction = await _context.Database.BeginTransactionAsync();
            try
            {
                var existingArchiveIds = await _context.NotificationArchives
                    .AsNoTracking()
                    .Where(a => candidateIds.Contains(a.NotificationID))
                    .Select(a => a.NotificationID)
                    .ToListAsync();

                var existingArchiveIdSet = existingArchiveIds.ToHashSet();
                var now = DateTime.Now;
                var archivesToInsert = candidates
                    .Where(n => !existingArchiveIdSet.Contains(n.NotificationID))
                    .Select(n => new UniYouth.Api.Domain.Entities.NotificationArchive
                    {
                        NotificationID = n.NotificationID,
                        UserID = n.UserID,
                        EventID = n.EventID,
                        Title = n.Title,
                        Content = n.Content,
                        NotificationTypeID = n.NotificationTypeID,
                        Priority = n.Priority,
                        IsRead = n.IsRead,
                        ReadDate = n.ReadDate,
                        ActionUrl = n.ActionUrl,
                        DedupKey = n.DedupKey,
                        Audience = n.Audience,
                        TargetRole = n.TargetRole,
                        CreatedDate = n.CreatedDate,
                        ExpiryDate = n.ExpiryDate,
                        ArchivedDate = now,
                        ArchiveReason = "Retention policy"
                    })
                    .ToList();

                if (archivesToInsert.Count > 0)
                {
                    _context.NotificationArchives.AddRange(archivesToInsert);
                    await _context.SaveChangesAsync();
                }

                deletedCount = await _context.Notifications
                    .Where(n => candidateIds.Contains(n.NotificationID))
                    .ExecuteDeleteAsync();

                await transaction.CommitAsync();
            }
            catch
            {
                await transaction.RollbackAsync();
                throw;
            }
        });

        if (deletedCount > 0)
        {
            _logger.LogInformation("Đã archive {Count} thông báo cũ trước {ArchiveBefore}", deletedCount, archiveBefore);
        }

        return deletedCount;
    }
}
