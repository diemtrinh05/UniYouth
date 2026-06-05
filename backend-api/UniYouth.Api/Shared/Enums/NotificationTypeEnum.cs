namespace UniYouth.Api.Shared.Enums
{
    /// <summary>
    /// Các loại thông báo trong hệ thống
    /// Mapping 1–1 với bảng NotificationTypes
    /// </summary>
    public enum NotificationTypeEnum
    {
        EventRegistration = 1,
        Attendance = 2,
        EventUpdate = 3,
        EventCancellation = 4,
        EventReminder = 5,
        ManualPoints = 6,
        System = 7
    }
}
