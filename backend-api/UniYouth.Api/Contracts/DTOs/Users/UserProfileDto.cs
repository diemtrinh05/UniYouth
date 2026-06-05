namespace UniYouth.Api.Contracts.DTOs.Users
{
    /// <summary>
    /// DTO chứa thông tin hồ sơ người dùng
    /// Đại diện cho toàn bộ dữ liệu hồ sơ được trả về cho người dùng đã xác thực
    /// </summary>
    public class UserProfileDto
    {
        /// <summary>
        /// User ID
        /// </summary>
        public int UserId { get; set; }

        /// <summary>
        /// Mã
        /// </summary>
        public string Code { get; set; } = string.Empty;

        /// <summary>
        /// Họ và tên
        /// </summary>
        public string FullName { get; set; } = string.Empty;

        /// <summary>
        /// Email (được sử dụng để đăng nhập)
        /// </summary>
        public string Email { get; set; } = string.Empty;

        /// <summary>
        /// Số điện thoại
        /// </summary>
        public string? Phone { get; set; }

        /// <summary>
        /// URL ảnh đại diện
        /// </summary>
        public string? AvatarUrl { get; set; }

        /// <summary>
        /// Người dùng hiện có FaceProfile active usable hay không
        /// </summary>
        public bool HasActiveFaceProfile { get; set; }

        /// <summary>
        /// URL ảnh gốc của FaceProfile active
        /// </summary>
        public string? FaceProfileImageUrl { get; set; }

        /// <summary>
        /// Thời điểm cập nhật FaceProfile active gần nhất
        /// </summary>
        public DateTime? FaceProfileUpdatedDate { get; set; }

        /// <summary>
        /// QualityScore của FaceProfile active
        /// </summary>
        public double? FaceProfileQualityScore { get; set; }

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
        public string? Address { get; set; }

        /// <summary>
        /// Vai trò chính của người dùng (Admin, CanBo, DoanVien, HoiVien)
        /// </summary>
        public string? Role { get; set; }

        /// <summary>
        /// Tên đơn vị (Chi Đoàn/Chi Hội)
        /// </summary>
        public string? UnitName { get; set; }

        /// <summary>
        /// ID đơn vị (Chi Đoàn/Chi Hội)
        /// </summary>
        public int? UnitId { get; set; }

        /// <summary>
        /// ID chức vụ chuẩn hóa
        /// </summary>
        public int? PositionId { get; set; }

        /// <summary>
        /// Ngày tham gia đơn vị hiện tại
        /// </summary>
        public DateOnly? JoinDate { get; set; }

        /// <summary>
        /// Chức vụ/vai trò trong đơn vị hiện tại
        /// </summary>
        public string? Position { get; set; }

        /// <summary>
        /// Tên viện
        /// </summary>
        public string? InstituteName { get; set; }

        /// <summary>
        /// ID viện
        /// </summary>
        public int? InstituteId { get; set; }

        /// <summary>
        /// Trạng thái tài khoản (1: Active, 0: Inactive)
        /// </summary>
        public byte? Status { get; set; }

        /// <summary>
        /// Ngày đăng nhập gần nhất
        /// </summary>
        public DateTime? LastLoginDate { get; set; }

        /// <summary>
        /// Ngày tạo tài khoản
        /// </summary>
        public DateTime? CreatedDate { get; set; }
    }
}


