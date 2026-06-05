namespace UniYouth.Admin.Models.DTOs.Events.Common
{
    public class EventImageDto
    {
        public int ImageId { get; set; }
        public string? ImageUrl { get; set; }
        public string? ImageType { get; set; }
        public string? Caption { get; set; }
        public int? DisplayOrder { get; set; }
    }
}
