using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Application.Templates;
using UniYouth.Api.Contracts.DTOs.Notifications;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Application.Services.NotificationsSupport;

public sealed class NotificationComposerService
{
    private readonly UniYouthDbContext _context;
    private readonly ILogger _logger;
    private readonly NotificationRoutingService _routingService;

    public NotificationComposerService(
        UniYouthDbContext context,
        ILogger logger,
        NotificationRoutingService routingService)
    {
        _context = context;
        _logger = logger;
        _routingService = routingService;
    }

    public async Task<int> CreateNotificationAsync(CreateNotificationDto dto)
    {
        var dedupKey = string.IsNullOrWhiteSpace(dto.DedupKey) ? null : dto.DedupKey.Trim();
        var routingMetadata = await _routingService.ResolveAudienceAndTargetRoleAsync(dto.UserID, dto.Audience, dto.TargetRole);

        if (dedupKey != null)
        {
            var existingNotificationId = await _context.Notifications
                .AsNoTracking()
                .Where(n => n.DedupKey == dedupKey)
                .Select(n => (int?)n.NotificationID)
                .FirstOrDefaultAsync();

            if (existingNotificationId.HasValue)
            {
                _logger.LogInformation(
                    "Bỏ qua tạo trùng notification theo DedupKey. NotificationID={NotificationId}, DedupKey={DedupKey}",
                    existingNotificationId.Value,
                    dedupKey);
                return existingNotificationId.Value;
            }
        }

        var notification = new Notification
        {
            UserID = dto.UserID,
            EventID = dto.EventID,
            Title = dto.Title,
            Content = dto.Content,
            NotificationTypeID = (int)dto.NotificationType,
            Priority = (byte)dto.Priority,
            IsRead = false,
            ActionUrl = dto.ActionUrl,
            DedupKey = dedupKey,
            Audience = routingMetadata.Audience.ToString(),
            TargetRole = routingMetadata.TargetRole,
            ExpiryDate = dto.ExpiryDate ?? NotificationComposerSupport.GetDefaultExpiryDate(dto.NotificationType),
            CreatedDate = DateTime.Now
        };

        var outboxEntries = _routingService.BuildOutboxEntries(notification, routingMetadata.Audience);
        _context.Notifications.Add(notification);
        if (outboxEntries.Count > 0)
        {
            _context.NotificationOutboxes.AddRange(outboxEntries);
        }

        try
        {
            await _context.SaveChangesAsync();
        }
        catch (DbUpdateException ex) when (dedupKey != null && NotificationRoutingService.IsNotificationDedupConflict(ex))
        {
            _routingService.DetachPendingOutboxEntriesFor(notification);
            _context.Entry(notification).State = EntityState.Detached;

            var existingNotificationId = await _context.Notifications
                .AsNoTracking()
                .Where(n => n.DedupKey == dedupKey)
                .Select(n => (int?)n.NotificationID)
                .FirstOrDefaultAsync();

            if (existingNotificationId.HasValue)
            {
                _logger.LogInformation(
                    "Phát hiện race condition tạo trùng notification, trả về bản ghi đã tồn tại. NotificationID={NotificationId}, DedupKey={DedupKey}",
                    existingNotificationId.Value,
                    dedupKey);
                return existingNotificationId.Value;
            }

            throw;
        }

        _logger.LogInformation(
            "Đã tạo thông báo mới: NotificationID={NotificationId}, UserID={UserId}, Type={TypeId}",
            notification.NotificationID,
            dto.UserID,
            dto.NotificationType);

        _logger.LogInformation(
            "Đã enqueue {OutboxCount} bản ghi outbox cho NotificationID={NotificationId}, Audience={Audience}",
            outboxEntries.Count,
            notification.NotificationID,
            routingMetadata.Audience);

        return notification.NotificationID;
    }

