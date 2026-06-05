namespace UniYouth.Admin.Models.DTOs.EventImages
{
    /// <summary>
    /// Body cho PUT /api/events/images/{imageId}
    /// Swagger: UpdateEventImageRequestDto
    /// </summary>
    public class UpdateEventImageRequestDto
    {
        public string? ImageType { get; set; }
        public string? Caption { get; set; }
    }
}

