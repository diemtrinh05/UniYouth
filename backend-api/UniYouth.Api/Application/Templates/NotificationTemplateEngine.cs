using System.Text.RegularExpressions;

namespace UniYouth.Api.Application.Templates
{
    internal enum NotificationTemplateKey
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
        ActorEventPointActionConfirmation = 12,
        SuspiciousAttendanceAlert = 13
    }

    internal sealed record NotificationTemplateResult(
        string Title,
        string Content,
        string Locale,
        int Version);

    internal static class NotificationTemplateEngine
    {
        private const string DefaultLocale = "vi-VN";
        private const int DefaultVersion = 1;

        private static readonly Regex PlaceholderRegex =
            new(@"\{(?<key>[A-Za-z0-9_]+)\}", RegexOptions.Compiled);

        private static readonly IReadOnlyDictionary<(NotificationTemplateKey Key, string Locale), (string Title, string Content, int Version)> Templates =
            new Dictionary<(NotificationTemplateKey, string), (string, string, int)>
            {
                [(NotificationTemplateKey.EventRegistrationSuccess, DefaultLocale)] = (
                    "Đăng ký sự kiện thành công",
                    "Bạn đã đăng ký tham gia sự kiện \"{EventName}\" thành công. Vui lòng theo dõi thông tin và điểm danh đúng giờ.",
                    DefaultVersion),

                [(NotificationTemplateKey.EventRegistrationCancel, DefaultLocale)] = (
                    "Hủy đăng ký sự kiện",
                    "Bạn đã hủy đăng ký tham gia sự kiện \"{EventName}\".{ReasonSuffix}",
                    DefaultVersion),

                [(NotificationTemplateKey.AttendanceValid, DefaultLocale)] = (
                    "Điểm danh thành công",
                    "Bạn đã điểm danh sự kiện \"{EventName}\" thành công.{PointsSuffix}",
                    DefaultVersion),

                [(NotificationTemplateKey.AttendanceInvalid, DefaultLocale)] = (
                    "Điểm danh không hợp lệ",
                    "Điểm danh sự kiện \"{EventName}\" không hợp lệ.{InvalidReasonSuffix}",
                    DefaultVersion),

                [(NotificationTemplateKey.EventUpdateBroadcast, DefaultLocale)] = (
                    "Thông báo cập nhật sự kiện",
                    "Sự kiện \"{EventName}\" đã có thay đổi: {UpdateMessage}",
                    DefaultVersion),

                [(NotificationTemplateKey.EventCancellationBroadcast, DefaultLocale)] = (
                    "Thông báo hủy sự kiện",
                    "Sự kiện \"{EventName}\" đã bị hủy.{ReasonSuffix}",
                    DefaultVersion),

                [(NotificationTemplateKey.EventCapacityFullAlert, DefaultLocale)] = (
                    "Cảnh báo sự kiện đã đủ chỗ",
                    "Sự kiện \"{EventName}\" đã đạt giới hạn người tham gia ({CurrentParticipants}/{MaxParticipants}).",
                    DefaultVersion),

                [(NotificationTemplateKey.QrScanLimitReachedAlert, DefaultLocale)] = (
                    "Cảnh báo QR đạt giới hạn quét",
                    "QR của sự kiện \"{EventName}\" đã đạt giới hạn quét ({CurrentScans}/{ScanLimit}).",
                    DefaultVersion),

                [(NotificationTemplateKey.QrDeactivatedAlert, DefaultLocale)] = (
                    "QR sự kiện đã bị vô hiệu hóa",
                    "QR ({QrId}) của sự kiện \"{EventName}\" đã bị vô hiệu hóa bởi {ActorName}.",
                    DefaultVersion),

                [(NotificationTemplateKey.ActorEventActionConfirmation, DefaultLocale)] = (
                    "Thao tác sự kiện thành công",
                    "Bạn đã {ActionName} sự kiện \"{EventName}\" thành công.{DetailSuffix}",
                    DefaultVersion),

                [(NotificationTemplateKey.ActorEventQrActionConfirmation, DefaultLocale)] = (
                    "Thao tác QR sự kiện thành công",
                    "Bạn đã {ActionName} QR ({QrId}) của sự kiện \"{EventName}\" thành công.{DetailSuffix}",
                    DefaultVersion),

                [(NotificationTemplateKey.ActorEventPointActionConfirmation, DefaultLocale)] = (
                    "Thao tác cấu hình điểm sự kiện thành công",
                    "Bạn đã {ActionName} cấu hình điểm ({RoleType}) của sự kiện \"{EventName}\" thành công.{DetailSuffix}",
                    DefaultVersion),

                [(NotificationTemplateKey.SuspiciousAttendanceAlert, DefaultLocale)] = (
                    "Cảnh báo điểm danh nghi ngờ",
                    "Điểm danh của {AttendeeDisplay} tại sự kiện \"{EventName}\" được gắn cờ {RiskLevelLabel} (risk score: {RiskScore}, face status: {FaceStatusLabel}).",
                    DefaultVersion),
            };

        public static NotificationTemplateResult Render(
            NotificationTemplateKey key,
            IReadOnlyDictionary<string, string?> placeholders,
            string? locale = null)
        {
            var effectiveLocale = string.IsNullOrWhiteSpace(locale)
                ? DefaultLocale
                : locale.Trim();

            if (!Templates.TryGetValue((key, effectiveLocale), out var template)
                && !Templates.TryGetValue((key, DefaultLocale), out template))
            {
                throw new InvalidOperationException($"Không tìm thấy template cho key={key}, locale={effectiveLocale}");
            }

            var title = RenderTemplate(template.Title, placeholders);
            var content = RenderTemplate(template.Content, placeholders);

            return new NotificationTemplateResult(title, content, effectiveLocale, template.Version);
        }

        private static string RenderTemplate(string template, IReadOnlyDictionary<string, string?> placeholders)
        {
            if (string.IsNullOrEmpty(template))
            {
                return string.Empty;
            }

            var rendered = PlaceholderRegex.Replace(template, match =>
            {
                var key = match.Groups["key"].Value;
                if (!placeholders.TryGetValue(key, out var value) || string.IsNullOrEmpty(value))
                {
                    return string.Empty;
                }

                return value;
            });

            return rendered.Trim();
        }
    }
}