    public Task CreateEventRegistrationNotificationAsync(int userId, int eventId, string eventName)
    {
        var template = NotificationTemplateEngine.Render(
            NotificationTemplateKey.EventRegistrationSuccess,
            new Dictionary<string, string?>
            {
                ["EventName"] = eventName
            });

        return CreateNotificationAsync(new CreateNotificationDto
        {
            UserID = userId,
            EventID = eventId,
            Title = template.Title,
            Content = template.Content,
            NotificationType = NotificationTypeEnum.EventRegistration,
            Priority = NotificationComposerSupport.GetPriorityByFlow(NotificationFlowType.EventRegistrationSuccess),
            ActionUrl = $"/events/{eventId}",
            DedupKey = NotificationComposerSupport.BuildDedupKey("event-registration-success", userId.ToString(), eventId.ToString(), eventName),
            Audience = NotificationAudience.MobileMember
        });
    }

    public Task CreateEventCancelRegistrationNotificationAsync(int userId, int eventId, string eventName, string? reason)
    {
        var reasonSuffix = string.IsNullOrWhiteSpace(reason) ? string.Empty : $" Lý do: {reason.Trim()}";
        var template = NotificationTemplateEngine.Render(
            NotificationTemplateKey.EventRegistrationCancel,
            new Dictionary<string, string?>
            {
                ["EventName"] = eventName,
                ["ReasonSuffix"] = reasonSuffix
            });

        return CreateNotificationAsync(new CreateNotificationDto
        {
            UserID = userId,
            EventID = eventId,
            Title = template.Title,
            Content = template.Content,
            NotificationType = NotificationTypeEnum.EventRegistration,
            Priority = NotificationComposerSupport.GetPriorityByFlow(NotificationFlowType.EventRegistrationCancel),
            ActionUrl = $"/events/{eventId}",
            DedupKey = NotificationComposerSupport.BuildDedupKey("event-registration-cancel", userId.ToString(), eventId.ToString(), eventName, reason),
            Audience = NotificationAudience.MobileMember
        });
    }

    public Task CreateAttendanceNotificationAsync(int userId, int eventId, string eventName, bool isValid, int? pointsEarned = null, string? invalidReason = null)
    {
        var pointsSuffix = pointsEarned.HasValue && isValid ? $" Bạn được cộng {pointsEarned.Value} điểm rèn luyện." : string.Empty;
        var invalidReasonSuffix = !isValid && !string.IsNullOrWhiteSpace(invalidReason) ? $" Lý do: {invalidReason.Trim()}" : string.Empty;
        var template = NotificationTemplateEngine.Render(
            isValid ? NotificationTemplateKey.AttendanceValid : NotificationTemplateKey.AttendanceInvalid,
            new Dictionary<string, string?>
            {
                ["EventName"] = eventName,
                ["PointsSuffix"] = pointsSuffix,
                ["InvalidReasonSuffix"] = invalidReasonSuffix
            });

        return CreateNotificationAsync(new CreateNotificationDto
        {
            UserID = userId,
            EventID = eventId,
            Title = template.Title,
            Content = template.Content,
            NotificationType = NotificationTypeEnum.Attendance,
            Priority = isValid
                ? NotificationComposerSupport.GetPriorityByFlow(NotificationFlowType.AttendanceValid)
                : NotificationComposerSupport.GetPriorityByFlow(NotificationFlowType.AttendanceInvalid),
            ActionUrl = $"/events/{eventId}",
            DedupKey = NotificationComposerSupport.BuildDedupKey(
                "attendance-checkin",
                userId.ToString(),
                eventId.ToString(),
                isValid.ToString(),
                pointsEarned?.ToString(),
                invalidReason),
            Audience = NotificationAudience.MobileMember
        });
    }

