using System.ComponentModel.DataAnnotations;
using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Contracts.DTOs.Events
{
    /// <summary>
    /// DTO dùng để cập nhật sự kiện (sử dụng trong API PUT /events/{id})
    /// Chỉ dành cho Cán bộ và Admin
    /// </summary>
    public class UpdateEventRequestDto
    {
        /// <summary>
        /// Tên sự kiện
        /// </summary>
        [Required(ErrorMessage = "Tên sự kiện là bắt buộc")]
        [StringLength(200, ErrorMessage = "Tên sự kiện không được vượt quá 200 ký tự")]
        public string EventName { get; set; } = string.Empty;

        /// <summary>
        /// Mô tả
        /// </summary>
        public string? Description { get; set; }

        /// <summary>
        /// Thời gian bắt đầu
        /// </summary>
        [Required(ErrorMessage = "Thời gian bắt đầu là bắt buộc")]
        public DateTime StartTime { get; set; }

        /// <summary>
        /// Thời gian kết thúc
        /// </summary>
        [Required(ErrorMessage = "Thời gian kết thúc là bắt buộc")]
        public DateTime EndTime { get; set; }

        /// <summary>
        /// Địa điểm tổ chức
        /// </summary>
        [StringLength(200, ErrorMessage = "Tên địa điểm không được vượt quá 200 ký tự")]
        public string? LocationName { get; set; }

        /// <summary>
        /// Vĩ độ GPS
        /// </summary>
        [Range(-90, 90, ErrorMessage = "Vĩ độ phải từ -90 đến 90")]
        public decimal? Latitude { get; set; }

        /// <summary>
        /// Kinh độ GPS
        /// </summary>
        [Range(-180, 180, ErrorMessage = "Kinh độ phải từ -180 đến 180")]
        public decimal? Longitude { get; set; }

        /// <summary>
        /// Bán kính hợp lệ (mét)
        /// </summary>
        [Range(1, 10000, ErrorMessage = "Bán kính phải từ 1 đến 10000 mét")]
        public int AllowRadius { get; set; } = 100;

        /// <summary>
        /// Số người tham gia tối đa (null = không giới hạn)
        /// </summary>
        [Range(1, int.MaxValue, ErrorMessage = "Số người tham gia tối đa phải lớn hơn 0")]
        public int? MaxParticipants { get; set; }

        /// <summary>
        /// Loại sự kiện
        /// </summary>
        [Required(ErrorMessage = "Loại sự kiện là bắt buộc")]
        public int EventTypeId { get; set; }

        /// <summary>
        /// Viện (null nếu là sự kiện chung)
        /// </summary>
        public int? InstituteId { get; set; }

        /// <summary>
        /// Hạn đăng ký
        /// </summary>
        public DateTime? RegistrationDeadline { get; set; }

        /// <summary>
        /// Có bật xác minh khuôn mặt cho sự kiện hay không
        /// </summary>
        public bool EnableFaceVerification { get; set; } = false;

        /// <summary>
        /// Trạng thái (0: Nháp, 1: Mở đăng ký, 2: Đang diễn ra, 3: Đã kết thúc, 4: Đã hủy)
        /// </summary>
        [Required]
        [EnumDataType(typeof(EventStatus), ErrorMessage = "Trạng thái không hợp lệ")]
        public EventStatus Status { get; set; }
    }
}
