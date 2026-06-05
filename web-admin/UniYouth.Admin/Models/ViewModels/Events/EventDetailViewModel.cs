namespace UniYouth.Admin.Models.ViewModels.Events
{
    /// <summary>
    /// ViewModel cho trang Event Details
    /// </summary>
    public class EventDetailViewModel
    {
        public int EventId { get; set; }
        public string EventName { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string? LocationName { get; set; }
        public double? Latitude { get; set; }
        public double? Longitude { get; set; }
        public int? AllowRadius { get; set; }
        public int? MaxParticipants { get; set; }
        public int? CurrentParticipants { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? StatusName { get; set; }
        public string? EventTypeName { get; set; }
        public string? InstituteName { get; set; }
        public DateTime? RegistrationDeadline { get; set; }
        public string? CreatedByName { get; set; }
        public DateTime? CreatedDate { get; set; }
        public List<string> ImageUrls { get; set; } = new();
        public bool EnableFaceVerification { get; set; }

        public bool HasEventPointsConfigured { get; set; }
        public int? EventPointsCount { get; set; }

        /// <summary>
        /// CSS class cho status badge
        /// </summary>
        public string StatusBadgeClass
        {
            get
            {
                return Status switch
                {
                    "Draft" => "bg-secondary",
                    "Open" => "bg-info",
                    "Ongoing" => "bg-success",
                    "Closed" => "bg-dark",
                    "Cancelled" => "bg-danger",
                    _ => "bg-secondary"
                };
            }
        }

        /// <summary>
        /// Kiểm tra sự kiện có còn chỗ không
        /// </summary>
        public bool HasAvailableSlots
        {
            get
            {
                if (!MaxParticipants.HasValue) return true;
                return (CurrentParticipants ?? 0) < MaxParticipants.Value;
            }
        }

        /// <summary>
        /// Kiểm tra hết hạn đăng ký chưa
        /// </summary>
        public bool IsRegistrationClosed
        {
            get
            {
                if (!RegistrationDeadline.HasValue) return false;
                return DateTime.Now > RegistrationDeadline.Value;
            }
        }
    }
}
