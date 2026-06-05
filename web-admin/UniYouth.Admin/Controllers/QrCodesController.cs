using Microsoft.AspNetCore.Mvc;
using QRCoder;
using UniYouth.Admin.Filters;
using UniYouth.Admin.Models.DTOs.QrCodes;
using UniYouth.Admin.Models.ViewModels.QrCodes;
using UniYouth.Admin.Services.QrCodes;

namespace UniYouth.Admin.Controllers
{
    /// <summary>
    /// Controller quản lý QR Codes cho sự kiện
    /// 
    /// CHỨC NĂNG:
    /// - Xem danh sách QR codes của sự kiện
    /// - Tạo QR code mới với thời gian hiệu lực
    /// - Vô hiệu hóa QR code (deactivate)
    /// 
    /// QR CODE LIFECYCLE TRONG WEB MANAGEMENT:
    /// 
    /// 1. GENERATION (Tạo mới):
    ///    - Admin chọn thời gian hiệu lực (ValidFrom - ValidUntil)
    ///    - Có thể set giới hạn số lần scan (ScanLimit)
    ///    - Backend tự động generate unique token
    ///    - QR code được lưu với trạng thái Active
    /// 
    /// 2. ACTIVE PERIOD (Đang hoạt động):
    ///    - QR code sẵn sàng để users scan
    ///    - Mobile app/attendance system sử dụng token để validate check-in
    ///    - CurrentScans được tự động tăng mỗi khi có scan thành công
    ///    - Admin có thể theo dõi số lượng scan real-time
    /// 
    /// 3. DEACTIVATION (Vô hiệu hóa):
    ///    - Admin có thể deactivate trước khi hết hạn
    ///    - Sử dụng khi: QR bị lộ, cần thay thế, hoặc sự kiện kết thúc sớm
    ///    - Sau khi deactivate, không thể scan được nữa
    ///    - Không thể reactivate - phải tạo QR mới
    /// 
    /// 4. EXPIRATION (Hết hạn):
    ///    - Tự động xảy ra khi qua thời gian ValidUntil
    ///    - QR không thể scan được nữa
    ///    - Vẫn giữ lại trong database để tracking
    /// 
    /// INTERACTION VỚI ATTENDANCE CHECK-IN:
    /// 
    /// - Admin Web (Controller này): Chỉ quản lý QR lifecycle
    /// - Mobile App/Web App: Scan QR và gửi token đến backend
    /// - Backend API: Validate token, check thời gian, tạo attendance record
    /// - Attendance System: Xử lý điểm danh, tính điểm, thông báo
    /// 
    /// Luồng check-in:
    /// 1. User scan QR bằng mobile app
    /// 2. App đọc QR token và gửi đến /api/attendance/checkin
    /// 3. Backend validate:
    ///    - QR có tồn tại không
    ///    - QR có active không
    ///    - Thời gian có hợp lệ không (ValidFrom <= now <= ValidUntil)
    ///    - Đã đạt ScanLimit chưa
    ///    - User có ở đúng vị trí không (GPS)
    /// 4. Nếu valid: Tạo attendance record, tăng CurrentScans
    /// 5. Nếu invalid: Trả về lỗi với lý do cụ thể
    /// 
    /// Admin web KHÔNG trực tiếp xử lý scanning - chỉ quản lý QR codes
    /// </summary>
    [ServiceFilter(typeof(AdminAuthorizeFilter))]
    public class QrCodesController : BaseController
    {
        private readonly IQrCodesApiService _qrCodesService;
        private readonly ILogger<QrCodesController> _logger;

        public QrCodesController(
            IQrCodesApiService qrCodesService,
            ILogger<QrCodesController> logger)
        {
            _qrCodesService = qrCodesService;
            _logger = logger;
        }

        /// <summary>
        /// Hiển thị danh sách QR codes của sự kiện
        /// GET: /QrCodes/Index/{eventId}
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Index(
            int eventId,
            int pageNumber = 1,
            int pageSize = 10,
            bool? isActive = null,
            bool? validNow = null)
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
                var eventResult = await _qrCodesService.GetEventDetailAsync(eventId);
                if (!eventResult.Success || eventResult.Data == null)
                {
                    SetErrorMessage(eventResult.ErrorMessage ?? "Không tìm thấy sự kiện.");
                    return RedirectToAction("Index", "Events");
                }

                // Lấy danh sách QR codes
                var qrCodesResult = await _qrCodesService.GetEventQrCodesAsync(
                    eventId: eventId,
                    pageNumber: pageNumber,
                    pageSize: pageSize,
                    isActive: isActive,
                    validNow: validNow);
                if (!qrCodesResult.Success)
                {
                    SetErrorMessage(qrCodesResult.ErrorMessage ?? "Không thể tải danh sách QR codes.");
                }

