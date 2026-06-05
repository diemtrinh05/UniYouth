namespace UniYouth.Api.Shared.Enums
{
    /// <summary>
    /// Trạng thái sự kiện
    /// </summary>
    public enum EventStatus : byte
    {
        Draft = 0,        // Nháp – chưa công bố
        Open = 1,         // Mở đăng ký
        Ongoing = 2,      // Đang diễn ra
        Closed = 3,       // Đã kết thúc
        Cancelled = 4     // Đã hủy
    }
}
