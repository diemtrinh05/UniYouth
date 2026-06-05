namespace UniYouth.Api.Shared.Enums
{
    public enum QrCodeStatus
    {
        Inactive = 0,      // Đã vô hiệu hóa
        NotStarted = 1,   // Chưa có hiệu lực
        Active = 2,       // Đang hoạt động
        Expired = 3,      // Đã hết hạn
        ScanLimitReached = 4 // Đã đạt giới hạn quét
    }
}
