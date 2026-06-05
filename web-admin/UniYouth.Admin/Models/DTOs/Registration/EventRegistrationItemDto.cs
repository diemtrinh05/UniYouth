namespace UniYouth.Admin.Models.DTOs.Registration
{
    /// <summary>
    /// DTO item theo swagger: EventRegistrationItemDto
    /// </summary>
    public class EventRegistrationItemDto
    {
        public int RegistrationId { get; set; }
        public int UserId { get; set; }
        public string? Code { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public DateTime? RegisterTime { get; set; }
        public int Status { get; set; }
        public string? CancellationReason { get; set; }
    }
}