    public async Task CreateEventUpdateNotificationsAsync(int eventId, string eventName, string updateMessage)
    {
        var template = NotificationTemplateEngine.Render(
            NotificationTemplateKey.EventUpdateBroadcast,
            new Dictionary<string, string?>
            {
                ["EventName"] = eventName,
                ["UpdateMessage"] = updateMessage
            });

        var registeredUserIds = await _context.EventRegistrations
            .Where(er => er.EventID == eventId && er.Status == (int)Shared.Enums.RegistrationStatus.Registered)
            .Select(er => er.UserID)
            .Distinct()
            .ToListAsync();

        if (!registeredUserIds.Any())
        {
            _logger.LogInformation("Không có người dùng nào đăng ký sự kiện EventID={EventId}", eventId);
            return;
        }

        foreach (var userId in registeredUserIds)
        {
            await CreateNotificationAsync(new CreateNotificationDto
            {
                UserID = userId,
                EventID = eventId,
                Title = template.Title,
                Content = template.Content,
                NotificationType = NotificationTypeEnum.EventUpdate,
                Priority = NotificationComposerSupport.GetPriorityByFlow(NotificationFlowType.EventUpdateBroadcast),
                ActionUrl = $"/events/{eventId}",
                DedupKey = NotificationComposerSupport.BuildDedupKey("event-update", userId.ToString(), eventId.ToString(), updateMessage),
                Audience = NotificationAudience.MobileMember
            });
        }

        _logger.LogInformation("Đã tạo {Count} thông báo cập nhật sự kiện cho EventID={EventId}", registeredUserIds.Count, eventId);
    }

    public async Task CreateEventCancellationNotificationsAsync(int eventId, string eventName, string? reason)
    {
        var reasonSuffix = string.IsNullOrWhiteSpace(reason) ? string.Empty : $" Lý do: {reason.Trim()}";
        var template = NotificationTemplateEngine.Render(
            NotificationTemplateKey.EventCancellationBroadcast,
            new Dictionary<string, string?>
            {
                ["EventName"] = eventName,
                ["ReasonSuffix"] = reasonSuffix
            });

        var registeredUserIds = await _context.EventRegistrations
            .Where(er => er.EventID == eventId && er.Status == (int)Shared.Enums.RegistrationStatus.Registered)
            .Select(er => er.UserID)
            .Distinct()
            .ToListAsync();

        if (!registeredUserIds.Any())
        {
            _logger.LogInformation("Không có người dùng nào đăng ký sự kiện EventID={EventId} để gửi thông báo hủy", eventId);
            return;
        }

        foreach (var userId in registeredUserIds)
        {
            await CreateNotificationAsync(new CreateNotificationDto
            {
                UserID = userId,
                EventID = eventId,
                Title = template.Title,
                Content = template.Content,
                NotificationType = NotificationTypeEnum.EventCancellation,
                Priority = NotificationComposerSupport.GetPriorityByFlow(NotificationFlowType.EventCancellationBroadcast),
                ActionUrl = $"/events/{eventId}",
                DedupKey = NotificationComposerSupport.BuildDedupKey("event-cancel", userId.ToString(), eventId.ToString(), reason),
                Audience = NotificationAudience.MobileMember
            });
        }

        _logger.LogInformation("Đã tạo {Count} thông báo hủy sự kiện cho EventID={EventId}", registeredUserIds.Count, eventId);
    }

