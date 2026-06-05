namespace UniYouth.Api.Contracts.DTOs.Users
{
    /// <summary>
    /// DTO kết quả đổi mật khẩu
    /// Chỉ chứa trạng thái và thông báo – KHÔNG chứa dữ liệu mật khẩu
    /// </summary>
    public class ChangePasswordResultDto
    {
        /// <summary>
        /// Trạng thái đổi mật khẩu thành công hay thất bại
        /// </summary>
        public bool Success { get; set; }

        /// <summary>
        /// Thông báo kết quả xử lý
        /// </summary>
        public string Message { get; set; } = string.Empty;

        /// <summary>
        /// Thông tin bổ sung (nếu có)
        /// Ví dụ: "Vui lòng đăng nhập lại bằng mật khẩu mới"
        public string? AdditionalInfo { get; set; }
    }
}
