using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class Attendance
{
    public int AttendanceID { get; set; }

    public int EventID { get; set; }

    public int UserID { get; set; }

    public int QRID { get; set; }

    public string? CheckInMethod { get; set; }

    public DateTime? CheckInTime { get; set; }

    public decimal? UserLatitude { get; set; }

    public decimal? UserLongitude { get; set; }

    public double? Distance { get; set; }

    public bool? FaceVerified { get; set; }

    public double? FaceConfidence { get; set; }

    public string? FaceVerificationStatus { get; set; }

    public string? FaceVerificationReason { get; set; }

    public string? FaceVerificationProvider { get; set; }

    public string? FaceVerificationVersion { get; set; }

    public bool? LivenessPassed { get; set; }

    public double? LivenessScore { get; set; }

    public string? LivenessReason { get; set; }

    public int? RiskScore { get; set; }

    public string? RiskLevel { get; set; }

    public string? RiskReasonsJson { get; set; }

    public bool? IsValid { get; set; }

    public string? InvalidReason { get; set; }

    public string? IPAddress { get; set; }

    public string? DeviceInfo { get; set; }

    public string? ClientDeviceId { get; set; }

    public int? FaceRetryCount { get; set; }

    public DateTime? CreatedDate { get; set; }

    public virtual Event Event { get; set; } = null!;

    public virtual ICollection<FaceRecognitionLog> FaceRecognitionLogs { get; set; } = new List<FaceRecognitionLog>();

    public virtual EventQRCode QR { get; set; } = null!;

    public virtual User User { get; set; } = null!;
}
