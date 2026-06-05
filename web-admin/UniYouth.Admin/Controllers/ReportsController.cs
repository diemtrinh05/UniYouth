using Microsoft.AspNetCore.Mvc;
using UniYouth.Admin.Models.DTOs.Reports;
using System.Text;
using UniYouth.Admin.Models.ViewModels.Reports;
using UniYouth.Admin.Services.Reports;

namespace UniYouth.Admin.Controllers
{
    /// <summary>
    /// Controller quản lý các báo cáo và thống kê sự kiện
    /// - Hiển thị danh sách báo cáo điểm danh của tất cả sự kiện
    /// - Hiển thị chi tiết báo cáo điểm danh của một sự kiện cụ thể
    /// 
    /// QUAN TRỌNG:
    /// - Báo cáo là READ-ONLY (chỉ xem, không sửa)
    /// - Dữ liệu được lấy từ database view vw_EventAttendanceStats
    /// - Chỉ Admin và CanBo mới có quyền xem báo cáo
    /// </summary>
    public class ReportsController : BaseController
    {
        private readonly IReportsApiService _reportsService;
        private readonly ILogger<ReportsController> _logger;

        public ReportsController(
            IReportsApiService reportsService,
            ILogger<ReportsController> logger)
        {
            _reportsService = reportsService;
            _logger = logger;
        }

        /// <summary>
        /// GET: /Reports
        /// Hiển thị danh sách báo cáo thống kê điểm danh của tất cả sự kiện
        /// 
        /// Data source: API GET /api/events/all/attendance-stats
        /// Database view: vw_EventAttendanceStats
        /// </summary>
        /// <param name="searchTerm">Từ khóa tìm kiếm theo tên sự kiện</param>
        /// <param name="startDate">Lọc sự kiện từ ngày</param>
        /// <param name="endDate">Lọc sự kiện đến ngày</param>
        [HttpGet]
        public async Task<IActionResult> Index(
            string? searchTerm,
            DateTime? startDate,
            DateTime? endDate,
            int? status = null,
            string? sortBy = null,
            string? sortDir = null,
            int pageNumber = 1,
            int pageSize = 10)
        {
            try
            {
                _logger.LogInformation(
                    "User {UserId} đang xem danh sách báo cáo. Filters: search={Search}, startDate={StartDate}, endDate={EndDate}",
                    CurrentUserId, searchTerm, startDate, endDate);

                var from = startDate?.Date;
                var to = endDate?.Date.AddDays(1).AddTicks(-1);

                // Gọi service để lấy danh sách báo cáo từ API (server-side paging/filter theo swagger v2)
                var apiData = await _reportsService.GetAllEventStatsAsync(
                    pageNumber: pageNumber,
                    pageSize: pageSize,
                    q: searchTerm,
                    status: status,
                    from: from,
                    to: to,
                    sortBy: sortBy,
                    sortDir: sortDir);

                if (apiData == null)
                {
                    _logger.LogWarning("Không thể lấy dữ liệu báo cáo từ API");
                    SetErrorMessage("Không thể tải danh sách báo cáo. Vui lòng thử lại sau.");
                    return View(new EventReportListViewModel());
                }

                var items = apiData.Items ?? new List<EventStatsListItemDto>();
                var mappedItems = items.Select(MapToListItemViewModel).ToList();

                // Map sang ViewModel
                var viewModel = new EventReportListViewModel
                {
                    EventReports = mappedItems,
                    PagedEventReports = mappedItems,
                    SearchTerm = searchTerm,
                    StartDate = startDate,
                    EndDate = endDate,
                    Status = status,
                    SortBy = sortBy,
                    SortDir = sortDir,
                    Summary = apiData.Summary,
                    Pagination = apiData.Pagination,
                    PageNumber = apiData.Pagination?.PageNumber ?? (pageNumber <= 0 ? 1 : pageNumber),
                    PageSize = apiData.Pagination?.PageSize ?? (pageSize <= 0 ? 10 : pageSize),
                    TotalPages = apiData.Pagination?.TotalPages ?? 1
                };

                _logger.LogInformation(
                    "Đã tải {Count} báo cáo sự kiện (page {PageNumber}/{TotalPages})",
                    items.Count,
                    viewModel.PageNumber,
                    viewModel.TotalPages);

                return View(viewModel);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải danh sách báo cáo");
                SetErrorMessage("Đã xảy ra lỗi khi tải danh sách báo cáo. Vui lòng thử lại sau.");
                return View(new EventReportListViewModel());
            }
        }

