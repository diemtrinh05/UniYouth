using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Attendance
{
    public class CheckInRequirementsRequestDto
    {
        [Required(ErrorMessage = "QR token là bắt buộc")]
        public string QRToken { get; set; } = string.Empty;
    }
}
