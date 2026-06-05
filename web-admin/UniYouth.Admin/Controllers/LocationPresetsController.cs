using Microsoft.AspNetCore.Mvc;
using UniYouth.Admin.Models.DTOs.LocationPresets;
using UniYouth.Admin.Models.ViewModels.LocationPresets;
using UniYouth.Admin.Services.LocationPresets;

namespace UniYouth.Admin.Controllers
{
    public class LocationPresetsController : BaseController
    {
        private readonly ILocationPresetsApiService _api;
        private readonly ILogger<LocationPresetsController> _logger;

        public LocationPresetsController(ILocationPresetsApiService api, ILogger<LocationPresetsController> logger)
        {
            _api = api;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> Index(
            int pageNumber = 1,
            int pageSize = 20,
            string? q = null,
            bool includeInactive = false)
        {
            pageNumber = pageNumber <= 0 ? 1 : pageNumber;
            pageSize = pageSize <= 0 ? 20 : pageSize;

            var vm = new LocationPresetsIndexViewModel
            {
                Q = string.IsNullOrWhiteSpace(q) ? null : q.Trim(),
                IncludeInactive = includeInactive
            };

            var result = await _api.GetLocationPresetsAsync(
                pageNumber,
                pageSize,
                vm.Q,
                IsAdmin ? CurrentUserInstituteId : null,
                includeInactive);

            if (result.Success && result.Data != null)
            {
                vm.Page = result.Data;
                return View(vm);
            }

            SetErrorMessage(result.ErrorMessage ?? "Không thể tải danh sách vị trí định sẵn.");
            vm.Page = new LocationPresetDtoPaginatedResultDto
            {
                Items = new List<LocationPresetDto>(),
                PageNumber = pageNumber,
                PageSize = pageSize,
                TotalCount = 0,
                TotalPages = 1,
                HasNextPage = false,
                HasPreviousPage = false
            };

            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(LocationPresetsIndexViewModel model)
        {
            if (!ModelState.IsValid)
            {
                SetErrorMessage("Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.");
                return RedirectToAction(nameof(Index));
            }

            var request = new CreateLocationPresetRequestDto
            {
                Name = model.Create.Name.Trim(),
                Address = string.IsNullOrWhiteSpace(model.Create.Address) ? null : model.Create.Address.Trim(),
                Latitude = model.Create.Latitude,
                Longitude = model.Create.Longitude,
                RadiusMeters = model.Create.RadiusMeters,
                InstituteId = CurrentUserInstituteId,
                IsActive = model.Create.IsActive
            };

            var result = await _api.CreateAsync(request);
            if (result.Success)
            {
                SetSuccessMessage(string.IsNullOrWhiteSpace(result.ErrorMessage) ? "Tạo vị trí định sẵn thành công." : result.ErrorMessage!);
                _logger.LogInformation("User {UserId} created location preset {Name}", CurrentUserId, request.Name);
            }
            else
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể tạo vị trí định sẵn.");
            }

            return RedirectToAction(nameof(Index));
        }

        [HttpGet]
        public async Task<IActionResult> Edit(int id, string? returnUrl = null)
        {
            var result = await _api.GetByIdAsync(id);
            if (!result.Success || result.Data == null)
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể tải vị trí định sẵn.");
                return RedirectToAction(nameof(Index));
            }

            ViewBag.ReturnUrl = returnUrl;
            var dto = result.Data;
            var vm = new UpdateLocationPresetForm
            {
                LocationPresetId = dto.LocationPresetId,
                Name = dto.Name ?? string.Empty,
                Address = dto.Address,
                Latitude = dto.Latitude,
                Longitude = dto.Longitude,
                RadiusMeters = dto.RadiusMeters,
                IsActive = dto.IsActive
            };
            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(UpdateLocationPresetForm model, string? returnUrl = null)
        {
            if (!ModelState.IsValid)
            {
                ViewBag.ReturnUrl = returnUrl;
                return View(model);
            }

            var request = new UpdateLocationPresetRequestDto
            {
                Name = model.Name.Trim(),
                Address = string.IsNullOrWhiteSpace(model.Address) ? null : model.Address.Trim(),
                Latitude = model.Latitude,
                Longitude = model.Longitude,
                RadiusMeters = model.RadiusMeters,
                InstituteId = CurrentUserInstituteId,
                IsActive = model.IsActive
            };

            var result = await _api.UpdateAsync(model.LocationPresetId, request);
            if (result.Success)
            {
                SetSuccessMessage(string.IsNullOrWhiteSpace(result.ErrorMessage) ? "Cập nhật vị trí định sẵn thành công." : result.ErrorMessage!);

                if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
                {
                    return Redirect(returnUrl);
                }

                return RedirectToAction(nameof(Index));
            }

            ModelState.AddModelError(string.Empty, result.ErrorMessage ?? "Không thể cập nhật vị trí định sẵn.");
            ViewBag.ReturnUrl = returnUrl;
            return View(model);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int id)
        {
            var result = await _api.DeleteAsync(id);
            if (result.Success)
            {
                SetSuccessMessage(string.IsNullOrWhiteSpace(result.ErrorMessage) ? "Xóa vị trí định sẵn thành công." : result.ErrorMessage!);
            }
            else
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể xóa vị trí định sẵn.");
            }

            return RedirectToAction(nameof(Index));
        }
    }
}
