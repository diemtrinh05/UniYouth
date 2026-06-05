using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Shared.Extensions
{
    public static class QrCodeStatusExtensions
    {
        public static string ToDisplayString(this QrCodeStatus status)
        {
            return status switch
            {
                QrCodeStatus.Inactive => "Đã vô hiệu hóa",
                QrCodeStatus.NotStarted => "Chưa có hiệu lực",
                QrCodeStatus.Active => "Đang hoạt động",
                QrCodeStatus.Expired => "Đã hết hạn",
                QrCodeStatus.ScanLimitReached => "Đã đạt giới hạn quét",
                _ => "Không xác định"
            };
        }
    }
}
