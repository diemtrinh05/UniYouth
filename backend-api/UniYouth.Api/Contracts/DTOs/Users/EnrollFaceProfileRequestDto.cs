using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Users
{
    public class EnrollFaceProfileRequestDto
    {
        [Required(ErrorMessage = "faceImageBase64 là bắt buộc.")]
        [MinLength(16, ErrorMessage = "faceImageBase64 không hợp lệ.")]
        public string FaceImageBase64 { get; set; } = string.Empty;

        [Required(ErrorMessage = "faceImageMimeType là bắt buộc.")]
        [MaxLength(50, ErrorMessage = "faceImageMimeType tối đa 50 ký tự.")]
        public string FaceImageMimeType { get; set; } = "image/jpeg";

        [MaxLength(255, ErrorMessage = "currentPassword tối đa 255 ký tự.")]
        public string? CurrentPassword { get; set; }

        [MaxLength(6, ErrorMessage = "reauthOtpCode tối đa 6 ký tự.")]
        public string? ReauthOtpCode { get; set; }
    }
}
