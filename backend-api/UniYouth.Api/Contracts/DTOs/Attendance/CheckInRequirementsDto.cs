namespace UniYouth.Api.Contracts.DTOs.Attendance
{
    public class CheckInRequirementsDto
    {
        public int EventId { get; set; }

        public string EventName { get; set; } = string.Empty;

        public bool EnableFaceVerification { get; set; }
    }
}
