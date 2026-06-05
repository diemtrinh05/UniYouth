using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.EventPoints
{
    /// <summary>
    /// ViewModel cho form sửa quy tắc điểm
    /// </summary>
    public class EditEventPointViewModel
    {
        public int EventPointID { get; set; }
        public int EventID { get; set; }

        /// <summary>
        /// RoleType không được sửa (immutable)
        /// Nếu muốn đổi role → xóa rule cũ, tạo rule mới
        /// </summary>
        [Display(Name = "Vai trò")]
        public string RoleType { get; set; } = string.Empty;

        /// <summary>
        /// Số điểm mới
        /// </summary>
        [Required(ErrorMessage = "Vui lòng nhập số điểm.")]
        [Range(1, int.MaxValue, ErrorMessage = "Số điểm phải lớn hơn 0.")]
        [Display(Name = "Số Điểm")]
        public int Points { get; set; }

        /// <summary>
        /// Mô tả mới
        /// </summary>
        [Display(Name = "Mô tả (Tùy chọn)")]
        [StringLength(255, ErrorMessage = "Mô tả không được vượt quá 255 ký tự.")]
        public string? Description { get; set; }
    }
}
