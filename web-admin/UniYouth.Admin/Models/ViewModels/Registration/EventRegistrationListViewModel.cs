using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.Registration
{
    /// <summary>
    /// ViewModel chính cho trang danh sách đăng ký
    /// </summary>
    public class EventRegistrationListViewModel
    {
        public int EventId { get; set; }

        [Display(Name = "Tên Sự kiện")]
        public string EventName { get; set; } = string.Empty;

        [Display(Name = "Danh sách Đăng ký")]
        public List<EventRegistrationViewModel> Registrations { get; set; } = new();

        public int? TotalFromApi { get; set; }

        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 20;
        public int? Status { get; set; }
        public string? Query { get; set; }

        public int TotalRegistrations => TotalFromApi ?? Registrations.Count;
        public int ReturnedCount => Registrations.Count;

        public int TotalPages =>
            PageSize > 0
                ? (int)Math.Ceiling((TotalRegistrations * 1.0) / PageSize)
                : 1;

        public int RegisteredCount =>
            Registrations.Count(r => r.StatusCode == EventRegistrationViewModel.StatusRegistered);

        public int CancelledCount =>
            Registrations.Count(r => r.StatusCode == EventRegistrationViewModel.StatusCancelled);

        public IReadOnlyDictionary<int, int> StatusCounts =>
            Registrations
                .GroupBy(r => r.StatusCode)
                .OrderBy(g => g.Key)
                .ToDictionary(g => g.Key, g => g.Count());

        public bool HasRegistrations => Registrations.Any();
    }
}
