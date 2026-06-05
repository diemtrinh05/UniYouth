namespace UniYouth.Api.Contracts.DTOs.Reports
{
    public sealed class GetEventAttendancesQueryDto
    {
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 50;

        public string? Q { get; set; }
        public bool? IsValid { get; set; }
        public string? Method { get; set; }
        public bool? FaceVerified { get; set; }
        public string? FaceVerificationStatus { get; set; }
        public string? RiskLevel { get; set; }
        public bool? SuspiciousOnly { get; set; }

        public DateTime? From { get; set; }
        public DateTime? To { get; set; }

        /// <summary>
        /// Whitelist: checkInTime | code | fullName | isValid
        /// </summary>
        public string? SortBy { get; set; }

        /// <summary>
        /// asc | desc
        /// </summary>
        public string? SortDir { get; set; }
    }
}

