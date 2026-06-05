namespace UniYouth.Admin.Helpers
{
    /// <summary>
    /// Helper xử lý DateTime cho UniYouth.Admin
    ///
    /// QUY ƯỚC:
    /// - Mọi DateTime từ API: UTC
    /// - Mọi DateTime hiển thị UI: Giờ Việt Nam (UTC+7)
    ///
    /// MỤC ĐÍCH:
    /// - Tránh lệch múi giờ khi deploy nhiều môi trường
    /// - Đảm bảo UI luôn hiển thị đúng giờ Việt Nam
    /// </summary>
    public static class DateTimeHelper
    {
        /// <summary>
        /// TimeZone ID cho Việt Nam (Windows)
        /// </summary>
        private const string VietnamTimeZoneId = "SE Asia Standard Time";

        /// <summary>
        /// Chuyển DateTime UTC sang giờ Việt Nam
        ///
        /// DÙNG KHI:
        /// - Hiển thị DateTime trên UI
        /// - Mapping DTO → ViewModel
        ///
        /// KHÔNG DÙNG KHI:
        /// - Business logic
        /// - So sánh nghiệp vụ thời gian
        /// </summary>
        public static DateTime ToVietnamTime(DateTime utcDateTime)
        {
            // Phòng trường hợp Kind = Unspecified (thường gặp khi deserialize JSON)
            if (utcDateTime.Kind == DateTimeKind.Unspecified)
            {
                utcDateTime = DateTime.SpecifyKind(utcDateTime, DateTimeKind.Utc);
            }

            var vietnamTimeZone =
                TimeZoneInfo.FindSystemTimeZoneById(VietnamTimeZoneId);

            return TimeZoneInfo.ConvertTimeFromUtc(utcDateTime, vietnamTimeZone);
        }

        /// <summary>
        /// Convert UTC → giờ Việt Nam và format sẵn cho UI
        /// </summary>
        public static string ToVietnamDisplay(
            DateTime utcDateTime,
            string format = "HH:mm dd/MM/yyyy")
        {
            return ToVietnamTime(utcDateTime).ToString(format);
        }

        /// <summary>
        /// Chuyển giờ Việt Nam (UTC+7) sang UTC
        ///
        /// DÙNG KHI:
        /// - Gửi DateTime từ Admin lên API
        ///
        /// KHÔNG DÙNG KHI:
        /// - Server tự sinh DateTime (DateTime.UtcNow)
        /// </summary>
        public static DateTime FromVietnamTimeToUtc(DateTime localTime)
        {
            var vietnamTimeZone =
                TimeZoneInfo.FindSystemTimeZoneById(VietnamTimeZoneId);

            // Gán Kind = Unspecified để ConvertTimeToUtc hiểu đúng
            var unspecified = DateTime.SpecifyKind(
                localTime,
                DateTimeKind.Unspecified);

            return TimeZoneInfo.ConvertTimeToUtc(unspecified, vietnamTimeZone);
        }
    }
}
