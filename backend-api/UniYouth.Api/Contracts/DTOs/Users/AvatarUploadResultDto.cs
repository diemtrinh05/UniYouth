namespace UniYouth.Api.Contracts.DTOs.Users
{
    /// <summary>
    /// DTO kết quả tải ảnh đại diện
    /// Trả về đường dẫn URL công khai của ảnh đại diện đã được tải lên
    /// </summary>
    public class AvatarUploadResultDto
    {
        /// <summary>
        /// Đường dẫn URL công khai tới ảnh đại diện
        /// Ví dụ: "/uploads/avatars/avatar_5.jpg"
        /// Có thể sử dụng trực tiếp trong thuộc tính src của thẻ img HTML
        /// hoặc trong các phản hồi API
        /// </summary>
        public string AvatarUrl { get; set; } = string.Empty;

        /// <summary>
        /// Thông báo tùy chọn liên quan đến quá trình tải ảnh
        /// </summary>
        public string? Message { get; set; }
    }
}
