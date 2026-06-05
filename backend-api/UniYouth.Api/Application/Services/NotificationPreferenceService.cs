using System.Globalization;
using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.NotificationPreferences;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Application.Services
{
    public interface INotificationPreferenceService
    {
        Task<List<NotificationPreferenceDto>> GetUserPreferencesAsync(int userId, CancellationToken cancellationToken);
        Task<NotificationPreferenceDto> UpsertPreferenceAsync(
            int userId,
            NotificationTypeEnum notificationType,
            UpsertNotificationPreferenceRequestDto dto,
            CancellationToken cancellationToken);
    }

    public sealed class NotificationPreferenceService : INotificationPreferenceService
    {
        private readonly UniYouthDbContext _context;

        public NotificationPreferenceService(UniYouthDbContext context)
        {
            _context = context;
        }

        public async Task<List<NotificationPreferenceDto>> GetUserPreferencesAsync(int userId, CancellationToken cancellationToken)
        {
            var typeNameMap = await _context.NotificationTypes
                .AsNoTracking()
                .ToDictionaryAsync(t => t.TypeID, t => t.TypeName, cancellationToken);

            var existingPreferences = await _context.UserNotificationPreferences
                .AsNoTracking()
                .Where(p => p.UserID == userId)
                .ToDictionaryAsync(p => p.NotificationTypeID, cancellationToken);

            var result = new List<NotificationPreferenceDto>();

            foreach (var notificationType in Enum.GetValues<NotificationTypeEnum>())
            {
                var notificationTypeId = (int)notificationType;
                existingPreferences.TryGetValue(notificationTypeId, out var preference);

                var isInAppEnabled = preference?.IsInAppEnabled ?? true;
                var isRealtimeEnabled = preference?.IsRealtimeEnabled ?? true;
                var isPushEnabled = preference?.IsPushEnabled ?? true;
                var isMuted = preference?.IsMuted ?? false;
                var quietHoursStart = preference?.QuietHoursStartMinute;
                var quietHoursEnd = preference?.QuietHoursEndMinute;

                result.Add(new NotificationPreferenceDto
                {
                    NotificationTypeID = notificationTypeId,
                    NotificationType = typeNameMap.GetValueOrDefault(notificationTypeId, notificationType.ToString()),
                    IsInAppEnabled = isInAppEnabled,
                    IsRealtimeEnabled = isRealtimeEnabled,
                    IsPushEnabled = isPushEnabled,
                    IsMuted = isMuted,
                    QuietHoursStart = ToTimeString(quietHoursStart),
                    QuietHoursEnd = ToTimeString(quietHoursEnd),
                    UpdatedDate = preference?.UpdatedDate ?? DateTime.Now
                });
            }

            return result
                .OrderBy(p => p.NotificationTypeID)
                .ToList();
        }

        public async Task<NotificationPreferenceDto> UpsertPreferenceAsync(
            int userId,
            NotificationTypeEnum notificationType,
            UpsertNotificationPreferenceRequestDto dto,
            CancellationToken cancellationToken)
        {
            if (!Enum.IsDefined(typeof(NotificationTypeEnum), notificationType))
            {
                throw new InvalidOperationException("NotificationType không hợp lệ.");
            }

            var notificationTypeId = (int)notificationType;

            var notificationTypeExists = await _context.NotificationTypes
                .AsNoTracking()
                .AnyAsync(t => t.TypeID == notificationTypeId, cancellationToken);

            if (!notificationTypeExists)
            {
                throw new KeyNotFoundException($"Không tìm thấy NotificationTypeID={notificationTypeId}");
            }

            var (quietHoursStartMinute, quietHoursEndMinute) = ParseQuietHours(dto.QuietHoursStart, dto.QuietHoursEnd);
            var now = DateTime.Now;

            var preference = await _context.UserNotificationPreferences
                .FirstOrDefaultAsync(
                    p => p.UserID == userId && p.NotificationTypeID == notificationTypeId,
                    cancellationToken);

            if (preference == null)
            {
                preference = new UserNotificationPreference
                {
                    UserID = userId,
                    NotificationTypeID = notificationTypeId,
                    CreatedDate = now
                };

                _context.UserNotificationPreferences.Add(preference);
            }

            preference.IsInAppEnabled = dto.IsInAppEnabled;
            preference.IsRealtimeEnabled = dto.IsRealtimeEnabled;
            preference.IsPushEnabled = dto.IsPushEnabled;
            preference.IsMuted = dto.IsMuted;
            preference.QuietHoursStartMinute = quietHoursStartMinute;
            preference.QuietHoursEndMinute = quietHoursEndMinute;
            preference.UpdatedDate = now;

            await _context.SaveChangesAsync(cancellationToken);

            return new NotificationPreferenceDto
            {
                NotificationTypeID = notificationTypeId,
                NotificationType = notificationType.ToString(),
                IsInAppEnabled = preference.IsInAppEnabled,
                IsRealtimeEnabled = preference.IsRealtimeEnabled,
                IsPushEnabled = preference.IsPushEnabled,
                IsMuted = preference.IsMuted,
                QuietHoursStart = ToTimeString(preference.QuietHoursStartMinute),
                QuietHoursEnd = ToTimeString(preference.QuietHoursEndMinute),
                UpdatedDate = preference.UpdatedDate
            };
        }

        private static (short? QuietHoursStartMinute, short? QuietHoursEndMinute) ParseQuietHours(
            string? quietHoursStart,
            string? quietHoursEnd)
        {
            var hasStart = !string.IsNullOrWhiteSpace(quietHoursStart);
            var hasEnd = !string.IsNullOrWhiteSpace(quietHoursEnd);

            if (hasStart != hasEnd)
            {
                throw new InvalidOperationException(
                    "QuietHoursStart và QuietHoursEnd phải cùng có giá trị hoặc cùng để trống.");
            }

            if (!hasStart)
            {
                return (null, null);
            }

            if (!TimeOnly.TryParseExact(
                    quietHoursStart,
                    "HH:mm",
                    CultureInfo.InvariantCulture,
                    DateTimeStyles.None,
                    out var start))
            {
                throw new InvalidOperationException("QuietHoursStart không đúng định dạng HH:mm.");
            }

            if (!TimeOnly.TryParseExact(
                    quietHoursEnd,
                    "HH:mm",
                    CultureInfo.InvariantCulture,
                    DateTimeStyles.None,
                    out var end))
            {
                throw new InvalidOperationException("QuietHoursEnd không đúng định dạng HH:mm.");
            }

            return ((short)(start.Hour * 60 + start.Minute), (short)(end.Hour * 60 + end.Minute));
        }

        private static string? ToTimeString(short? minuteOfDay)
        {
            if (!minuteOfDay.HasValue)
            {
                return null;
            }

            var hour = minuteOfDay.Value / 60;
            var minute = minuteOfDay.Value % 60;
            return $"{hour:D2}:{minute:D2}";
        }
    }
}
