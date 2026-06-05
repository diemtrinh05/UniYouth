using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.EventPoints
{
    /// <summary>
    /// ViewModel đại diện cho một quy tắc điểm trong danh sách
    /// </summary>
    public class EventPointViewModel
    {
        public int EventPointID { get; set; }
        public int EventID { get; set; }

        [Display(Name = "Vai trò")]
        public string RoleType { get; set; } = string.Empty;

        [Display(Name = "Số Điểm")]
        public int Points { get; set; }

        [Display(Name = "Mô tả")]
        public string? Description { get; set; }

        [Display(Name = "Ngày tạo")]
        [DisplayFormat(DataFormatString = "{0:dd/MM/yyyy HH:mm}")]
        public DateTime? CreatedDate { get; set; }

        /// <summary>
        /// Helper: Badge class cho role type
        /// </summary>
        public string RoleBadgeClass => RoleType switch
        {
            "Organizer" => "bg-primary",
            "Participant" => "bg-success",
            "Volunteer" => "bg-info",
            _ => "bg-secondary"
        };

        /// <summary>
        /// Helper: Icon cho role type
        /// </summary>
        public string RoleIcon => RoleType switch
        {
            "Organizer" => "bi-person-gear",
            "Participant" => "bi-person-check",
            "Volunteer" => "bi-people-fill",
            _ => "bi-person"
        };

        /// <summary>
        /// Helper: Display text tiếng Việt cho role
        /// </summary>
        public string RoleDisplayText => RoleType switch
        {
            "Organizer" => "Ban tổ chức",
            "Participant" => "Người tham gia",
            "Volunteer" => "Tình nguyện viên",
            _ => RoleType
        };
    }
}
