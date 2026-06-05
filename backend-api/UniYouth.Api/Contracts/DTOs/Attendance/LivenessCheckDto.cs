using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Attendance
{
    /// <summary>
    /// Payload liveness gửi kèm request check-in.
    /// Giữ optional để backward compatibility cho client chưa triển khai Phase 3.
    /// </summary>
    public class LivenessCheckDto
    {
        /// <summary>
        /// Capture mode đã chốt ở Phase 3.
        /// Hiện tại chỉ chấp nhận passive_auto_burst.
        /// </summary>
        [StringLength(50, ErrorMessage = "Liveness.Mode không được vượt quá 50 ký tự")]
        public string? Mode { get; set; }

        /// <summary>
        /// Số frame trong burst liveness.
        /// Phase 3 hiện chốt = 3.
        /// </summary>
        [Range(1, 10, ErrorMessage = "Liveness.FrameCount phải trong khoảng 1 đến 10")]
        public int? FrameCount { get; set; }

        /// <summary>
        /// MIME type của toàn bộ burst.
        /// Hiện tại chỉ chấp nhận image/jpeg.
        /// </summary>
        [StringLength(50, ErrorMessage = "Liveness.MimeType không được vượt quá 50 ký tự")]
        public string? MimeType { get; set; }

        /// <summary>
        /// Danh sách frame liveness.
        /// </summary>
        public List<LivenessFrameDto>? Frames { get; set; }
    }

    public class LivenessFrameDto
    {
        /// <summary>
        /// Chỉ số thứ tự frame trong burst.
        /// </summary>
        [Range(0, 9, ErrorMessage = "Liveness.FrameIndex phải trong khoảng 0 đến 9")]
        public int FrameIndex { get; set; }

        /// <summary>
        /// Ảnh frame dạng Base64.
        /// </summary>
        [Required(ErrorMessage = "Liveness.ImageBase64 là bắt buộc")]
        public string ImageBase64 { get; set; } = string.Empty;

        /// <summary>
        /// Millisecond tính từ frame đầu tiên.
        /// </summary>
        [Range(0, int.MaxValue, ErrorMessage = "Liveness.CapturedAtMs phải >= 0")]
        public int CapturedAtMs { get; set; }
    }
}
