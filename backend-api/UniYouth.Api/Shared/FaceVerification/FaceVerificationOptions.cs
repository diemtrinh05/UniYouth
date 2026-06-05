namespace UniYouth.Api.Shared.FaceVerification
{
    public sealed class FaceVerificationOptions
    {
        public const string SectionName = "FaceVerification";

        public ServiceOptions Service { get; set; } = new();

        public ThresholdOptions Thresholds { get; set; } = new();

        public ObservabilityOptions Observability { get; set; } = new();

        public EnrollmentOptions Enrollment { get; set; } = new();

        public AttendanceOptions Attendance { get; set; } = new();
    }

    public sealed class ServiceOptions
    {
        public string? BaseUrl { get; set; }

        public int TimeoutSeconds { get; set; } = 3;

        public string? Provider { get; set; }

        public string? Model { get; set; }

        public string? Version { get; set; }
    }

    public sealed class ThresholdOptions
    {
        public double Match { get; set; } = 0.85d;

        public double Review { get; set; } = 0.70d;
    }

    public sealed class ObservabilityOptions
    {
        public bool LogRequests { get; set; } = true;

        public bool LogResponses { get; set; } = true;

        public bool LogFailuresOnly { get; set; } = false;
    }

    public sealed class EnrollmentOptions
    {
        public int ReEnrollCooldownMinutes { get; set; } = 60;
    }

    public sealed class AttendanceOptions
    {
        public int MaxFaceRetryAttempts { get; set; } = 2;
    }
}
