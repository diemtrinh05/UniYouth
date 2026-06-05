namespace UniYouth.Admin.Models.DTOs.Auth
{
    /// <summary>
    /// DTO cho request đăng nhập gửi đến API
    /// Phải khớp với schema trong swagger.json
    /// </summary>
    public class LoginRequestDto
    {
        public string Code { get; set; } = string.Empty;
        public string Password { get; set; } = string.Empty;
    }
}

