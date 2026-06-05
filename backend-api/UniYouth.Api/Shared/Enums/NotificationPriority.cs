namespace UniYouth.Api.Shared.Enums
{
    /// <summary>
    /// Mức độ ưu tiên của thông báo
    /// </summary>
    public enum NotificationPriority : byte
    {
        Normal = 0,   // Bình thường
        High = 1,     // Quan trọng
        Critical = 2 // Khẩn cấp
    }
}
