namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class BiometricTelemetryItemDto
    {
        public int AttendanceID { get; set; }
        public int EventID { get; set; }
        public string EventName { get; set; } = string.Empty;
        public int UserID { get; set; }
        public string FullName { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
        public DateTime? CheckInTime { get; set; }
        public bool? IsValid { get; set; }
        public string? InvalidReason { get; set; }
        public string? FaceVerificationStatus { get; set; }
        public double? FaceConfidence { get; set; }
        public string? FaceVerificationReason { get; set; }
        public bool? LivenessPassed { get; set; }
        public double? LivenessScore { get; set; }
        public string? LivenessReason { get; set; }
        public int? RiskScore { get; set; }
        public string? RiskLevel { get; set; }
        public double? SimilarityScore { get; set; }
        public double? Threshold { get; set; }
        public string? FaceLogStatus { get; set; }
        public string? FaceProvider { get; set; }
        public string? FaceModel { get; set; }
        public int? FaceProcessingTimeMs { get; set; }
        public string? FaceErrorCode { get; set; }
        public string? FaceErrorMessage { get; set; }
    }
}
