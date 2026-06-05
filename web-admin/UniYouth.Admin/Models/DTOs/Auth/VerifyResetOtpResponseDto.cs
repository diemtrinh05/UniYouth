namespace UniYouth.Admin.Models.DTOs.Auth
{
    public class VerifyResetOtpResponseDto
    {
        public string VerificationTicket { get; set; } = string.Empty;
        public DateTime ExpiresAt { get; set; }
    }
}
