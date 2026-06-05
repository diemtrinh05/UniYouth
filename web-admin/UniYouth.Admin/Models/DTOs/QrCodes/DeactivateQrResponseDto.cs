namespace UniYouth.Admin.Models.DTOs.QrCodes
{
    /// <summary>
    /// DTO cho response khi deactivate QR code
    /// </summary>
    public class DeactivateQrResponseDto
    {
        public bool Success { get; set; }
        public string? Message { get; set; }
        public int Qrid { get; set; }
        public DateTime DeactivatedAt { get; set; }
    }

    /// <summary>
    /// DTO đại diện cho thông tin sự kiện (tái sử dụng)
    /// </summary>
    //public class EventDetailDto
    //{
    //    public int EventId { get; set; }
    //    public string? EventName { get; set; }
    //    public string? Description { get; set; }
    //    public DateTime StartTime { get; set; }
    //    public DateTime EndTime { get; set; }
    //    public string? LocationName { get; set; }
    //    public string? StatusName { get; set; }
    //}
}