    public async Task CreateEventCapacityFullAlertAsync(int eventId, string eventName, int currentParticipants, int maxParticipants)
    {
        var managerUserIds = await _routingService.GetWebAlertRecipientUserIdsAsync(eventId);
        if (!managerUserIds.Any())
        {
            _logger.LogWarning("Không tìm thấy user quản trị để gửi alert EventFull. EventID={EventId}", eventId);
            return;
        }

        var template = NotificationTemplateEngine.Render(
            NotificationTemplateKey.EventCapacityFullAlert,
            new Dictionary<string, string?>
            {
                ["EventName"] = eventName,
                ["CurrentParticipants"] = currentParticipants.ToString(),
                ["MaxParticipants"] = maxParticipants.ToString()
            });

        foreach (var managerUserId in managerUserIds)
        {
            await CreateNotificationAsync(new CreateNotificationDto
            {
                UserID = managerUserId,
                EventID = eventId,
                Title = template.Title,
                Content = template.Content,
                NotificationType = NotificationTypeEnum.System,
                Priority = NotificationComposerSupport.GetPriorityByFlow(NotificationFlowType.EventCapacityFullAlert),
                ActionUrl = $"/events/{eventId}",
                DedupKey = NotificationComposerSupport.BuildDedupKey("web-alert-event-full", managerUserId.ToString(), eventId.ToString(), maxParticipants.ToString()),
                Audience = null
            });
        }

        _logger.LogInformation("Đã tạo alert EventFull cho {Count} user quản trị. EventID={EventId}", managerUserIds.Count, eventId);
    }

    public async Task CreateQrScanLimitReachedAlertAsync(int eventId, string eventName, int qrId, int currentScans, int scanLimit)
    {
        var managerUserIds = await _routingService.GetWebAlertRecipientUserIdsAsync(eventId);
        if (!managerUserIds.Any())
        {
            _logger.LogWarning("Không tìm thấy user quản trị để gửi alert QrScanLimitReached. EventID={EventId}, QRID={QrId}", eventId, qrId);
            return;
        }

        var template = NotificationTemplateEngine.Render(
            NotificationTemplateKey.QrScanLimitReachedAlert,
            new Dictionary<string, string?>
            {
                ["EventName"] = eventName,
                ["CurrentScans"] = currentScans.ToString(),
                ["ScanLimit"] = scanLimit.ToString()
            });

        foreach (var managerUserId in managerUserIds)
        {
            await CreateNotificationAsync(new CreateNotificationDto
            {
                UserID = managerUserId,
                EventID = eventId,
                Title = template.Title,
                Content = template.Content,
                NotificationType = NotificationTypeEnum.System,
                Priority = NotificationComposerSupport.GetPriorityByFlow(NotificationFlowType.QrScanLimitReachedAlert),
                ActionUrl = $"/events/{eventId}/qrcode",
                DedupKey = NotificationComposerSupport.BuildDedupKey("web-alert-qr-scan-limit", managerUserId.ToString(), eventId.ToString(), qrId.ToString(), scanLimit.ToString()),
                Audience = null
            });
        }

        _logger.LogInformation("Đã tạo alert QrScanLimitReached cho {Count} user quản trị. EventID={EventId}, QRID={QrId}", managerUserIds.Count, eventId, qrId);
    }

    public async Task CreateQrDeactivatedAlertAsync(int eventId, string eventName, int qrId, int deactivatedByUserId)
    {
        var managerUserIds = await _routingService.GetWebAlertRecipientUserIdsAsync(eventId);
        if (!managerUserIds.Any())
        {
            _logger.LogWarning("Không tìm thấy user quản trị để gửi alert QrDeactivated. EventID={EventId}, QRID={QrId}", eventId, qrId);
            return;
        }

        var actorName = await _context.Users
            .AsNoTracking()
            .Where(u => u.UserID == deactivatedByUserId)
            .Select(u => u.FullName)
            .FirstOrDefaultAsync();

        var template = NotificationTemplateEngine.Render(
            NotificationTemplateKey.QrDeactivatedAlert,
            new Dictionary<string, string?>
            {
                ["EventName"] = eventName,
                ["QrId"] = qrId.ToString(),
                ["ActorName"] = string.IsNullOrWhiteSpace(actorName) ? $"User {deactivatedByUserId}" : actorName
            });

        foreach (var managerUserId in managerUserIds)
        {
            await CreateNotificationAsync(new CreateNotificationDto
            {
                UserID = managerUserId,
                EventID = eventId,
                Title = template.Title,
                Content = template.Content,
                NotificationType = NotificationTypeEnum.System,
                Priority = NotificationComposerSupport.GetPriorityByFlow(NotificationFlowType.QrDeactivatedAlert),
                ActionUrl = $"/events/{eventId}/qrcode",
                DedupKey = NotificationComposerSupport.BuildDedupKey("web-alert-qr-deactivated", managerUserId.ToString(), eventId.ToString(), qrId.ToString(), deactivatedByUserId.ToString()),
                Audience = null
            });
        }

        _logger.LogInformation("Đã tạo alert QrDeactivated cho {Count} user quản trị. EventID={EventId}, QRID={QrId}, DeactivatedByUserID={UserId}", managerUserIds.Count, eventId, qrId, deactivatedByUserId);
    }

