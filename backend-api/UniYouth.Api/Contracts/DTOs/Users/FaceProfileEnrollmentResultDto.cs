namespace UniYouth.Api.Contracts.DTOs.Users
{
    public class FaceProfileEnrollmentResultDto
    {
        public int FaceProfileId { get; set; }

        public string? ImageUrl { get; set; }

        public double? QualityScore { get; set; }

        public string Algorithm { get; set; } = string.Empty;

        public string Version { get; set; } = string.Empty;

        public DateTime UpdatedDate { get; set; }

        public bool ReplacedPreviousProfile { get; set; }
    }
}
