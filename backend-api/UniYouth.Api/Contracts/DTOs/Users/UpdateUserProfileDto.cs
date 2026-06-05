using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Users
{
    /// <summary>
    /// DTO dùng để cập nhật thông tin hồ sơ người dùng
    /// Chỉ bao gồm các trường mà người dùng được phép chỉnh sửa
    /// </summary>
    public class UpdateUserProfileDto
    {
        /// <summary>
        /// Họ và tên
        /// </summary>
        [Required(ErrorMessage = "Họ và tên là bắt buộc")]
        [StringLength(100, MinimumLength = 2, ErrorMessage = "Họ và tên phải từ 2 đến 100 ký tự")]
        public string FullName { get; set; } = string.Empty;

        /// <summary>
        /// Số điện thoại
        /// </summary>
        [Phone(ErrorMessage = "Số điện thoại không đúng định dạng")]
        [StringLength(20, ErrorMessage = "Số điện thoại không được vượt quá 20 ký tự")]
        public string? Phone { get; set; }

        /// <summary>
        /// URL ảnh đại diện
        /// </summary>
        [StringLength(255, ErrorMessage = "URL ảnh đại diện không được vượt quá 255 ký tự")]
        [Url(ErrorMessage = "URL ảnh đại diện không đúng định dạng")]
        public string? AvatarUrl { get; set; }

        /// <summary>
        /// Giới tính (true: Nam, false: Nữ, null: Không xác định)
        /// </summary>
        public bool? Gender { get; set; }

        /// <summary>
        /// Ngày sinh
        /// </summary>
        public DateOnly? DateOfBirth { get; set; }

        /// <summary>
        /// Địa chỉ
        /// </summary>
        [StringLength(255, ErrorMessage = "Địa chỉ không được vượt quá 255 ký tự")]
        public string? Address { get; set; }

        /// <summary>
        /// ID chức vụ chuẩn hóa.
        ///
        /// Lưu ý: Backend sẽ tự resolve UnitId tương ứng từ PositionId.
        /// </summary>
        [Range(1, int.MaxValue, ErrorMessage = "PositionId không hợp lệ")]
        public int? PositionId { get; set; }

        /// <summary>
        /// ID viện (tham chiếu theo Unit).
        /// 
        /// Lưu ý: InstituteId không phải nguồn sự thật, backend sẽ validate khớp với UnitId/Unit hiện tại.
        /// </summary>
        [Range(1, int.MaxValue, ErrorMessage = "InstituteId không hợp lệ")]
        public int? InstituteId { get; set; }

        /// <summary>
        /// Ngày tham gia đơn vị hiện tại.
        /// </summary>
        public DateOnly? JoinDate { get; set; }

        /// <summary>
        /// Chức vụ/vai trò trong đơn vị.
        ///
        /// Legacy output field. Request mới dùng PositionId làm nguồn sự thật.
        /// </summary>
        [StringLength(100, ErrorMessage = "Position không được vượt quá 100 ký tự")]
        public string? Position { get; set; }
    }
}
