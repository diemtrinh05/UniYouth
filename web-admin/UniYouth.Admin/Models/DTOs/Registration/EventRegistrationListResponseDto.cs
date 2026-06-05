namespace UniYouth.Admin.Models.DTOs.Registration
{
    /// <summary>
    /// DTO theo swagger: EventRegistrationListResponseDto
    /// </summary>
    public class EventRegistrationListResponseDto
    {
        public int EventId { get; set; }
        public string? EventName { get; set; }
        public int Total { get; set; }
        public List<EventRegistrationItemDto>? Items { get; set; }
    }
}

