namespace UniYouth.Admin.Models.DTOs.EventImages
{
    /// <summary>
    /// DTO đại diện cho thông tin chi tiết sự kiện
    /// </summary>
    public class EventDetailDto
    {
        public int EventId { get; set; }
        public string? EventName { get; set; }
        public string? Description { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string? LocationName { get; set; }
        public int? MaxParticipants { get; set; }
        public string? StatusName { get; set; }
    }
}
