namespace UniYouth.Admin.Models.DTOs.Auth
{
    /// <summary>
    /// Kết quả đăng nhập để xử lý trong controller
    /// </summary>
    public class LoginResult
    {
        public bool Success { get; set; }
        public string Message { get; set; } = string.Empty;
        public LoginResponseDto? Data { get; set; }
    }
}
