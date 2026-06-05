using Microsoft.Extensions.Options;
using UniYouth.Api.Shared.PushNotifications;

namespace UniYouth.Api.Application.Jobs
{
    public sealed class PushNotificationConfigDiagnosticsService : IHostedService
    {
        private readonly PushNotificationOptions _options;
        private readonly ILogger<PushNotificationConfigDiagnosticsService> _logger;
        private readonly IWebHostEnvironment _environment;

        public PushNotificationConfigDiagnosticsService(
            IOptions<PushNotificationOptions> options,
            ILogger<PushNotificationConfigDiagnosticsService> logger,
            IWebHostEnvironment environment)
        {
            _options = options.Value;
            _logger = logger;
            _environment = environment;
        }

        public Task StartAsync(CancellationToken cancellationToken)
        {
            var fcmConfigState = DescribeFcmConfig();
            _logger.LogInformation(
                "Push diagnostics: Env={Environment}, FcmEnabled={FcmEnabled}, ProjectId={ProjectId}, CredentialState={CredentialState}, ApnsEnabled={ApnsEnabled}",
                _environment.EnvironmentName,
                _options.Fcm.Enabled,
                _options.Fcm.ProjectId ?? "(null)",
                fcmConfigState,
                _options.Apns.Enabled);

            if (_options.Fcm.Enabled && fcmConfigState != "ready")
            {
                _logger.LogWarning(
                    "FCM đang bật nhưng chưa đủ credential hợp lệ. Push sẽ không gửi được cho tới khi cấu hình xong service account.");
            }

            return Task.CompletedTask;
        }

        public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;

        private string DescribeFcmConfig()
        {
            if (!string.IsNullOrWhiteSpace(_options.Fcm.ServiceAccountJson))
            {
                return "inline-json";
            }

            if (string.IsNullOrWhiteSpace(_options.Fcm.ServiceAccountJsonPath))
            {
                return "missing";
            }

            return File.Exists(_options.Fcm.ServiceAccountJsonPath)
                ? "ready"
                : $"missing-file:{_options.Fcm.ServiceAccountJsonPath}";
        }
    }
}
