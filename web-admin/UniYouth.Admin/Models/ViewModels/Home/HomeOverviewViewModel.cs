namespace UniYouth.Admin.Models.ViewModels.Home
{
    public class HomeOverviewViewModel
    {
        public string Greeting { get; set; } = "Chào bạn";

        public int TotalEvents { get; set; }
        public int OngoingEvents { get; set; }
        public int TotalValidAttendances { get; set; }
        public int DraftEvents { get; set; }

        public int TodayOngoingEvents { get; set; }

        public int AttendanceRatePercent { get; set; }

        public List<HomeRecentEventViewModel> RecentEvents { get; set; } = new();
        public Dictionary<string, HomeChartSeriesViewModel> ChartDataByPeriod { get; set; } = new();

        public bool HasError { get; set; }
        public string? ErrorMessage { get; set; }
    }

    public class HomeChartSeriesViewModel
    {
        public List<string> Labels { get; set; } = new();
        public List<int> EventCounts { get; set; } = new();
        public List<int> ValidAttendanceCounts { get; set; } = new();
    }

    public class HomeRecentEventViewModel
    {
        public int EventId { get; set; }
        public string EventName { get; set; } = string.Empty;
        public string? ThumbnailUrl { get; set; }
        public string? LocationName { get; set; }
        public DateTime StartTime { get; set; }
        public DateTime EndTime { get; set; }

        public string Status { get; set; } = string.Empty; // Draft/Open/Ongoing/Closed/Cancelled
        public string? StatusName { get; set; } // display name from API if present

        public int CurrentParticipants { get; set; }
        public int? MaxParticipants { get; set; }

        public int ParticipationPercent
        {
            get
            {
                if (!MaxParticipants.HasValue || MaxParticipants.Value <= 0) return 0;
                var pct = (int)Math.Round(CurrentParticipants * 100.0 / MaxParticipants.Value);
                return Math.Clamp(pct, 0, 100);
            }
        }

        public string ParticipantsDisplay =>
            MaxParticipants.HasValue ? $"{CurrentParticipants}/{MaxParticipants}" : $"{CurrentParticipants}";

        public string BadgeClass => Status switch
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

