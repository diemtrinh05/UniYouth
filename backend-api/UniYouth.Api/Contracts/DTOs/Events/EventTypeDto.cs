namespace UniYouth.Api.Contracts.DTOs.Events
{
    public class EventTypeDto
    {
        public int TypeId { get; set; }

        public string TypeName { get; set; } = string.Empty;

        public string? Description { get; set; }
    }
}

