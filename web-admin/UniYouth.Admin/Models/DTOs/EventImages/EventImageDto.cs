namespace UniYouth.Admin.Models.DTOs.EventImages
{
    /// <summary>
    /// DTO đại diện cho thông tin hình ảnh sự kiện từ API
    /// </summary>
    public class EventImageDto
    {
        public int ImageId { get; set; }
        public string? ImageUrl { get; set; }
        public string? ImageType { get; set; }
        public string? Caption { get; set; }
        public int? DisplayOrder { get; set; }
    }
}
