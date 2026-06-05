namespace UniYouth.Api.Shared.PushNotifications
{
    public sealed class PushNotificationOptions
    {
        public const string SectionName = "PushNotifications";

        public FcmOptions Fcm { get; set; } = new();

        public ApnsOptions Apns { get; set; } = new();
    }

    public sealed class FcmOptions
    {
        public bool Enabled { get; set; } = false;

        public string? ProjectId { get; set; }

        /// <summary>
        /// Đường dẫn tới file JSON service account (khuyến nghị set bằng env var / secret manager).
        /// </summary>
        public string? ServiceAccountJsonPath { get; set; }

        /// <summary>
        /// Raw JSON của Firebase service account. Dùng cho môi trường local khi không muốn lưu file trên repo.
        /// </summary>
        public string? ServiceAccountJson { get; set; }
    }

    public sealed class ApnsOptions
    {
        public bool Enabled { get; set; } = false;

        public bool UseSandbox { get; set; } = true;

        public string? TeamId { get; set; }

        public string? KeyId { get; set; }

        public string? BundleId { get; set; }

        /// <summary>
        /// Đường dẫn tới APNS .p8 private key (khuyến nghị set bằng env var / secret manager).
        /// </summary>
        public string? PrivateKeyPath { get; set; }
    }
}
