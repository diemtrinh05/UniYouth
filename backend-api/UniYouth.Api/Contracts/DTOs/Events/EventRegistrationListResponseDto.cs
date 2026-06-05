namespace UniYouth.Api.Contracts.DTOs.Events
{
    public class EventRegistrationListResponseDto
    {
        public int EventId { get; set; }

        public string EventName { get; set; } = string.Empty;

        public int Total { get; set; }

        public List<EventRegistrationItemDto> Items { get; set; } = new();
    }
}

