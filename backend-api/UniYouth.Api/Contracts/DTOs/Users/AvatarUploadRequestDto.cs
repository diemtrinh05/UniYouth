namespace UniYouth.Api.Contracts.DTOs.Users
{
    /// <summary>
    /// DTO dùng cho upload ảnh đại diện
    /// </summary>
    public class AvatarUploadRequestDto
    {
        /// <summary>
        /// File ảnh đại diện (JPG, PNG, WEBP)
        /// </summary>
        public IFormFile File { get; set; } = null!;
    }
}
