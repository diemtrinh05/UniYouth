using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Events
{
    /// <summary>
    /// DTO yêu cầu hủy sự kiện (Cancel)
    /// </summary>
    public class CancelEventRequestDto
    {
        /// <summary>
        /// Lý do hủy (không bắt buộc)
        /// </summary>
        [StringLength(255, ErrorMessage = "Lý do hủy không được vượt quá 255 ký tự")]
        public string? Reason { get; set; }
    }
}

