using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.EventPoints
{
    /// <summary>
    /// ViewModel chính cho trang quản lý điểm
    /// </summary>
    public class EventPointListViewModel
    {
        public int EventId { get; set; }

        [Display(Name = "Tên Sự kiện")]
        public string EventName { get; set; } = string.Empty;

        [Display(Name = "Quy tắc Điểm")]
        public List<EventPointViewModel> EventPoints { get; set; } = new();

        /// <summary>
        /// Các vai trò có sẵn (từ enum hoặc constant)
        /// </summary>
        public string[] AvailableRoles { get; set; } = new[]
        {
            "Participant"
        };

        /// <summary>
        /// Helper properties
        /// </summary>
        public int TotalRules => EventPoints.Count;
        public bool HasRules => EventPoints.Any();

        /// <summary>
        /// Kiểm tra vai trò đã có quy tắc chưa (để prevent duplicate)
        /// </summary>
        public bool HasRoleType(string roleType)
        {
            return EventPoints.Any(p => p.RoleType.Equals(roleType, StringComparison.OrdinalIgnoreCase));
        }

        /// <summary>
        /// Lấy các vai trò chưa có quy tắc
        /// </summary>
        public IEnumerable<string> AvailableRolesToAdd
        {
            get
            {
                return AvailableRoles.Where(r => !HasRoleType(r));
            }
        }
    }
}
