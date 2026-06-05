namespace UniYouth.Admin.Models.ViewModels.Events
{
    /// <summary>
    /// ViewModel cho mỗi event trong danh sách
    /// </summary>
    public class EventListItemViewModel
    {
        public int EventId { get; set; }
        public string EventName { get; set; } = string.Empty;
        public string? Description { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }
        public string? LocationName { get; set; }
        public int? MaxParticipants { get; set; }
        public int? CurrentParticipants { get; set; }
        public string Status { get; set; } = string.Empty;
        public string? StatusName { get; set; }
        public string? EventTypeName { get; set; }
        public string? InstituteName { get; set; }
        public string? ThumbnailUrl { get; set; }
        public bool EnableFaceVerification { get; set; }

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
        /// Hiển thị số lượng người tham gia
        /// </summary>
        public string ParticipantsDisplay
        {
            get
            {
                if (MaxParticipants.HasValue)
                    return $"{CurrentParticipants ?? 0} / {MaxParticipants}";
                return $"{CurrentParticipants ?? 0}";
            }
        }
    }
}
