using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.Events
{
    /// <summary>
    /// ViewModel cho trang Edit Event
    /// </summary>
    public class EditEventViewModel : IValidatableObject
    {
        public int EventId { get; set; }

        public List<UniYouth.Admin.Models.DTOs.EventTypes.EventTypeDto> EventTypes { get; set; } = new();
        public List<UniYouth.Admin.Models.DTOs.LocationPresets.LocationPresetDto> LocationPresets { get; set; } = new();

        [Required(ErrorMessage = "Vui lòng nhập tên sự kiện")]
        [StringLength(200, ErrorMessage = "Tên sự kiện không được vượt quá 200 ký tự")]
        [Display(Name = "Tên sự kiện")]
        public string EventName { get; set; } = string.Empty;

        [Display(Name = "Mô tả")]
        [DataType(DataType.MultilineText)]
        public string? Description { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn thời gian bắt đầu")]
        [Display(Name = "Thời gian bắt đầu")]
        public DateTime? StartTime { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn thời gian kết thúc")]
        [Display(Name = "Thời gian kết thúc")]
        public DateTime? EndTime { get; set; }

        [StringLength(200, ErrorMessage = "Địa điểm không được vượt quá 200 ký tự")]
        [Display(Name = "Địa điểm")]
        public string? LocationName { get; set; }

        [Range(-90, 90, ErrorMessage = "Vĩ độ phải từ -90 đến 90")]
        [Display(Name = "Vĩ độ")]
        public double? Latitude { get; set; }

        [Range(-180, 180, ErrorMessage = "Kinh độ phải từ -180 đến 180")]
        [Display(Name = "Kinh độ")]
        public double? Longitude { get; set; }

        [Range(1, 10000, ErrorMessage = "Bán kính cho phép từ 1m đến 10000m")]
        [Display(Name = "Bán kính cho phép (m)")]
        public int AllowRadius { get; set; }

        [Range(1, int.MaxValue, ErrorMessage = "Số lượng tối đa phải lớn hơn 0")]
        [Display(Name = "Số lượng tối đa")]
        public int? MaxParticipants { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn loại sự kiện")]
        [Display(Name = "Loại sự kiện")]
        public int? EventTypeId { get; set; }

        [Display(Name = "Đơn vị tổ chức")]
        public int? InstituteId { get; set; }

        [Display(Name = "Hạn đăng ký")]
        public DateTime? RegistrationDeadline { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn trạng thái")]
        [Display(Name = "Trạng thái")]
        public int Status { get; set; }

        [Display(Name = "Bật xác minh khuôn mặt")]
        public bool EnableFaceVerification { get; set; }

        public IEnumerable<ValidationResult> Validate(ValidationContext validationContext)
        {
            // Nếu dùng GPS thì bắt buộc nhập cả Latitude và Longitude
            if (Latitude.HasValue ^ Longitude.HasValue)
            {
                if (!Latitude.HasValue)
                {
                    yield return new ValidationResult(
                        "Vui lòng nhập vĩ độ khi đã nhập kinh độ.",
                        new[] { nameof(Latitude) });
                }

                if (!Longitude.HasValue)
                {
                    yield return new ValidationResult(
                        "Vui lòng nhập kinh độ khi đã nhập vĩ độ.",
                        new[] { nameof(Longitude) });
                }
            }
        }
    }

}
