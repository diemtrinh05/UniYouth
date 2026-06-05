using System.Text.Json;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;

namespace UniYouth.Api.Application.Services.AttendanceSupport;

public sealed class AttendanceAuditService
{
    private readonly UniYouthDbContext _context;

    public AttendanceAuditService(UniYouthDbContext context)
    {
        _context = context;
    }

    public async Task WriteAsync(
        int userId,
        string action,
        string? tableName,
        int? recordId,
        object details,
        string? ipAddress,
        string? userAgent,
        DateTime nowUtc)
    {
        var audit = new AuditLog
        {
            UserID = userId,
            Action = action,
            TableName = tableName,
            RecordID = recordId,
            OldValue = null,
            NewValue = JsonSerializer.Serialize(details),
            IPAddress = ipAddress,
            UserAgent = userAgent,
            CreatedDate = nowUtc
        };

        _context.AuditLogs.Add(audit);
        await _context.SaveChangesAsync();
    }
}
