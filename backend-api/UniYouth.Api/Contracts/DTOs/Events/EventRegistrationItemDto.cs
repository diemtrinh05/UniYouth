namespace UniYouth.Api.Contracts.DTOs.Events
{
    public class EventRegistrationItemDto
    {
        public int RegistrationId { get; set; }

        public int UserId { get; set; }

        public string Code { get; set; } = string.Empty;

        public string FullName { get; set; } = string.Empty;

        public string Email { get; set; } = string.Empty;

        public DateTime? RegisterTime { get; set; }

        public int Status { get; set; }

        public string? CancellationReason { get; set; }
    }
}

