using Microsoft.AspNetCore.Mvc;
using UniYouth.Admin.Models.DTOs.EventTypes;
using UniYouth.Admin.Models.ViewModels.EventTypes;
using UniYouth.Admin.Services.EventTypes;

namespace UniYouth.Admin.Controllers
{
    public class EventTypesController : BaseController
    {
        private readonly IEventTypesApiService _eventTypesApi;
        private readonly ILogger<EventTypesController> _logger;

        public EventTypesController(IEventTypesApiService eventTypesApi, ILogger<EventTypesController> logger)
        {
            _eventTypesApi = eventTypesApi;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var result = await _eventTypesApi.GetEventTypesAsync();
            if (!result.Success)
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể tải danh sách loại sự kiện.");
                return View(new EventTypesIndexViewModel());
            }

            return View(new EventTypesIndexViewModel
            {
                Items = result.Data ?? new List<EventTypeDto>()
            });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(EventTypesIndexViewModel model)
        {
            var accessDenied = RequireAdmin();
            if (accessDenied != null)
            {
                return accessDenied;
            }

            if (!ModelState.IsValid)
            {
                SetErrorMessage("Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.");
                return RedirectToAction(nameof(Index));
            }

            var request = new CreateEventTypeRequestDto
            {
                TypeName = model.Create.TypeName.Trim(),
                Description = string.IsNullOrWhiteSpace(model.Create.Description) ? null : model.Create.Description.Trim()
            };

            var result = await _eventTypesApi.CreateEventTypeAsync(request);
            if (result.Success)
            {
                SetSuccessMessage(string.IsNullOrWhiteSpace(result.ErrorMessage) ? "Tạo loại sự kiện thành công." : result.ErrorMessage!);
                _logger.LogInformation("Admin {AdminId} created event type {TypeName}", CurrentUserId, request.TypeName);
            }
            else
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể tạo loại sự kiện.");
            }

            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Update(UpdateEventTypeForm model)
        {
            var accessDenied = RequireAdmin();
            if (accessDenied != null)
            {
                return accessDenied;
            }

            if (!ModelState.IsValid)
            {
                SetErrorMessage("Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.");
                return RedirectToAction(nameof(Index));
            }

            var request = new UpdateEventTypeRequestDto
            {
                TypeName = model.TypeName.Trim(),
                Description = string.IsNullOrWhiteSpace(model.Description) ? null : model.Description.Trim()
            };

            var result = await _eventTypesApi.UpdateEventTypeAsync(model.TypeId, request);
            if (result.Success)
            {
                SetSuccessMessage(string.IsNullOrWhiteSpace(result.ErrorMessage) ? "Cập nhật loại sự kiện thành công." : result.ErrorMessage!);
            }
            else
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể cập nhật loại sự kiện.");
            }

            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int typeId)
        {
            var accessDenied = RequireAdmin();
            if (accessDenied != null)
            {
                return accessDenied;
            }

            var result = await _eventTypesApi.DeleteEventTypeAsync(typeId);
            if (result.Success)
            {
                SetSuccessMessage(string.IsNullOrWhiteSpace(result.ErrorMessage) ? "Xóa loại sự kiện thành công." : result.ErrorMessage!);
            }
            else
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể xóa loại sự kiện.");
            }

            return RedirectToAction(nameof(Index));
        }
    }
}
