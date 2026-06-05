using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.EventPoints
{
    /// <summary>
    /// ViewModel cho form tạo quy tắc điểm mới
    /// 
    /// TẠI SAO EVENTPOINTS CẤU HÌNH ĐƯỢC:
    /// 
    /// 1. Tính linh hoạt:
    ///    - Mỗi sự kiện có thể có độ quan trọng khác nhau
    ///    - Sự kiện lớn → nhiều điểm, sự kiện nhỏ → ít điểm
    ///    - Admin có thể điều chỉnh để khuyến khích tham gia
    /// 
    /// 2. Phân biệt vai trò:
    ///    - Organizer làm việc nhiều → nhiều điểm hơn
    ///    - Volunteer đóng góp → điểm vừa phải
    ///    - Participant chỉ tham dự → ít điểm nhất
    /// 
    /// 3. Khuyến khích hành vi:
    ///    - Muốn nhiều volunteer → tăng điểm volunteer
    ///    - Muốn nhiều người tham dự → tăng điểm participant
    /// 
    /// CÁCH POINT CONFIGURATION ẢNH HƯỞNG ĐẾN ATTENDANCE POINT AWARDING:
    /// 
    /// Luồng cấp điểm:
    /// 1. User check-in thành công (IsValid = true)
    /// 2. Backend tìm EventPoint rule dựa vào:
    ///    - EventID
    ///    - User's RoleType trong event đó
    /// 3. Nếu tìm thấy rule → Cấp số điểm theo Points
    /// 4. Nếu không tìm thấy → Không cấp điểm (hoặc default = 0)
    /// 5. Points được lưu vào UserPoints table
    /// 6. Tính vào tổng điểm rèn luyện của user
    /// 
    /// Ví dụ:
    /// - Event "Hội thảo AI" có rule: Participant = 5 điểm
    /// - User A check-in với role = Participant
    /// - Backend cấp 5 điểm cho User A
    /// - Tổng điểm của User A tăng từ 50 → 55
    /// </summary>
    public class CreateEventPointViewModel
    {
        /// <summary>
        /// Vai trò - Required
        /// </summary>
        [Required(ErrorMessage = "Vui lòng chọn vai trò.")]
        [Display(Name = "Vai trò")]
        public string RoleType { get; set; } = string.Empty;

        /// <summary>
        /// Số điểm - Required, phải dương
        /// </summary>
        [Required(ErrorMessage = "Vui lòng nhập số điểm.")]
        [Range(1, int.MaxValue, ErrorMessage = "Số điểm phải lớn hơn 0.")]
        [Display(Name = "Số Điểm")]
        public int Points { get; set; }

        /// <summary>
        /// Mô tả - Tùy chọn
        /// </summary>
        [Display(Name = "Mô tả (Tùy chọn)")]
        [StringLength(255, ErrorMessage = "Mô tả không được vượt quá 255 ký tự.")]
        public string? Description { get; set; }
    }
}