    public Task CreateActorEventActionConfirmationAsync(int actorUserId, int eventId, string eventName, string actionName, string? actionDetail = null, long? operationStamp = null)
    {
        if (string.IsNullOrWhiteSpace(actionName))
        {
            return Task.CompletedTask;
        }

        var detailSuffix = string.IsNullOrWhiteSpace(actionDetail) ? string.Empty : $" Chi tiết: {actionDetail.Trim()}";
        var template = NotificationTemplateEngine.Render(
            NotificationTemplateKey.ActorEventActionConfirmation,
            new Dictionary<string, string?>
            {
                ["ActionName"] = actionName.Trim(),
                ["EventName"] = eventName,
                ["DetailSuffix"] = detailSuffix
            });

        return CreateNotificationAsync(new CreateNotificationDto
        {
            UserID = actorUserId,
            EventID = eventId,
            Title = template.Title,
            Content = template.Content,
            NotificationType = NotificationTypeEnum.System,
            Priority = NotificationComposerSupport.GetPriorityByFlow(NotificationFlowType.ActorEventActionConfirmation),
            ActionUrl = $"/events/{eventId}",
            DedupKey = NotificationComposerSupport.BuildDedupKey("actor-event-action", actorUserId.ToString(), eventId.ToString(), actionName, actionDetail, operationStamp?.ToString()),
            Audience = null
        });
    }

    public Task CreateActorEventQrActionConfirmationAsync(int actorUserId, int eventId, string eventName, int qrId, string actionName, string? actionDetail = null, long? operationStamp = null)
    {
        if (string.IsNullOrWhiteSpace(actionName))
        {
            return Task.CompletedTask;
        }

        var detailSuffix = string.IsNullOrWhiteSpace(actionDetail) ? string.Empty : $" Chi tiết: {actionDetail.Trim()}";
        var template = NotificationTemplateEngine.Render(
            NotificationTemplateKey.ActorEventQrActionConfirmation,
            new Dictionary<string, string?>
            {
                ["ActionName"] = actionName.Trim(),
                ["EventName"] = eventName,
                ["QrId"] = qrId.ToString(),
                ["DetailSuffix"] = detailSuffix
            });

        return CreateNotificationAsync(new CreateNotificationDto
        {
            UserID = actorUserId,
            EventID = eventId,
            Title = template.Title,
            Content = template.Content,
            NotificationType = NotificationTypeEnum.System,
            Priority = NotificationComposerSupport.GetPriorityByFlow(NotificationFlowType.ActorEventQrActionConfirmation),
            ActionUrl = $"/events/{eventId}/qrcode",
            DedupKey = NotificationComposerSupport.BuildDedupKey("actor-event-qr-action", actorUserId.ToString(), eventId.ToString(), qrId.ToString(), actionName, actionDetail, operationStamp?.ToString()),
            Audience = null
        });
    }

