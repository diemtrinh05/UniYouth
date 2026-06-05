using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Events.Points
{
    /// <summary>
    /// DTO dùng để cập nhật cấu hình điểm sự kiện đã tồn tại.
    /// 
    /// DTO này chỉ cho phép chỉnh sửa:
    /// - Số điểm rèn luyện
    /// - Mô tả quy tắc điểm
    /// 
    /// Việc KHÔNG cho phép cập nhật RoleType là có chủ đích,
    /// nhằm đảm bảo tính toàn vẹn dữ liệu và tránh xung đột nghiệp vụ.
    /// </summary>
    public class UpdateEventPointRequestDto
    {
        /// <summary>
        /// Số điểm rèn luyện mới được áp dụng cho vai trò tương ứng.
        /// 
        /// Giá trị phải là số nguyên dương (> 0).
        [Required(ErrorMessage = "Points là bắt buộc")]
        [Range(1, int.MaxValue, ErrorMessage = "Points phải là số nguyên dương")]
        public int Points { get; set; }

        /// <summary>
        /// Mô tả mới cho quy tắc điểm.
        /// 
        /// Trường này dùng để giải thích ý nghĩa hoặc mục đích
        /// của cấu hình điểm, phục vụ việc quản lý và báo cáo.
        /// </summary>
        [MaxLength(255, ErrorMessage = "Description không được vượt quá 255 ký tự")]
        public string? Description { get; set; }

        /*
         * LƯU Ý:
         * RoleType KHÔNG được phép cập nhật thông qua DTO này.
         * 
         * Lý do:
         * - RoleType là một phần của khóa logic (EventID + RoleType)
         * - Thay đổi RoleType có thể tạo ra cấu hình trùng lặp
         * - Có thể làm sai lệch các bản ghi ActivityPoints đã được tạo
         * 
         * Nếu cần thay đổi RoleType:
         * - Hãy xóa cấu hình hiện tại
         * - Sau đó tạo mới một cấu hình điểm với RoleType mong muốn
         */
    }
}
