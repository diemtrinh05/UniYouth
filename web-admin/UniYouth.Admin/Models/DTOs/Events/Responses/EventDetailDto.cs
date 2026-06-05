using UniYouth.Admin.Models.DTOs.Events.Common;

namespace UniYouth.Admin.Models.DTOs.Events.Responses
{
    /// <summary>
    /// DTO cho event detail (GET /api/Events/{id})
    /// </summary>
    public class EventDetailDto
    {
        public int EventId { get; set; }
        public string EventName { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string? LocationName { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public int? AllowRadius { get; set; }
        public int? MaxParticipants { get; set; }
        public int? CurrentParticipants { get; set; }
        public int Status { get; set; }
        public string? StatusName { get; set; }
        public EventTypeInfoDto? EventType { get; set; }
        public InstituteInfoDto? Institute { get; set; }
        public DateTime? RegistrationDeadline { get; set; }
        public List<EventImageDto>? Images { get; set; }
        public string? CreatedByName { get; set; }
        public DateTime? CreatedDate { get; set; }
        public bool HasAvailableSlots { get; set; }
        public bool IsRegistrationClosed { get; set; }
        public bool EnableFaceVerification { get; set; }
    }
}
