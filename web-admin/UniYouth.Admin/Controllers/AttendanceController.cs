using Microsoft.AspNetCore.Mvc;
using UniYouth.Admin.Filters;
using UniYouth.Admin.Models.DTOs.Attendance;
using UniYouth.Admin.Models.ViewModels.Attendance;
using UniYouth.Admin.Services.Attendance;

namespace UniYouth.Admin.Controllers
{
    /// <summary>
    /// Controller quản lý xem Đăng ký & Điểm danh sự kiện
    /// 
    /// CHỨC NĂNG:
    /// - Xem danh sách người đăng ký sự kiện
    /// - Xem danh sách điểm danh (check-in records)
    /// - Xem thống kê điểm danh
    /// 
    /// ⚠️ READ-ONLY CONTROLLER - KHÔNG CHO PHÉP SỬA/XÓA
    /// 
    /// LÝ DO READ-ONLY:
    /// 
    /// 1. Dữ liệu đã được validated khi tạo:
    ///    - Registration: User tự đăng ký qua app/web
    ///    - Attendance: User tự check-in qua QR/GPS
    ///    - Mỗi record có timestamp, GPS, IP address
    /// 
    /// 2. Tính toàn vẹn dữ liệu (Data Integrity):
    ///    - Sửa/xóa sẽ làm mất audit trail
    ///    - Cần đảm bảo không ai can thiệp vào dữ liệu gốc
    ///    - Dùng cho báo cáo và thống kê chính xác
    /// 
    /// 3. Trách nhiệm (Accountability):
    ///    - Mỗi attendance record là "proof" điểm danh
    ///    - Không thể thay đổi sau khi đã tạo
    ///    - Nếu có sai sót → quy trình appeal riêng
    /// 
    /// 4. Phát hiện gian lận (Fraud Detection):
    ///    - Admin cần XEM dữ liệu nguyên gốc để phát hiện:
    ///      + Check-in từ xa (distance > allowRadius)
    ///      + Check-in ngoài giờ
    ///      + Duplicate check-ins
    ///    - Sửa đổi sẽ che giấu gian lận
    /// 
    /// CÁCH HIỂN THỊ ATTENDANCE VALIDITY:
    /// 
    /// Valid Attendance:
    /// - Background: Light green (table-success)
    /// - Badge: Green "Hợp lệ" với icon check-circle
    /// - Distance hiển thị rõ ràng
    /// - Có thể tính điểm, cấp certificate
    /// 
    /// Invalid Attendance:
    /// - Background: Light red (table-danger)
    /// - Badge: Red "Không hợp lệ" với icon x-circle
    /// - InvalidReason hiển thị trong tooltip hoặc text nhỏ
    /// - Ví dụ: "Vượt quá khoảng cách 500m", "Ngoài thời gian sự kiện"
    /// - KHÔNG tính điểm
    /// 
    /// Controller này CHỈ HIỂN THỊ dữ liệu, KHÔNG XỬ LÝ business logic
    /// </summary>
    [ServiceFilter(typeof(AdminAuthorizeFilter))]
    public class AttendanceController : BaseController
    {
        private readonly IAttendanceApiService _attendanceService;
        private readonly ILogger<AttendanceController> _logger;

        public AttendanceController(
            IAttendanceApiService attendanceService,
            ILogger<AttendanceController> logger)
        {
            _attendanceService = attendanceService;
            _logger = logger;
        }

