using UniYouth.Admin.Models.DTOs.Events.Common;

namespace UniYouth.Admin.Models.DTOs.EventImages
{
    /// <summary>
    /// DTO đại diện cho response khi upload hình ảnh
    /// </summary>
    public class UploadEventImageResponseDto
    {
        public int UploadedCount { get; set; }
        public List<EventImagesDto>? Images { get; set; }
        public string? Message { get; set; }
    }
    /// <summary>
    /// DTO chi tiết của hình ảnh sau khi upload
    /// </summary>
    public class EventImagesDto
    {
        public int ImageId { get; set; }
        public int EventId { get; set; }
        public string? ImageUrl { get; set; }
        public string? ImageType { get; set; }
        public string? Caption { get; set; }
        public int? DisplayOrder { get; set; }
        public DateTime? CreatedDate { get; set; }
    }
}