    public Task CreateActorEventPointActionConfirmationAsync(int actorUserId, int eventId, string eventName, string roleType, string actionName, string? actionDetail = null, long? operationStamp = null)
    {
        if (string.IsNullOrWhiteSpace(actionName))
        {
            return Task.CompletedTask;
        }

        var detailSuffix = string.IsNullOrWhiteSpace(actionDetail) ? string.Empty : $" Chi tiết: {actionDetail.Trim()}";
        var template = NotificationTemplateEngine.Render(
            NotificationTemplateKey.ActorEventPointActionConfirmation,
            new Dictionary<string, string?>
            {
                ["ActionName"] = actionName.Trim(),
                ["EventName"] = eventName,
                ["RoleType"] = roleType,
                ["DetailSuffix"] = detailSuffix
            });

        return CreateNotificationAsync(new CreateNotificationDto
        {
            UserID = actorUserId,
            EventID = eventId,
            Title = template.Title,
            Content = template.Content,
            NotificationType = NotificationTypeEnum.System,
            Priority = NotificationComposerSupport.GetPriorityByFlow(NotificationFlowType.ActorEventPointActionConfirmation),
            ActionUrl = $"/events/{eventId}/points",
            DedupKey = NotificationComposerSupport.BuildDedupKey("actor-event-point-action", actorUserId.ToString(), eventId.ToString(), roleType, actionName, actionDetail, operationStamp?.ToString()),
            Audience = null
        });
    }

    public async Task CreateSuspiciousAttendanceAlertAsync(int attendanceId, int eventId, string eventName, int attendeeUserId, int? riskScore, string? riskLevel, string? faceVerificationStatus)
    {
        if (!string.Equals(riskLevel, "High", StringComparison.OrdinalIgnoreCase)
            && !string.Equals(riskLevel, "Critical", StringComparison.OrdinalIgnoreCase))
        {
            return;
        }

        var adminUserIds = await _routingService.GetAdminAlertRecipientUserIdsAsync();
        if (!adminUserIds.Any())
        {
            _logger.LogWarning(
                "Không tìm thấy admin để gửi alert SuspiciousAttendance. AttendanceID={AttendanceId}, EventID={EventId}",
                attendanceId,
                eventId);
            return;
        }

        var attendee = await _context.Users
            .AsNoTracking()
            .Where(u => u.UserID == attendeeUserId)
            .Select(u => new { u.FullName, u.Code })
            .FirstOrDefaultAsync();

        var normalizedRiskLevel = NotificationComposerSupport.NormalizeRiskLevel(riskLevel);
        var attendeeDisplay = NotificationComposerSupport.BuildAttendeeDisplay(attendee?.FullName, attendee?.Code, attendeeUserId);
        var template = NotificationTemplateEngine.Render(
            NotificationTemplateKey.SuspiciousAttendanceAlert,
            new Dictionary<string, string?>
            {
                ["AttendeeDisplay"] = attendeeDisplay,
                ["EventName"] = eventName,
                ["RiskLevelLabel"] = normalizedRiskLevel,
                ["RiskScore"] = (riskScore ?? 0).ToString(),
                ["FaceStatusLabel"] = NotificationComposerSupport.NormalizeFaceStatusLabel(faceVerificationStatus)
            });

        var priority = string.Equals(normalizedRiskLevel, "Critical", StringComparison.OrdinalIgnoreCase)
            ? NotificationPriority.Critical
            : NotificationPriority.High;

        foreach (var adminUserId in adminUserIds)
        {
            await CreateNotificationAsync(new CreateNotificationDto
            {
                UserID = adminUserId,
                EventID = eventId,
                Title = template.Title,
                Content = template.Content,
                NotificationType = NotificationTypeEnum.System,
                Priority = priority,
                ActionUrl = $"/Attendance?eventId={eventId}&suspiciousOnly=true&riskLevel={normalizedRiskLevel}",
                DedupKey = NotificationComposerSupport.BuildDedupKey(
                    "web-alert-suspicious-attendance",
                    adminUserId.ToString(),
                    eventId.ToString(),
                    attendanceId.ToString(),
                    normalizedRiskLevel,
                    riskScore?.ToString(),
                    faceVerificationStatus),
                Audience = null
            });
        }

        _logger.LogInformation(
            "Đã tạo alert SuspiciousAttendance cho {Count} admin. AttendanceID={AttendanceId}, EventID={EventId}, RiskLevel={RiskLevel}, RiskScore={RiskScore}",
            adminUserIds.Count,
            attendanceId,
            eventId,
            normalizedRiskLevel,
            riskScore ?? 0);
    }
}

