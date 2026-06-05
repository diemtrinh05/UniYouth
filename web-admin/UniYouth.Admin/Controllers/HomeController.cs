using Microsoft.AspNetCore.Mvc;
using System.Globalization;
using UniYouth.Admin.Models.ViewModels.Home;
using UniYouth.Admin.Services.Events;
using UniYouth.Admin.Services.QrCodes;
using UniYouth.Admin.Services.Stats;

namespace UniYouth.Admin.Controllers
{
    /// <summary>
    /// Home Controller - Trang chủ sau khi đăng nhập
    /// Kế thừa BaseController để có quyền truy cập CurrentUser và các helper methods
    /// </summary>
    public class HomeController : BaseController
    {
        private readonly ILogger<HomeController> _logger;
        private readonly IEventApiService _eventApi;
        private readonly IStatsApiService _statsApi;
        private readonly IQrCodesApiService _qrCodesApi;

        public HomeController(
            ILogger<HomeController> logger,
            IEventApiService eventApi,
            IStatsApiService statsApi,
            IQrCodesApiService qrCodesApi)
        {
            _logger = logger;
            _eventApi = eventApi;
            _statsApi = statsApi;
            _qrCodesApi = qrCodesApi;
        }

        /// <summary>
        /// GET: /Home/Index
        /// Trang chủ chính
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Index()
        {
            _logger.LogInformation(
                "User {FullName} (ID: {UserId}, Role: {Role}) đang truy cập Home",
                CurrentUserFullName,
                CurrentUserId,
                CurrentUserRole);

            var vm = new HomeOverviewViewModel { Greeting = GetGreeting(DateTime.Now) };

            try
            {
                // Counters (best-effort)
                var totalResp = await _eventApi.GetEventsAsync(pageNumber: 1, pageSize: 1);
                vm.TotalEvents = totalResp?.TotalCount ?? 0;

                var ongoingResp = await _eventApi.GetEventsAsync(pageNumber: 1, pageSize: 1, status: 2);
                vm.OngoingEvents = ongoingResp?.TotalCount ?? 0;

                var draftResp = await _eventApi.GetEventsAsync(pageNumber: 1, pageSize: 1, status: 0);
                vm.DraftEvents = draftResp?.TotalCount ?? 0;

                // Attendance stats
                var stats = await _statsApi.GetAllEventsStatsAsync();
                if (stats != null && stats.Any())
                {
                    var totalRegistrations = stats.Sum(s => s.TotalRegistrations);
                    vm.TotalValidAttendances = stats.Sum(s => s.ValidAttendances);
                    vm.AttendanceRatePercent = totalRegistrations > 0
                        ? (int)Math.Round(vm.TotalValidAttendances * 100.0 / totalRegistrations)
                        : 0;
                    vm.AttendanceRatePercent = Math.Clamp(vm.AttendanceRatePercent, 0, 100);
                    vm.ChartDataByPeriod = BuildChartData(stats);
                }

                // Ongoing events that occur today (best-effort from first page)
                var today = DateTime.Today;
                var todayEndExclusive = today.AddDays(1);
                var ongoingList = await _eventApi.GetEventsAsync(pageNumber: 1, pageSize: 50, status: 2);
                vm.TodayOngoingEvents = ongoingList?.Items?.Count(e =>
                    e.StartTime < todayEndExclusive && e.EndTime >= today) ?? 0;

                // Recent events
                var recentResp = await _eventApi.GetEventsAsync(pageNumber: 1, pageSize: 10);
                if (recentResp?.Items != null)
                {
                    vm.RecentEvents = recentResp.Items
                        .OrderByDescending(e => e.StartTime)
                        .Select(e => new HomeRecentEventViewModel
                        {
                            EventId = e.EventId,
                            EventName = e.EventName,
                            ThumbnailUrl = e.ThumbnailUrl,
                            LocationName = e.LocationName,
                            StartTime = e.StartTime,
                            EndTime = e.EndTime,
                            Status = MapEventStatus(e.Status),
                            StatusName = e.StatusName,
                            CurrentParticipants = e.CurrentParticipants ?? 0,
                            MaxParticipants = e.MaxParticipants
                        })
                        .ToList();
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading home data");
                vm.HasError = true;
                vm.ErrorMessage = "Không thể tải dữ liệu trang chủ. Vui lòng thử lại sau.";
                SetErrorMessage(vm.ErrorMessage);
            }

            return View(vm);
        }

        /// <summary>
        /// GET: /Home/Error
        /// Trang hiển thị lỗi chung
        /// </summary>
        [ResponseCache(Duration = 0, Location = ResponseCacheLocation.None, NoStore = true)]
        public IActionResult Error()
        {
            return View();
        }

        [HttpGet]
        public async Task<IActionResult> EventQrPreview(int eventId)
        {
            if (eventId <= 0)
            {
                return BadRequest(new { success = false, message = "ID sự kiện không hợp lệ." });
            }

            try
            {
                var validNowResult = await _qrCodesApi.GetEventQrCodesAsync(
                    eventId: eventId,
                    pageNumber: 1,
                    pageSize: 10,
                    isActive: true,
                    validNow: true);

                var activeQr = validNowResult.Success
                    ? validNowResult.Data?.Items?.FirstOrDefault()
                    : null;

                if (activeQr != null)
                {
                    var detail = await _qrCodesApi.GetQrCodeDetailAsync(activeQr.Qrid);
                    if (!detail.Success || detail.Data == null)
                    {
                        return NotFound(new
                        {
                            success = false,
                            message = detail.ErrorMessage ?? "Không thể tải chi tiết QR code."
                        });
                    }

                    string? qrImageDataUrl = null;
                    if (!string.IsNullOrWhiteSpace(detail.Data.QrToken))
                    {
                        using var generator = new QRCoder.QRCodeGenerator();
                        using var qrCodeData = generator.CreateQrCode(
                            detail.Data.QrToken,
                            QRCoder.QRCodeGenerator.ECCLevel.Q);
                        var png = new QRCoder.PngByteQRCode(qrCodeData);
                        var bytes = png.GetGraphic(20);
                        qrImageDataUrl = $"data:image/png;base64,{Convert.ToBase64String(bytes)}";
                    }

                    return Ok(new
                    {
                        success = true,
                        data = new
                        {
                            qrId = detail.Data.QrId,
                            eventId = detail.Data.EventId,
                            eventName = detail.Data.EventName,
                            validFrom = detail.Data.ValidFrom,
                            validUntil = detail.Data.ValidUntil,
                            currentScans = detail.Data.CurrentScans,
                            scanLimit = detail.Data.ScanLimit,
                            isExpired = detail.Data.IsExpired,
                            isOverScanLimit = detail.Data.IsOverScanLimit,
                            qrImageDataUrl
                        }
                    });
                }

                var fallbackResult = await _qrCodesApi.GetEventQrCodesAsync(
                    eventId: eventId,
                    pageNumber: 1,
                    pageSize: 20,
                    isActive: null,
                    validNow: null);

                var latestQr = fallbackResult.Success
                    ? fallbackResult.Data?.Items?
                        .OrderByDescending(item => item.CreatedDate ?? item.ValidUntil)
                        .FirstOrDefault()
                    : null;

                if (latestQr == null)
                {
                    return Ok(new
                    {
                        success = false,
                        message = "Sự kiện này chưa có mã QR."
                    });
                }

                var latestStatus = latestQr.Status?.Trim().ToLowerInvariant() ?? string.Empty;
                var now = DateTime.Now;

                var message =
                    latestQr.ValidUntil < now || latestStatus.Contains("expired")
                        ? "Mã QR của sự kiện này đã hết hiệu lực."
                        : latestQr.IsActive == false || latestStatus.Contains("deactivated")
                        ? "Mã QR của sự kiện này đã bị vô hiệu hóa."
                        : "Hiện chưa có mã QR còn hiệu lực cho sự kiện này.";

                return Ok(new
                {
                    success = false,
                    message,
                    data = new
                    {
                        eventId,
                        qrId = latestQr.Qrid,
                        validFrom = latestQr.ValidFrom,
                        validUntil = latestQr.ValidUntil,
                        status = latestQr.Status
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading QR preview for event {EventId}", eventId);
                return StatusCode(500, new
                {
                    success = false,
                    message = "Không thể tải QR code của sự kiện."
                });
            }
        }

        /// <summary>
        /// Ví dụ: Action chỉ dành cho Admin
        /// Sử dụng RequireAdmin() helper từ BaseController
        /// </summary>
        public IActionResult AdminOnlyPage()
        {
            var accessDenied = RequireAdmin();
            if (accessDenied != null)
                return accessDenied;

            _logger.LogInformation("Admin {FullName} đang truy cập trang Admin-only", CurrentUserFullName);

            return View();
        }

        private static string MapEventStatus(int status)
        {
            return status switch
            {
                0 => "Draft",
                1 => "Open",
                2 => "Ongoing",
                3 => "Closed",
                4 => "Cancelled",
                _ => "Unknown"
            };
        }

        private static Dictionary<string, HomeChartSeriesViewModel> BuildChartData(
            IReadOnlyCollection<UniYouth.Admin.Models.DTOs.Stats.EventStatsListItem> stats)
        {
            var currentYear = DateTime.Today.Year;
            var today = DateTime.Today;

            var weeklyDates = Enumerable.Range(0, 7)
                .Select(offset => today.AddDays(offset - 6))
                .ToList();
            var weeklyLabels = weeklyDates
                .Select(date => date.ToString("dd/MM", CultureInfo.InvariantCulture))
                .ToList();
            var weeklyEvents = weeklyDates
                .Select(date => stats.Count(x => x.StartTime.Date == date))
                .ToList();
            var weeklyAttendances = weeklyDates
                .Select(date => stats.Where(x => x.StartTime.Date == date).Sum(x => x.ValidAttendances))
                .ToList();

            var monthlyLabels = Enumerable.Range(1, 12)
                .Select(month => $"T{month}")
                .ToList();
            var monthlyEvents = Enumerable.Repeat(0, 12).ToArray();
            var monthlyAttendances = Enumerable.Repeat(0, 12).ToArray();

            foreach (var item in stats.Where(x => x.StartTime.Year == currentYear))
            {
                var monthIndex = item.StartTime.Month - 1;
                monthlyEvents[monthIndex] += 1;
                monthlyAttendances[monthIndex] += item.ValidAttendances;
            }

            var quarterlyLabels = new List<string> { "Q1", "Q2", "Q3", "Q4" };
            var quarterlyEvents = new[] { 0, 0, 0, 0 };
            var quarterlyAttendances = new[] { 0, 0, 0, 0 };

            foreach (var item in stats.Where(x => x.StartTime.Year == currentYear))
            {
                var quarterIndex = (item.StartTime.Month - 1) / 3;
                quarterlyEvents[quarterIndex] += 1;
                quarterlyAttendances[quarterIndex] += item.ValidAttendances;
            }

            return new Dictionary<string, HomeChartSeriesViewModel>(StringComparer.OrdinalIgnoreCase)
            {
                ["week"] = new HomeChartSeriesViewModel
                {
                    Labels = weeklyLabels,
                    EventCounts = weeklyEvents,
                    ValidAttendanceCounts = weeklyAttendances
                },
                ["month"] = new HomeChartSeriesViewModel
                {
                    Labels = monthlyLabels,
                    EventCounts = monthlyEvents.ToList(),
                    ValidAttendanceCounts = monthlyAttendances.ToList()
                },
                ["quarter"] = new HomeChartSeriesViewModel
                {
                    Labels = quarterlyLabels,
                    EventCounts = quarterlyEvents.ToList(),
                    ValidAttendanceCounts = quarterlyAttendances.ToList()
                }
            };
        }

        private static string GetGreeting(DateTime now)
        {
            var hour = now.Hour;

            if (hour < 11) return "Chào buổi sáng";
            if (hour < 14) return "Chào buổi trưa";
            if (hour < 18) return "Chào buổi chiều";
            return "Chào buổi tối";
        }


    }
}

