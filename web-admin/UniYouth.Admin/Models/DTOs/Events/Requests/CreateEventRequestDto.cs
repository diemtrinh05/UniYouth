namespace UniYouth.Admin.Models.DTOs.Events.Requests
{
    /// <summary>
    /// Request DTO cho POST /api/Events
    /// </summary>
    public class CreateEventRequestDto
    {
        public string EventName { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string? LocationName { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public int AllowRadius { get; set; } = 100;
        public int? MaxParticipants { get; set; }
        public int EventTypeId { get; set; }
        public int? InstituteId { get; set; }
        public DateTime? RegistrationDeadline { get; set; }
        public int Status { get; set; }
        public bool EnableFaceVerification { get; set; }
    }
}