        /// <summary>
        /// GET: /Reports/Detail/{eventId}
        /// Hiển thị chi tiết báo cáo điểm danh của một sự kiện cụ thể
        /// 
        /// Data source: API GET /api/events/{eventId}/attendance-stats
        /// Database view: vw_EventAttendanceStats
        /// </summary>
        /// <param name="eventId">ID của sự kiện cần xem báo cáo</param>
        [HttpGet]
        public async Task<IActionResult> Detail(int eventId)
        {
            try
            {
                _logger.LogInformation(
                    "User {UserId} đang xem chi tiết báo cáo sự kiện {EventId}",
                    CurrentUserId, eventId);

                // Gọi service để lấy chi tiết báo cáo từ API
                var stats = await _reportsService.GetEventAttendanceStatsAsync(eventId);

                if (stats == null)
                {
                    _logger.LogWarning("Không tìm thấy sự kiện {EventId}", eventId);
                    SetErrorMessage("Không tìm thấy sự kiện. Sự kiện có thể đã bị xóa hoặc bạn không có quyền xem.");
                    return RedirectToAction(nameof(Index));
                }

                // Map sang ViewModel
                var viewModel = MapToDetailViewModel(stats);

                _logger.LogInformation(
                    "Đã tải báo cáo chi tiết cho sự kiện: {EventName} (ID: {EventId})",
                    viewModel.EventName, eventId);

                return View(viewModel);
            }
            catch (HttpRequestException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
            {
                _logger.LogWarning("Sự kiện {EventId} không tồn tại (404)", eventId);
                SetErrorMessage("Không tìm thấy sự kiện. Vui lòng kiểm tra lại.");
                return RedirectToAction(nameof(Index));
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải chi tiết báo cáo sự kiện {EventId}", eventId);
                SetErrorMessage("Đã xảy ra lỗi khi tải báo cáo. Vui lòng thử lại sau.");
                return RedirectToAction(nameof(Index));
            }
        }

        [HttpGet]
        public async Task<IActionResult> BiometricTelemetry(
            string? searchTerm,
            int? eventId,
            DateTime? from,
            DateTime? to,
            string? faceStatus,
            string? livenessStatus,
            bool onlyInvalid = false,
            int pageNumber = 1,
            int pageSize = 20)
        {
            try
            {
                var response = await _reportsService.GetBiometricTelemetryAsync(
                    pageNumber: pageNumber,
                    pageSize: pageSize,
                    q: searchTerm,
                    eventId: eventId,
                    from: from,
                    to: to,
                    faceStatus: faceStatus,
                    livenessStatus: livenessStatus,
                    onlyInvalid: onlyInvalid ? true : null);

                if (response == null)
                {
                    SetErrorMessage("Không thể tải biometric telemetry. Vui lòng thử lại sau.");
                    return View(new BiometricTelemetryPageViewModel());
                }

                var pagination = response.Telemetry ?? new BiometricTelemetryPaginatedResultDto();
                var viewModel = new BiometricTelemetryPageViewModel
                {
                    Items = pagination.Items ?? new List<BiometricTelemetryItemDto>(),
                    SearchTerm = searchTerm,
                    EventId = eventId,
                    From = from,
                    To = to,
                    FaceStatus = faceStatus,
                    LivenessStatus = livenessStatus,
                    OnlyInvalid = onlyInvalid,
                    PageNumber = pagination.PageNumber <= 0 ? pageNumber : pagination.PageNumber,
                    PageSize = pagination.PageSize <= 0 ? pageSize : pagination.PageSize,
                    TotalCount = pagination.TotalCount,
                    TotalPages = pagination.TotalPages <= 0 ? 1 : pagination.TotalPages
                };

                return View(viewModel);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải biometric telemetry");
                SetErrorMessage("Không thể tải biometric telemetry. Vui lòng thử lại sau.");
                return View(new BiometricTelemetryPageViewModel());
            }
        }

        [HttpGet]
        public async Task<IActionResult> ExportBiometricTelemetryCsv(
            string? searchTerm,
            int? eventId,
            DateTime? from,
            DateTime? to,
            string? faceStatus,
            string? livenessStatus,
            bool onlyInvalid = false)
        {
            try
            {
                var response = await _reportsService.GetBiometricTelemetryAsync(
                    pageNumber: 1,
                    pageSize: 1000,
                    q: searchTerm,
                    eventId: eventId,
                    from: from,
                    to: to,
                    faceStatus: faceStatus,
                    livenessStatus: livenessStatus,
                    onlyInvalid: onlyInvalid ? true : null);

                var items = response?.Telemetry?.Items ?? new List<BiometricTelemetryItemDto>();
                if (items.Count == 0)
                {
                    SetErrorMessage("Không có dữ liệu biometric telemetry để xuất CSV.");
                    return RedirectToAction(nameof(BiometricTelemetry), new
                    {
                        searchTerm,
                        eventId,
                        from,
                        to,
                        faceStatus,
                        livenessStatus,
                        onlyInvalid
                    });
                }

                var csv = new StringBuilder();
                csv.AppendLine("AttendanceID,CheckInTime,EventID,EventName,UserID,FullName,Code,IsValid,InvalidReason,FaceStatus,FaceConfidence,FaceReason,LivenessStatus,LivenessScore,LivenessReason,RiskLevel,RiskScore,SimilarityScore,Threshold,FaceProvider,FaceModel,FaceProcessingTimeMs,FaceErrorCode,FaceErrorMessage");

                foreach (var item in items)
                {
                    csv.AppendLine(string.Join(",",
                        Csv(item.AttendanceID),
                        Csv(item.CheckInTime?.ToString("yyyy-MM-dd HH:mm:ss")),
                        Csv(item.EventID),
                        Csv(item.EventName),
                        Csv(item.UserID),
                        Csv(item.FullName),
                        Csv(item.Code),
                        Csv(item.IsValid),
                        Csv(item.InvalidReason),
                        Csv(item.FaceVerificationStatus),
                        Csv(item.FaceConfidence?.ToString("0.000")),
                        Csv(item.FaceVerificationReason),
                        Csv(item.LivenessPassed == true ? "Passed" : item.LivenessPassed == false ? "Failed" : !string.IsNullOrWhiteSpace(item.LivenessReason) ? "Review" : "N/A"),
                        Csv(item.LivenessScore?.ToString("0.000")),
                        Csv(item.LivenessReason),
                        Csv(item.RiskLevel),
                        Csv(item.RiskScore),
                        Csv(item.SimilarityScore?.ToString("0.000")),
                        Csv(item.Threshold?.ToString("0.000")),
                        Csv(item.FaceProvider),
                        Csv(item.FaceModel),
                        Csv(item.FaceProcessingTimeMs),
                        Csv(item.FaceErrorCode),
                        Csv(item.FaceErrorMessage)));
                }

                var fileName = $"biometric-telemetry-{DateTime.Now:yyyyMMdd-HHmmss}.csv";
                return File(Encoding.UTF8.GetBytes(csv.ToString()), "text/csv; charset=utf-8", fileName);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi export biometric telemetry CSV");
                SetErrorMessage("Không thể xuất CSV biometric telemetry. Vui lòng thử lại sau.");
                return RedirectToAction(nameof(BiometricTelemetry), new
                {
                    searchTerm,
                    eventId,
                    from,
                    to,
                    faceStatus,
                    livenessStatus,
                    onlyInvalid
                });
            }
        }

        #region Private Helper Methods

        private static string Csv(object? value)
        {
            if (value == null)
            {
                return string.Empty;
            }

            var text = value.ToString() ?? string.Empty;
            return $"\"{text.Replace("\"", "\"\"")}\"";
        }