                // Tạo ViewModel
                var viewModel = new QrCodeListViewModel
                {
                    EventId = eventId,
                    EventName = eventResult.Data.EventName ?? "Sự kiện không xác định",
                    Pagination = qrCodesResult.Success ? qrCodesResult.Data : null,
                    IsActive = isActive,
                    ValidNow = validNow,
                    PageNumber = qrCodesResult.Data?.PageNumber ?? (pageNumber <= 0 ? 1 : pageNumber),
                    PageSize = qrCodesResult.Data?.PageSize ?? (pageSize <= 0 ? 10 : pageSize),
                    TotalPages = qrCodesResult.Data?.TotalPages ?? 1,
                    QrCodes = qrCodesResult.Success && qrCodesResult.Data?.Items != null
                        ? qrCodesResult.Data.Items.Select(MapToViewModel).ToList()
                        : new List<QrCodeViewModel>(),
                    GenerateForm = new GenerateQrCodeViewModel
                    {
                        ValidFrom = DateTime.Now,
                        ValidUntil = DateTime.Now.AddHours(2)
                    }
                };

                // Log thông tin
                _logger.LogInformation(
                    "User {UserId} đang xem QR codes của sự kiện {EventId}",
                    CurrentUserId,
                    eventId);

                return View(viewModel);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải trang quản lý QR codes cho sự kiện {EventId}", eventId);
                SetErrorMessage("Đã xảy ra lỗi khi tải trang. Vui lòng thử lại.");
                return RedirectToAction("Index", "Events");
            }
        }

        /// <summary>
        /// Tạo QR code mới cho sự kiện
        /// POST: /QrCodes/Generate
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Generate(
            int eventId,
            [Bind(Prefix = "GenerateForm")] GenerateQrCodeViewModel model)
        {
            try
            {
                // Validate eventId
                if (eventId <= 0)
                {
                    ModelState.AddModelError("", "ID sự kiện không hợp lệ.");
                    SetErrorMessage("ID sự kiện không hợp lệ.");
                    return await ReturnIndexWithModelErrorsAsync(eventId, model);
                }

                // Validate model state
                if (!ModelState.IsValid)
                {
                    SetErrorMessage("Dữ liệu không hợp lệ. Vui lòng kiểm tra lại thông tin.");
                    return await ReturnIndexWithModelErrorsAsync(eventId, model);
                }

                if (!model.ValidFrom.HasValue)
                {
                    const string message = "Vui lòng chọn thời gian bắt đầu";
                    ModelState.AddModelError("GenerateForm.ValidFrom", message);
                    SetErrorMessage(message);
                    return await ReturnIndexWithModelErrorsAsync(eventId, model);
                }

                if (!model.ValidUntil.HasValue)
                {
                    const string message = "Vui lòng chọn thời gian kết thúc";
                    ModelState.AddModelError("GenerateForm.ValidUntil", message);
                    SetErrorMessage(message);
                    return await ReturnIndexWithModelErrorsAsync(eventId, model);
                }

                var validFrom = model.ValidFrom.Value;
                var validUntil = model.ValidUntil.Value;

                // Validate ValidFrom < ValidUntil
                if (validFrom >= validUntil)
                {
                    const string message = "Thời gian bắt đầu phải trước thời gian kết thúc.";
                    ModelState.AddModelError(
                        "GenerateForm.ValidUntil",
                        message);
                    SetErrorMessage(message);
                    return await ReturnIndexWithModelErrorsAsync(eventId, model);
                }

                // Tạo DTO request
                var request = new GenerateEventQrRequestDto
                {
                    ValidFrom = validFrom,
                    ValidUntil = validUntil,
                    ScanLimit = model.ScanLimit
                };

                // Gọi service để tạo QR
                var result = await _qrCodesService.GenerateQrCodeAsync(eventId, request);

                if (result.Success && result.Data != null)
                {
                    SetSuccessMessage(
                        $"Đã tạo QR code thành công! QR sẽ hiệu lực từ {validFrom:dd/MM/yyyy HH:mm} đến {validUntil:dd/MM/yyyy HH:mm}.");

                    _logger.LogInformation(
                        "User {UserId} đã tạo QR code {QrId} cho sự kiện {EventId}",
                        CurrentUserId,
                        result.Data.Qrid,
                        eventId);

                    // Lưu QR vừa tạo vào TempData để hiển thị full token
                    TempData["NewQrToken"] = result.Data.QrToken;
                    TempData["NewQrId"] = result.Data.Qrid;
                }
                else
                {
                    SetErrorMessage(result.ErrorMessage ?? "Không thể tạo QR code. Vui lòng thử lại.");
                }

                return RedirectToAction(nameof(Index), new { eventId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tạo QR code cho sự kiện {EventId}", eventId);
                SetErrorMessage("Đã xảy ra lỗi khi tạo QR code. Vui lòng thử lại.");
                return RedirectToAction(nameof(Index), new { eventId });
            }
        }

        private async Task<IActionResult> ReturnIndexWithModelErrorsAsync(
            int eventId,
            GenerateQrCodeViewModel form)
        {
            // Reload page data so the Index view can render again with field-level messages
            var eventResult = await _qrCodesService.GetEventDetailAsync(eventId);
            if (!eventResult.Success || eventResult.Data == null)
            {
                SetErrorMessage(eventResult.ErrorMessage ?? "Không tìm thấy sự kiện.");
                return RedirectToAction("Index", "Events");
            }

            var qrCodesResult = await _qrCodesService.GetEventQrCodesAsync(
                eventId: eventId,
                pageNumber: 1,
                pageSize: 10,
                isActive: null,
                validNow: null);
            if (!qrCodesResult.Success)
            {
                SetErrorMessage(qrCodesResult.ErrorMessage ?? "Không thể tải danh sách QR codes.");
            }

            var viewModel = new QrCodeListViewModel
            {
                EventId = eventId,
                EventName = eventResult.Data.EventName ?? "Sự kiện không xác định",
                Pagination = qrCodesResult.Success ? qrCodesResult.Data : null,
                PageNumber = qrCodesResult.Data?.PageNumber ?? 1,
                PageSize = qrCodesResult.Data?.PageSize ?? 10,
                TotalPages = qrCodesResult.Data?.TotalPages ?? 1,
                QrCodes = qrCodesResult.Success && qrCodesResult.Data?.Items != null
                    ? qrCodesResult.Data.Items.Select(MapToViewModel).ToList()
                    : new List<QrCodeViewModel>(),
                GenerateForm = form
            };

            return View("Index", viewModel);
        }

        /// <summary>
        /// Vô hiệu hóa QR code
        /// POST: /QrCodes/Deactivate
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Deactivate(int eventId, int qrId)
        {
            try
            {
                // Validate
                if (eventId <= 0 || qrId <= 0)
                {
                    SetErrorMessage("Thông tin không hợp lệ.");
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                // Gọi service để deactivate
                var result = await _qrCodesService.DeactivateQrCodeAsync(qrId);

                if (result.Success)
                {
                    SetSuccessMessage("Đã vô hiệu hóa QR code thành công.");

                    _logger.LogInformation(
                        "User {UserId} đã deactivate QR code {QrId} của sự kiện {EventId}",
                        CurrentUserId,
                        qrId,
                        eventId);
                }
                else
                {
                    SetErrorMessage(result.ErrorMessage ?? "Không thể vô hiệu hóa QR code.");
                }

                return RedirectToAction(nameof(Index), new { eventId });
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Lỗi khi deactivate QR code {QrId} của sự kiện {EventId}",
                    qrId,
                    eventId);
                SetErrorMessage("Đã xảy ra lỗi khi vô hiệu hóa QR code. Vui lòng thử lại.");
                return RedirectToAction(nameof(Index), new { eventId });
            }
        }

        /// <summary>
        /// Xem chi tiết QR code (AJAX)
        /// GET: /QrCodes/Detail?qrId=...
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Detail(int qrId)
        {
            try
            {
                if (qrId <= 0)
                {
                    return BadRequest(new { success = false, message = "ID QR code không hợp lệ." });
                }

                var result = await _qrCodesService.GetQrCodeDetailAsync(qrId);
                if (!result.Success || result.Data == null)
                {
                    return NotFound(new { success = false, message = result.ErrorMessage ?? "Không tìm thấy QR code." });
                }

                string? qrImageDataUrl = null;
                if (!string.IsNullOrWhiteSpace(result.Data.QrToken))
                {
                    using var generator = new QRCodeGenerator();
                    using var qrCodeData = generator.CreateQrCode(result.Data.QrToken, QRCodeGenerator.ECCLevel.Q);
                    var png = new PngByteQRCode(qrCodeData);
                    var bytes = png.GetGraphic(20);
                    qrImageDataUrl = $"data:image/png;base64,{Convert.ToBase64String(bytes)}";
                }

                return Ok(new
                {
                    success = true,
                    data = new
                    {
                        qrId = result.Data.QrId,
                        eventId = result.Data.EventId,
                        eventName = result.Data.EventName,
                        isActive = result.Data.IsActive,
                        validFrom = result.Data.ValidFrom,
                        validUntil = result.Data.ValidUntil,
                        scanLimit = result.Data.ScanLimit,
                        currentScans = result.Data.CurrentScans,
                        createdByName = result.Data.CreatedBy?.FullName,
                        createdDate = result.Data.CreatedDate,
                        isExpired = result.Data.IsExpired,
                        isOverScanLimit = result.Data.IsOverScanLimit,
                        qrImageDataUrl
                    }
                });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy chi tiết QR code {QrId}", qrId);
                return StatusCode(500, new { success = false, message = "Đã xảy ra lỗi khi tải chi tiết QR code." });
            }
        }

        #region Helper Methods

        /// <summary>
        /// Ánh xạ DTO sang ViewModel
        /// </summary>
        private static QrCodeViewModel MapToViewModel(EventQrListItemDto dto)
        {
            return new QrCodeViewModel
            {
                QrId = dto.Qrid,
                EventId = dto.EventID,
                QrTokenPreview = dto.QrTokenPreview ?? string.Empty,
                ValidFrom = dto.ValidFrom,
                ValidUntil = dto.ValidUntil,
                IsActive = dto.IsActive ?? false,
                ScanLimit = dto.ScanLimit,
                CurrentScans = dto.CurrentScans ?? 0,
                Status = dto.Status ?? "Unknown",
                CreatedByName = dto.CreatedByName,
                CreatedDate = dto.CreatedDate
            };
        }

        #endregion
    }
}