internal enum NotificationFlowType
{
    EventRegistrationSuccess = 1,
    EventRegistrationCancel = 2,
    AttendanceValid = 3,
    AttendanceInvalid = 4,
    EventUpdateBroadcast = 5,
    EventCancellationBroadcast = 6,
    EventCapacityFullAlert = 7,
    QrScanLimitReachedAlert = 8,
    QrDeactivatedAlert = 9,
    ActorEventActionConfirmation = 10,
    ActorEventQrActionConfirmation = 11,
    ActorEventPointActionConfirmation = 12
}

internal static class NotificationComposerSupport
{
    public static string BuildDedupKey(string prefix, params string?[] parts)
    {
        var raw = string.Join("|", parts.Select(p => p?.Trim() ?? string.Empty));
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(raw));
        return $"{prefix}:{Convert.ToHexString(bytes)}";
    }

    public static DateTime GetDefaultExpiryDate(NotificationTypeEnum notificationType)
    {
        var now = DateTime.Now;
        return notificationType switch
        {
            NotificationTypeEnum.EventReminder => now.AddDays(3),
            NotificationTypeEnum.EventUpdate => now.AddDays(30),
            NotificationTypeEnum.EventRegistration => now.AddDays(90),
            NotificationTypeEnum.Attendance => now.AddDays(90),
            NotificationTypeEnum.EventCancellation => now.AddDays(180),
            NotificationTypeEnum.ManualPoints => now.AddDays(365),
            NotificationTypeEnum.System => now.AddDays(30),
            _ => now.AddDays(30)
        };
    }

    public static NotificationPriority GetPriorityByFlow(NotificationFlowType flow)
    {
        return flow switch
        {
            NotificationFlowType.EventRegistrationSuccess => NotificationPriority.Normal,
            NotificationFlowType.EventRegistrationCancel => NotificationPriority.Normal,
            NotificationFlowType.AttendanceValid => NotificationPriority.Normal,
            NotificationFlowType.AttendanceInvalid => NotificationPriority.High,
            NotificationFlowType.EventUpdateBroadcast => NotificationPriority.High,
            NotificationFlowType.EventCancellationBroadcast => NotificationPriority.High,
            NotificationFlowType.EventCapacityFullAlert => NotificationPriority.High,
            NotificationFlowType.QrDeactivatedAlert => NotificationPriority.High,
            NotificationFlowType.QrScanLimitReachedAlert => NotificationPriority.Critical,
            NotificationFlowType.ActorEventActionConfirmation => NotificationPriority.Normal,
            NotificationFlowType.ActorEventQrActionConfirmation => NotificationPriority.Normal,
            NotificationFlowType.ActorEventPointActionConfirmation => NotificationPriority.Normal,
            _ => NotificationPriority.Normal
        };
    }

    public static string BuildAttendeeDisplay(string? fullName, string? code, int userId)
    {
        var normalizedFullName = string.IsNullOrWhiteSpace(fullName) ? $"User {userId}" : fullName.Trim();
        return string.IsNullOrWhiteSpace(code) ? normalizedFullName : $"{normalizedFullName} ({code.Trim()})";
    }

    public static string NormalizeRiskLevel(string? riskLevel)
    {
        return string.IsNullOrWhiteSpace(riskLevel) ? "Low" : riskLevel.Trim();
    }

    public static string NormalizeFaceStatusLabel(string? faceVerificationStatus)
    {
        return string.IsNullOrWhiteSpace(faceVerificationStatus) ? "Unknown" : faceVerificationStatus.Trim();
    }
}
