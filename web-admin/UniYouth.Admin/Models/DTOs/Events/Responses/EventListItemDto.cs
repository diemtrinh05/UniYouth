namespace UniYouth.Admin.Models.DTOs.Events.Responses
{
    /// <summary>
    /// DTO cho mỗi event trong danh sách
    /// Khớp với EventListItemDto từ Swagger
    /// </summary>
    public class EventListItemDto
    {
        public int EventId { get; set; }
        public string EventName { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string? LocationName { get; set; }
        public int? MaxParticipants { get; set; }
        public int? CurrentParticipants { get; set; }
        public int Status { get; set; }
        public string? StatusName { get; set; }
        public string? EventTypeName { get; set; }
        public string? InstituteName { get; set; }
        public DateTime? RegistrationDeadline { get; set; }
        public string? ThumbnailUrl { get; set; }
        public bool HasAvailableSlots { get; set; }
        public bool EnableFaceVerification { get; set; }
    }
}
