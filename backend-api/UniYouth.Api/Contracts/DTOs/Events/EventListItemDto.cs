using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Contracts.DTOs.Events
{
    /// <summary>
    /// DTO dùng cho danh sách sự kiện (sử dụng trong API GET /events)
    /// Là model gọn nhẹ để hiển thị danh sách sự kiện
    /// </summary>
    public class EventListItemDto
    {
        /// <summary>
        /// Event ID
        /// </summary>
        public int EventId { get; set; }

        /// <summary>
        /// Tên sự kiện
        /// </summary>
        public string EventName { get; set; } = string.Empty;

        /// <summary>
        /// Mô tả ngắn
        /// </summary>
        public string? Description { get; set; }

        /// <summary>
        /// Thời gian bắt đầu
        /// </summary>
        public DateTime StartTime { get; set; }

        /// <summary>
        /// Thời gian kết thúc
        /// </summary>
        public DateTime EndTime { get; set; }

        /// <summary>
        /// Địa điểm tổ chức
        /// </summary>
        public string? LocationName { get; set; }

        /// <summary>
        /// Số người tham gia tối đa
        /// </summary>
        public int? MaxParticipants { get; set; }

        /// <summary>
        /// Số người đã đăng ký
        /// </summary>
        public int? CurrentParticipants { get; set; }

        /// <summary>
        /// Trạng thái sự kiện
        /// (0: Nháp, 1: Mở đăng ký, 2: Đang diễn ra, 3: Đã kết thúc, 4: Đã hủy)
        /// </summary>
        public EventStatus Status { get; set; }

        /// <summary>
        /// Tên trạng thái (hiển thị cho người dùng)
        /// </summary>
        public string StatusName { get; set; } = string.Empty;

        /// <summary>
        /// Loại sự kiện
        /// </summary>
        public string EventTypeName { get; set; } = string.Empty;

        /// <summary>
        /// Tên viện
        /// </summary>
        public string? InstituteName { get; set; }

        /// <summary>
        /// Hạn đăng ký
        /// </summary>
        public DateTime? RegistrationDeadline { get; set; }

        /// <summary>
        /// Có bật xác minh khuôn mặt cho sự kiện hay không
        /// </summary>
        public bool EnableFaceVerification { get; set; }

        /// <summary>
        /// URL ảnh thumbnail (ảnh đầu tiên)
        /// </summary>
        public string? ThumbnailUrl { get; set; }

        /// <summary>
        /// Còn chỗ trống hay không
        /// </summary>
        public bool HasAvailableSlots { get; set; }
    }
}
