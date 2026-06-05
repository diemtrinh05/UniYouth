using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class FaceRecognitionLog
{
    public int FaceLogID { get; set; }

    public int AttendanceID { get; set; }

    public int? FaceProfileID { get; set; }

    public double? SimilarityScore { get; set; }

    public double? Threshold { get; set; }

    public bool? IsMatched { get; set; }

    public int? ProcessingTime { get; set; }

    public string? VerificationStatus { get; set; }

    public string? Provider { get; set; }

    public string? Model { get; set; }

    public string? ErrorCode { get; set; }

    public string? CapturedImageUrl { get; set; }

    public string? ErrorMessage { get; set; }

    public DateTime? CreatedDate { get; set; }

    public virtual Attendance Attendance { get; set; } = null!;

    public virtual FaceProfile? FaceProfile { get; set; }
}
