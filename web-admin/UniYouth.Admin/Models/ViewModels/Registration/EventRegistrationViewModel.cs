using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.Registration
{
    /// <summary>
    /// ViewModel đại diện cho một đăng ký sự kiện
    /// Sử dụng trong danh sách đăng ký
    /// </summary>
    public class EventRegistrationViewModel
    {
        public const int StatusRegistered = 0;
        public const int StatusCancelled = 1;

        public int RegistrationID { get; set; }
        public int UserID { get; set; }

        [Display(Name = "Mã Sinh viên")]
        public string Code { get; set; } = string.Empty;

        [Display(Name = "Họ và Tên")]
        public string FullName { get; set; } = string.Empty;

        [Display(Name = "Email")]
        public string Email { get; set; } = string.Empty;

        [Display(Name = "Thời gian Đăng ký")]
        [DisplayFormat(DataFormatString = "{0:dd/MM/yyyy HH:mm}")]
        public DateTime RegisterTime { get; set; }

        [Display(Name = "Trạng thái")]
        public int StatusCode { get; set; }

        [Display(Name = "Lý do hủy")]
        public string? CancellationReason { get; set; }

        public bool IsRegistered => StatusCode == StatusRegistered;
        public bool IsCancelled => StatusCode == StatusCancelled;

        public string StatusBadgeClass => StatusCode switch
        {
            StatusRegistered => "bg-success",
            StatusCancelled => "bg-danger",
            _ => "bg-secondary"
        };

        public string StatusIcon => StatusCode switch
        {
            StatusRegistered => "bi-check-circle-fill",
            StatusCancelled => "bi-x-circle-fill",
            _ => "bi-question-circle"
        };

        public string StatusDisplay => StatusCode switch
        {
            StatusRegistered => "Đã đăng ký",
            StatusCancelled => "Đã hủy",
            _ => $"Không rõ ({StatusCode})"
        };
    }
}

