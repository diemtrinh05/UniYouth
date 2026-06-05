using System;
using System.Collections.Generic;

namespace UniYouth.Api.Domain.Entities;

public partial class FaceProfile
{
    public int FaceProfileID { get; set; }

    public int UserID { get; set; }

    public byte[] FaceEmbedding { get; set; } = null!;

    public string? Algorithm { get; set; }

    public string? Version { get; set; }

    public double? QualityScore { get; set; }

    public string? ImageUrl { get; set; }

    public bool? IsActive { get; set; }

    public DateTime? CreatedDate { get; set; }

    public DateTime? UpdatedDate { get; set; }

    public virtual ICollection<FaceRecognitionLog> FaceRecognitionLogs { get; set; } = new List<FaceRecognitionLog>();

    public virtual User User { get; set; } = null!;
}
