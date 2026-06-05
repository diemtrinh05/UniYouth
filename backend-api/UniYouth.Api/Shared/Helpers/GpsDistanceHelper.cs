namespace UniYouth.Api.Shared.Helpers
{
    /// <summary>
    /// Helper hỗ trợ tính khoảng cách giữa hai tọa độ GPS
    /// sử dụng công thức Haversine.
    /// 
    /// MỤC ĐÍCH SỬ DỤNG:
    /// - Kiểm tra vị trí người dùng khi điểm danh (check-in)
    /// - Xác định người dùng có nằm trong bán kính cho phép của sự kiện hay không
    /// 
    /// VÌ SAO DÙNG HAVERSINE:
    /// - Tính khoảng cách ngắn nhất giữa 2 điểm trên bề mặt Trái Đất
    /// - Phù hợp cho GPS, bản đồ, định vị
    /// - Được sử dụng phổ biến trong các hệ thống navigation
    /// 
    /// ĐỘ CHÍNH XÁC:
    /// - Sai số ~0.5%
    /// - Đủ chính xác cho bài toán điểm danh (bán kính thường < 1km)
    /// - Giả định Trái Đất là hình cầu (sai số không đáng kể trong thực tế)
    /// </summary>
    public static class GpsDistanceHelper
    {
        // Bán kính trung bình của Trái Đất tính bằng meters
        private const double EarthRadiusMeters = 6371000;

        /// <summary>
        /// Tính khoảng cách giữa 2 tọa độ GPS sử dụng Haversine formula
        /// </summary>
        /// <param name="lat1">Vĩ độ điểm 1 (degrees)</param>
        /// <param name="lon1">Kinh độ điểm 1 (degrees)</param>
        /// <param name="lat2">Vĩ độ điểm 2 (degrees)</param>
        /// <param name="lon2">Kinh độ điểm 2 (degrees)</param>
        /// <returns>Khoảng cách tính bằng meters</returns>
        public static double CalculateDistance(
            decimal lat1,
            decimal lon1,
            decimal lat2,
            decimal lon2)
        {
            // Chuyển từ độ (degrees) sang radian để dùng cho các hàm lượng giác
            double lat1Rad = DegreesToRadians((double)lat1);
            double lon1Rad = DegreesToRadians((double)lon1);
            double lat2Rad = DegreesToRadians((double)lat2);
            double lon2Rad = DegreesToRadians((double)lon2);

            // Haversine formula

            double deltaLat = lat2Rad - lat1Rad;
            double deltaLon = lon2Rad - lon1Rad;

            // Công thức Haversine:
            // a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
            // c = 2 * atan2(√a, √(1 - a))
            // distance = R * c

            double a = Math.Sin(deltaLat / 2) * Math.Sin(deltaLat / 2) +
                       Math.Cos(lat1Rad) * Math.Cos(lat2Rad) *
                       Math.Sin(deltaLon / 2) * Math.Sin(deltaLon / 2);

            double c = 2 * Math.Atan2(Math.Sqrt(a), Math.Sqrt(1 - a));

            // Khoảng cách cuối cùng (mét)

            double distance = EarthRadiusMeters * c;

            return distance;
        }

        /// <summary>
        /// Chuyển đổi từ độ (degrees) sang radian
        /// </summary>
        private static double DegreesToRadians(double degrees)
        {
            return degrees * Math.PI / 180.0;
        }

        /// <summary>
        /// Kiểm tra xem vị trí có trong phạm vi cho phép không
        /// </summary>
        /// <param name="userLat">Vĩ độ người dùng</param>
        /// <param name="userLon">Kinh độ người dùng</param>
        /// <param name="eventLat">Vĩ độ sự kiện</param>
        /// <param name="eventLon">Kinh độ sự kiện</param>
        /// <param name="allowedRadiusMeters">Bán kính cho phép (meters)</param>
        /// <returns>true nếu trong phạm vi, false nếu ngoài phạm vi</returns>
        public static bool IsWithinRadius(
            decimal userLat,
            decimal userLon,
            decimal eventLat,
            decimal eventLon,
            int allowedRadiusMeters)
        {
            double distance = CalculateDistance(userLat, userLon, eventLat, eventLon);
            return distance <= allowedRadiusMeters;
        }
    }
}
