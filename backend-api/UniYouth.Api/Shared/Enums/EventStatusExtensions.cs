namespace UniYouth.Api.Shared.Enums
{
    public static class EventStatusExtensions
    {
        public static string ToDisplayName(this EventStatus status)
        {
            return status switch
            {
                EventStatus.Draft => "Nháp",
                EventStatus.Open => "Mở đăng ký",
                EventStatus.Ongoing => "Đang diễn ra",
                EventStatus.Closed => "Đã kết thúc",
                EventStatus.Cancelled => "Đã hủy",
                _ => "Không xác định"
            };
        }
    }
}
