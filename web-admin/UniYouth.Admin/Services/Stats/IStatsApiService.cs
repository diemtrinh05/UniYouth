using UniYouth.Admin.Models.DTOs.Stats;

namespace UniYouth.Admin.Services.Stats
{
    public interface IStatsApiService
    {
        Task<EventAttendanceStats?> GetEventAttendanceStatsAsync(int eventId);
        Task<List<EventStatsListItem>?> GetAllEventsStatsAsync();
    }
}
