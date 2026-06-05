namespace UniYouth.Admin.Models.DTOs.Auth
{
    public class ResetPasswordRequestDto
    {
        public string? Token { get; set; }
        public string? VerificationTicket { get; set; }
        public string NewPassword { get; set; } = string.Empty;
    }
}
