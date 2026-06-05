using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Contracts.DTOs.Events
{
    /// <summary>
    /// DTO dùng cho chi tiết sự kiện (sử dụng trong API GET /events/{id})
    /// Chứa đầy đủ thông tin sự kiện bao gồm hình ảnh và vị trí tổ chức
    /// </summary>
    public class EventDetailDto
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
        /// Mô tả chi tiết
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
        /// Vĩ độ GPS
        /// </summary>
        public decimal? Latitude { get; set; }

        /// <summary>
        /// Kinh độ GPS
        /// </summary>
        public decimal? Longitude { get; set; }

        /// <summary>
        /// Bán kính hợp lệ để check-in (đơn vị: mét)
        /// </summary>
        public int? AllowRadius { get; set; }

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
        /// </summary>
        public EventStatus Status { get; set; }

        /// <summary>
        /// Tên trạng thái
        /// </summary>
        public string StatusName { get; set; } = string.Empty;

        /// <summary>
        /// Loại sự kiện
        /// </summary>
        public EventTypeInfoDto EventType { get; set; } = null!;

        /// <summary>
        /// Thông tin viện (có thể null nếu là sự kiện chung)
        /// </summary>
        public InstituteInfoDto? Institute { get; set; }

        /// <summary>
        /// Hạn đăng ký tham gia sự kiện
        /// </summary>
        public DateTime? RegistrationDeadline { get; set; }

        /// <summary>
        /// Có bật xác minh khuôn mặt cho sự kiện hay không
        /// </summary>
        public bool EnableFaceVerification { get; set; }

        /// <summary>
        /// Danh sách ảnh của sự kiện
        /// </summary>
        public List<EventImageDto> Images { get; set; } = new();

        /// <summary>
        /// Người tạo sự kiện
        /// </summary>
        public string CreatedByName { get; set; } = string.Empty;

        /// <summary>
        /// Ngày tạo
        /// </summary>
        public DateTime? CreatedDate { get; set; }

        /// <summary>
        /// Còn chỗ trống hay không
        /// </summary>
        public bool HasAvailableSlots { get; set; }

        /// <summary>
        /// Đã quá hạn đăng ký chưa
        /// </summary>
        public bool IsRegistrationClosed { get; set; }
    }

    /// <summary>
    /// Thông tin loại sự kiện
    /// </summary>
    public class EventTypeInfoDto
    {
        public int TypeId { get; set; }
        public string TypeName { get; set; } = string.Empty;
        public string? Description { get; set; }
    }

    /// <summary>
    /// Thông tin viện
    /// </summary>
    public class InstituteInfoDto
    {
        public int InstituteId { get; set; }
        public string InstituteName { get; set; } = string.Empty;
    }

    /// <summary>
    /// Thông tin hình ảnh của sự kiện
    /// </summary>
    public class EventImageDto
    {
        /// <summary>
        /// ID của hình ảnh
        /// </summary>
        public int ImageId { get; set; }
        /// <summary>
        /// Đường dẫn URL của hình ảnh
        /// </summary>
        public string ImageUrl { get; set; } = string.Empty;
        public string? ImageType { get; set; }
        /// <summary>
        /// Chú thích hình ảnh
        /// </summary>
        public string? Caption { get; set; }
        /// <summary>
        /// Thứ tự hiển thị của hình ảnh
        /// </summary>
        public int? DisplayOrder { get; set; }
    }
}
