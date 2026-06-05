using Microsoft.AspNetCore.Mvc;
using UniYouth.Admin.Filters;
using UniYouth.Admin.Models.DTOs.EventPoints;
using UniYouth.Admin.Models.ViewModels.EventPoints;
using UniYouth.Admin.Services.EventPoints;

namespace UniYouth.Admin.Controllers
{
    /// <summary>
    /// Controller quản lý cấu hình điểm rèn luyện cho sự kiện
    /// </summary>
    [ServiceFilter(typeof(AdminAuthorizeFilter))]
    public class EventPointsController : BaseController
    {
        private readonly IEventPointsApiService _eventPointsService;
        private readonly ILogger<EventPointsController> _logger;

        public EventPointsController(
            IEventPointsApiService eventPointsService,
            ILogger<EventPointsController> logger)
        {
            _eventPointsService = eventPointsService;
            _logger = logger;
        }

        /// <summary>
        /// Hiển thị danh sách quy tắc điểm
        /// GET: /EventPoints/Index/{eventId}
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Index(int eventId)
        {
            try
            {
                if (eventId <= 0)
                {
                    SetErrorMessage("ID sự kiện không hợp lệ.");
                    return RedirectToAction("Index", "Events");
                }

                var eventResult = await _eventPointsService.GetEventDetailAsync(eventId);
                if (!eventResult.Success || eventResult.Data == null)
                {
                    SetErrorMessage(eventResult.ErrorMessage ?? "Không tìm thấy sự kiện.");
                    return RedirectToAction("Index", "Events");
                }

                var pointsResult = await _eventPointsService.GetEventPointsAsync(eventId);

                var viewModel = new EventPointListViewModel
                {
                    EventId = eventId,
                    EventName = eventResult.Data.EventName ?? "Sự kiện không xác định",
                    EventPoints = pointsResult.Success && pointsResult.Data != null
                        ? pointsResult.Data.Select(MapToViewModel).ToList()
                        : new List<EventPointViewModel>()
                };

                _logger.LogInformation(
                    "User {UserId} đang xem quy tắc điểm của sự kiện {EventId}",
                    CurrentUserId,
                    eventId);

                return View(viewModel);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải trang quản lý điểm cho sự kiện {EventId}", eventId);
                SetErrorMessage("Đã xảy ra lỗi khi tải trang.");
                return RedirectToAction("Index", "Events");
            }
        }

        /// <summary>
        /// Tạo quy tắc điểm mới
        /// POST: /EventPoints/Create
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(int eventId, CreateEventPointViewModel model)
        {
            try
            {
                if (eventId <= 0)
                {
                    SetErrorMessage("ID sự kiện không hợp lệ.");
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                if (!ModelState.IsValid)
                {
                    SetErrorMessage("Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.");
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                var request = new CreateEventPointRequestDto
                {
                    RoleType = model.RoleType,
                    Points = model.Points,
                    Description = model.Description
                };

                var result = await _eventPointsService.CreateEventPointAsync(eventId, request);

                if (result.Success)
                {
                    SetSuccessMessage($"Đã tạo quy tắc điểm cho {GetRoleDisplayName(model.RoleType)} thành công!");

                    _logger.LogInformation(
                        "User {UserId} đã tạo quy tắc điểm cho sự kiện {EventId}. Role: {Role}, Points: {Points}",
                        CurrentUserId,
                        eventId,
                        model.RoleType,
                        model.Points);
                }
                else
                {
                    SetErrorMessage(result.ErrorMessage ?? "Không thể tạo quy tắc điểm.");
                }

                return RedirectToAction(nameof(Index), new { eventId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tạo quy tắc điểm cho sự kiện {EventId}", eventId);
                SetErrorMessage("Đã xảy ra lỗi khi tạo quy tắc điểm.");
                return RedirectToAction(nameof(Index), new { eventId });
            }
        }

        /// <summary>
        /// Cập nhật quy tắc điểm
        /// POST: /EventPoints/Update
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Update(int eventId, EditEventPointViewModel model)
        {
            try
            {
                if (!ModelState.IsValid)
                {
                    SetErrorMessage("Dữ liệu không hợp lệ.");
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                var request = new UpdateEventPointRequestDto
                {
                    Points = model.Points,
                    Description = model.Description
                };

                var result = await _eventPointsService.UpdateEventPointAsync(model.EventPointID, request);

                if (result.Success)
                {
                    SetSuccessMessage("Đã cập nhật quy tắc điểm thành công!");

                    _logger.LogInformation(
                        "User {UserId} đã cập nhật quy tắc điểm {PointId}",
                        CurrentUserId,
                        model.EventPointID);
                }
                else
                {
                    SetErrorMessage(result.ErrorMessage ?? "Không thể cập nhật quy tắc điểm.");
                }

                return RedirectToAction(nameof(Index), new { eventId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật quy tắc điểm {PointId}", model.EventPointID);
                SetErrorMessage("Đã xảy ra lỗi khi cập nhật.");
                return RedirectToAction(nameof(Index), new { eventId });
            }
        }

        /// <summary>
        /// Xóa quy tắc điểm
        /// POST: /EventPoints/Delete
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int eventId, int eventPointId)
        {
            try
            {
                var result = await _eventPointsService.DeleteEventPointAsync(eventPointId);

                if (result.Success)
                {
                    SetSuccessMessage("Đã xóa quy tắc điểm thành công!");

                    _logger.LogInformation(
                        "User {UserId} đã xóa quy tắc điểm {PointId}",
                        CurrentUserId,
                        eventPointId);
                }
                else
                {
                    SetErrorMessage(result.ErrorMessage ?? "Không thể xóa quy tắc điểm.");
                }

                return RedirectToAction(nameof(Index), new { eventId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi xóa quy tắc điểm {PointId}", eventPointId);
                SetErrorMessage("Đã xảy ra lỗi khi xóa.");
                return RedirectToAction(nameof(Index), new { eventId });
            }
        }

        #region Helper Methods

        private static EventPointViewModel MapToViewModel(EventPointDto dto)
        {
            return new EventPointViewModel
            {
                EventPointID = dto.EventPointID,
                EventID = dto.EventID,
                RoleType = dto.RoleType ?? string.Empty,
                Points = dto.Points,
                Description = dto.Description,
                CreatedDate = dto.CreatedDate
            };
        }

        private static string GetRoleDisplayName(string roleType)
        {
            return roleType switch
            {
                "Organizer" => "Ban tổ chức",
                "Participant" => "Người tham gia",
                "Volunteer" => "Tình nguyện viên",
                _ => roleType
            };
        }

        #endregion
    }
}
