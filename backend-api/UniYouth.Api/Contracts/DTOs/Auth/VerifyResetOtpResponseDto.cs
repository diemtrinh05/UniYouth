namespace UniYouth.Api.Contracts.DTOs.Auth
{
    public class VerifyResetOtpResponseDto
    {
        public string VerificationTicket { get; set; } = string.Empty;

        public DateTime ExpiresAt { get; set; }
    }
}