        /// <summary>
        /// Hiển thị danh sách điểm danh của sự kiện
        /// GET: /Attendance/Attendances/{eventId}
        /// 
        /// Hiển thị:
        /// - Tất cả check-in records (valid và invalid)
        /// - Highlight: Valid = xanh, Invalid = đỏ
        /// - Thông tin GPS: Distance, coordinates
        /// - InvalidReason cho các attendance không hợp lệ
        /// - Thống kê tổng quan
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Index(
            int eventId,
            int pageNumber = 1,
            int pageSize = 10,
            string? q = null,
            bool? isValid = null,
            string? method = null,
            bool? faceVerified = null,
            string? riskLevel = null,
            DateTime? from = null,
            DateTime? to = null,
            string? sortBy = null,
            string? sortDir = null)
        {
            try
            {
                // Kiểm tra eventId hợp lệ
                if (eventId <= 0)
                {
                    SetErrorMessage("ID sự kiện không hợp lệ.");
                    return RedirectToAction("Index", "Events");
                }

                // Lấy thông tin sự kiện
                var eventResult = await _attendanceService.GetEventDetailAsync(eventId);
                if (!eventResult.Success || eventResult.Data == null)
                {
                    SetErrorMessage(eventResult.ErrorMessage ?? "Không tìm thấy sự kiện.");
                    return RedirectToAction("Index", "Events");
                }

                // Lấy danh sách điểm danh
                var attendancesResult = await _attendanceService.GetEventAttendancesAsync(
                    eventId: eventId,
                    pageNumber: pageNumber,
                    pageSize: pageSize,
                    q: q,
                    isValid: isValid,
                    method: method,
                    faceVerified: faceVerified,
                    faceVerificationStatus: null,
                    riskLevel: riskLevel,
                    suspiciousOnly: null,
                    from: from,
                    to: to,
                    sortBy: sortBy,
                    sortDir: sortDir);
                if (!attendancesResult.Success)
                {
                    SetErrorMessage(attendancesResult.ErrorMessage ?? "Không thể tải danh sách điểm danh.");
                }

                // Lấy thống kê (nếu có)
                var statsResult = await _attendanceService.GetAttendanceStatsAsync(eventId);

                // Tạo ViewModel
                var viewModel = new EventAttendanceListViewModel
                {
                    EventId = eventId,
                    EventName = eventResult.Data.EventName ?? "Sự kiện không xác định",
                    Summary = attendancesResult.Success ? attendancesResult.Data?.Summary : null,
                    Pagination = attendancesResult.Success ? attendancesResult.Data?.Attendances : null,
                    Q = q,
                    IsValid = isValid,
                    Method = method,
                    FaceVerified = faceVerified,
                    RiskLevel = riskLevel,
                    From = from,
                    To = to,
                    SortBy = sortBy,
                    SortDir = sortDir,
                    PageNumber = attendancesResult.Data?.Attendances?.PageNumber ?? (pageNumber <= 0 ? 1 : pageNumber),
                    PageSize = attendancesResult.Data?.Attendances?.PageSize ?? (pageSize <= 0 ? 10 : pageSize),
                    TotalPages = attendancesResult.Data?.Attendances?.TotalPages ?? 1,
                    Attendances = attendancesResult.Success && attendancesResult.Data?.Attendances?.Items != null
                        ? attendancesResult.Data.Attendances.Items.Select(MapToAttendanceViewModel).ToList()
                        : new List<EventAttendanceViewModel>(),
                    Statistics = statsResult.Success && statsResult.Data != null
                        ? MapToStatsViewModel(statsResult.Data)
                        : null
                };

                // Log thông tin
                _logger.LogInformation(
                    "User {UserId} đang xem danh sách điểm danh của sự kiện {EventId}. " +
                    "Total: {Total}, Valid: {Valid}, Invalid: {Invalid}",
                    CurrentUserId,
                    eventId,
                    viewModel.TotalAttendances,
                    viewModel.ValidAttendances,
                    viewModel.InvalidAttendances);

                return View(viewModel);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải trang danh sách điểm danh cho sự kiện {EventId}", eventId);
                SetErrorMessage("Đã xảy ra lỗi khi tải trang. Vui lòng thử lại.");
                return RedirectToAction("Index", "Events");
            }
        }

        #region Helper Methods

        /// <summary>
        /// Ánh xạ DTO điểm danh sang ViewModel
        /// </summary>
        private static EventAttendanceViewModel MapToAttendanceViewModel(AttendanceDetailDto dto)
        {
            return new EventAttendanceViewModel
            {
                AttendanceID = dto.AttendanceID,
                UserID = dto.UserID,
                Code = dto.Code ?? string.Empty,
                FullName = dto.FullName ?? string.Empty,
                Email = dto.Email ?? string.Empty,
                CheckInTime = dto.CheckInTime ?? DateTime.MinValue,
                CheckInMethod = dto.CheckInMethod ?? "Unknown",
                IsValid = dto.IsValid ?? false,
                InvalidReason = dto.InvalidReason,
                Distance = dto.Distance,
                UserLatitude = dto.UserLatitude,
                UserLongitude = dto.UserLongitude,
                IpAddress = dto.IpAddress,
                DeviceInfo = dto.DeviceInfo,
                ClientDeviceId = dto.ClientDeviceId,
                FaceVerified = dto.FaceVerified,
                FaceConfidence = dto.FaceConfidence,
                FaceVerificationStatus = dto.FaceVerificationStatus,
                FaceVerificationProvider = dto.FaceVerificationProvider,
                FaceVerificationVersion = dto.FaceVerificationVersion,
                FaceVerificationReason = dto.FaceVerificationReason,
                RiskScore = dto.RiskScore,
                RiskLevel = dto.RiskLevel,
                RiskReasons = dto.RiskReasons ?? new List<string>()
            };
        }

        /// <summary>
        /// Ánh xạ DTO thống kê sang ViewModel
        /// </summary>
        private static EventAttendanceStatsViewModel MapToStatsViewModel(EventAttendanceStatsDto dto)
        {
            return new EventAttendanceStatsViewModel
            {
                EventID = dto.EventID,
                EventName = dto.EventName ?? string.Empty,
                StartTime = dto.StartTime,
                MaxParticipants = dto.MaxParticipants,
                TotalRegistrations = dto.TotalRegistrations,
                ValidAttendances = dto.ValidAttendances,
                InvalidAttendances = dto.InvalidAttendances,
                AttendanceRate = dto.AttendanceRate,
                TotalCheckIns = dto.TotalCheckIns,
                NotCheckedIn = dto.NotCheckedIn
            };
        }

        #endregion
    }
}

