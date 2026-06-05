using Microsoft.AspNetCore.Mvc;
using UniYouth.Admin.Filters;
using UniYouth.Admin.Models.DTOs.Registration;
using UniYouth.Admin.Models.ViewModels.Registration;
using UniYouth.Admin.Services.Registration;

namespace UniYouth.Admin.Controllers
{
    [ServiceFilter(typeof(AdminAuthorizeFilter))]
    public class RegistrationController : BaseController
    {
        private readonly IRegistrationApiService _registrationService;
        private readonly ILogger<RegistrationController> _logger;

        public RegistrationController(
            IRegistrationApiService registrationService,
            ILogger<RegistrationController> logger)
        {
            _registrationService = registrationService;
            _logger = logger;
        }

        /// <summary>
        /// Hiển thị danh sách người đăng ký sự kiện
        /// GET: /Attendance/Registrations/{eventId}
        /// 
        /// Hiển thị:
        /// - Tất cả người đã đăng ký (bao gồm cả cancelled)
        /// - Thời gian đăng ký
        /// - Trạng thái (Registered / Cancelled)
        /// - Lý do hủy (nếu có)
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Index(
            int eventId,
            int? status,
            int pageNumber = 1,
            int pageSize = 20,
            string? q = null)
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
                var eventResult = await _registrationService.GetEventDetailAsync(eventId);
                if (!eventResult.Success || eventResult.Data == null)
                {
                    SetErrorMessage(eventResult.ErrorMessage ?? "Không tìm thấy sự kiện.");
                    return RedirectToAction("Index", "Events");
                }

                // Lấy danh sách đăng ký
                var registrationsResult = await _registrationService.GetEventRegistrationsAsync(
                    eventId,
                    status,
                    pageNumber,
                    pageSize);

                // Tạo ViewModel
                var viewModel = new EventRegistrationListViewModel
                {
                    EventId = eventId,
                    EventName = registrationsResult.Success && registrationsResult.Data != null && !string.IsNullOrWhiteSpace(registrationsResult.Data.EventName)
                        ? registrationsResult.Data.EventName!
                        : (eventResult.Data.EventName ?? "Sự kiện không xác định"),
                    TotalFromApi = registrationsResult.Success && registrationsResult.Data != null
                        ? registrationsResult.Data.Total
                        : null,
                    Registrations = registrationsResult.Success && registrationsResult.Data?.Items != null
                        ? registrationsResult.Data.Items.Select(MapToRegistrationViewModel).ToList()
                        : new List<EventRegistrationViewModel>(),
                    PageNumber = pageNumber < 1 ? 1 : pageNumber,
                    PageSize = pageSize < 1 ? 20 : pageSize,
                    Status = status,
                    Query = string.IsNullOrWhiteSpace(q) ? null : q.Trim()
                };

                // Log thông tin
                _logger.LogInformation(
                    "User {UserId} đang xem danh sách đăng ký của sự kiện {EventId}. Total: {Total}, Returned: {Returned}",
                    CurrentUserId,
                    eventId,
                    viewModel.TotalRegistrations,
                    viewModel.ReturnedCount);

                return View(viewModel);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải trang danh sách đăng ký cho sự kiện {EventId}", eventId);
                SetErrorMessage("Đã xảy ra lỗi khi tải trang. Vui lòng thử lại.");
                return RedirectToAction("Index", "Events");
            }
        }


        /// <summary>
        /// Ánh xạ DTO đăng ký sang ViewModel
        /// </summary>
        private static EventRegistrationViewModel MapToRegistrationViewModel(EventRegistrationItemDto dto)
        {
            return new EventRegistrationViewModel
            {
                RegistrationID = dto.RegistrationId,
                UserID = dto.UserId,
                Code = dto.Code ?? string.Empty,
                FullName = dto.FullName ?? string.Empty,
                Email = dto.Email ?? string.Empty,
                RegisterTime = dto.RegisterTime ?? DateTime.MinValue,
                StatusCode = dto.Status,
                CancellationReason = dto.CancellationReason
            };
        }
    }

}