        /// <summary>
        /// Map DTO từ API sang ViewModel cho danh sách
        /// </summary>
        private EventReportListItemViewModel MapToListItemViewModel(EventStatsListItemDto dto)
        {
            return new EventReportListItemViewModel
            {
                EventId = dto.EventID,
                EventName = dto.EventName ?? "Chưa có tên",
                StartTime = dto.StartTime,
                Status = dto.Status ?? "Không xác định",
                MaxParticipants = dto.MaxParticipants,
                TotalRegistrations = dto.TotalRegistrations,
                ValidAttendances = dto.ValidAttendances,
                InvalidAttendances = dto.InvalidAttendances,
                AttendanceRate = dto.AttendanceRate,
                NotCheckedIn = dto.NotCheckedIn
            };
        }

        /// <summary>
        /// Map DTO từ API sang ViewModel cho chi tiết
        /// </summary>
        private EventAttendanceReportViewModel MapToDetailViewModel(EventAttendanceStatsDto dto)
        {
            return new EventAttendanceReportViewModel
            {
                EventId = dto.EventID,
                EventName = dto.EventName ?? "Chưa có tên",
                StartTime = dto.StartTime,
                MaxParticipants = dto.MaxParticipants,
                TotalRegistrations = dto.TotalRegistrations,
                ValidAttendances = dto.ValidAttendances,
                InvalidAttendances = dto.InvalidAttendances,
                TotalCheckIns = dto.TotalCheckIns,
                NotCheckedIn = dto.NotCheckedIn,
                AttendanceRate = dto.AttendanceRate
            };
        }

        #endregion
    }
}
