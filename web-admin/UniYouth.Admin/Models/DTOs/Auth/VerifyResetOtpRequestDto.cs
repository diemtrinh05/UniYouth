namespace UniYouth.Admin.Models.DTOs.Auth
{
    public class VerifyResetOtpRequestDto
    {
        public string Account { get; set; } = string.Empty;
        public string OtpCode { get; set; } = string.Empty;
    }
}
