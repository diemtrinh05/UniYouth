namespace UniYouth.Api.Shared.Helpers
{
    /// <summary>
    /// Helper hỗ trợ xử lý DateTime và chuyển đổi múi giờ
    /// 
    /// QUY ƯỚC TOÀN HỆ THỐNG:
    /// - Database và business logic: sử dụng giờ Việt Nam (UTC+7)
    /// - Dữ liệu trả về cho client: dùng trực tiếp giờ Việt Nam (không convert)
    /// 
    /// MỤC ĐÍCH:
    /// - Tránh lỗi lệch múi giờ khi deploy ở môi trường khác
    /// - Đảm bảo thời gian hiển thị đúng với người dùng Việt Nam
    /// </summary>
    public static class DateTimeHelper
    {
        /// <summary>
        /// Giữ lại method name để tương thích code hiện tại.
        ///
        /// Theo quy ước mới: hệ thống dùng giờ Việt Nam (UTC+7) end-to-end,
        /// nên method này là no-op (không chuyển đổi).
        /// </summary>
        public static DateTime ToVietnamTime(DateTime utcDateTime)
        {
            return utcDateTime;
        }

        /// <summary>
        /// Giữ lại method name để tương thích code hiện tại.
        ///
        /// Theo quy ước mới: hệ thống dùng giờ Việt Nam (UTC+7) end-to-end,
        /// nên method này là no-op (không chuyển đổi).
        /// </summary>
        public static DateTime FromVietnamTimeToUtc(DateTime localTime)
        {
            return localTime;
        }
    }
}
