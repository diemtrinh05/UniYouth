namespace UniYouth.Api.Shared.Enums
{
    public enum NotificationOutboxStatus : byte
    {
        Pending = 0,
        Processing = 1,
        Succeeded = 2,
        Failed = 3
    }
}
