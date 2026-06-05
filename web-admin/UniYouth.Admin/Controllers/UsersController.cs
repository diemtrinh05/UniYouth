using System.Text.Json;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Admin.Models.DTOs.AdminUsers;
using UniYouth.Admin.Models.DTOs.Positions;
using UniYouth.Admin.Models.ViewModels.Users;
using UniYouth.Admin.Services.AdminUsers;
using UniYouth.Admin.Services.Positions;

namespace UniYouth.Admin.Controllers
{
    public class UsersController : BaseController
    {
        private readonly IAdminUsersApiService _adminUsersApi;
        private readonly IPositionsApiService _positionsApi;
        private readonly ILogger<UsersController> _logger;

        public UsersController(
            IAdminUsersApiService adminUsersApi,
            IPositionsApiService positionsApi,
            ILogger<UsersController> logger)
        {
            _adminUsersApi = adminUsersApi;
            _positionsApi = positionsApi;
            _logger = logger;
        }

        [HttpGet]
        public async Task<IActionResult> Index(
            int pageNumber = 1,
            int pageSize = 20,
            string? search = null,
            int? status = null,
            string? role = null)
        {
            var accessDenied = RequireAdmin();
            if (accessDenied != null)
            {
                return accessDenied;
            }

            pageNumber = pageNumber <= 0 ? 1 : pageNumber;
            pageSize = pageSize <= 0 ? 20 : pageSize;

            var vm = new UserManagementViewModel
            {
                Search = string.IsNullOrWhiteSpace(search) ? null : search.Trim(),
                Status = status,
                Role = string.IsNullOrWhiteSpace(role) ? null : role.Trim()
            };

            await LoadPositionOptionsAsync(vm);

            var result = await _adminUsersApi.GetUsersAsync(pageNumber, pageSize, vm.Search, vm.Status, vm.Role);
            if (result.Success && result.Data != null)
            {
                vm.UsersPage = result.Data;
                return View(vm);
            }

            SetErrorMessage(result.ErrorMessage ?? "Không thể tải danh sách người dùng.");
            vm.UsersPage = new AdminUserListItemDtoPaginatedResultDto
            {
                Items = new List<AdminUserListItemDto>(),
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
        public async Task<IActionResult> Create(UserManagementViewModel model)
        {
            var accessDenied = RequireAdmin();
            if (accessDenied != null)
            {
                return accessDenied;
            }

            ModelState.Clear();
            if (!TryValidateModel(model.CreateUser, nameof(model.CreateUser)))
            {
                SetErrorMessage("Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.");
                await LoadPositionOptionsAsync(model);
                await LoadUsersPageAsync(model);
                return View("Index", model);
            }

            var roles = SplitCsv(model.CreateUser.RolesCsv);
            if (roles.Count == 0)
            {
                SetErrorMessage("Roles không hợp lệ.");
                await LoadPositionOptionsAsync(model);
                await LoadUsersPageAsync(model);
                return View("Index", model);
            }

            var request = new CreateUserRequestDto
            {
                Code = model.CreateUser.Code.Trim(),
                FullName = model.CreateUser.FullName.Trim(),
                Email = model.CreateUser.Email.Trim(),
                Phone = string.IsNullOrWhiteSpace(model.CreateUser.Phone) ? null : model.CreateUser.Phone.Trim(),
                Gender = model.CreateUser.Gender,
                DateOfBirth = model.CreateUser.DateOfBirth.HasValue
                    ? DateOnly.FromDateTime(model.CreateUser.DateOfBirth.Value)
                    : null,
                PositionId = model.CreateUser.PositionId!.Value,
                Roles = roles
            };

            var result = await _adminUsersApi.CreateUserAsync(request);
            if (result.Success)
            {
                SetSuccessMessage(string.IsNullOrWhiteSpace(result.ErrorMessage) ? "Tạo người dùng thành công." : result.ErrorMessage!);
                if (!string.IsNullOrWhiteSpace(result.Data))
                {
                    TempData["LastAdminUserApiData"] = result.Data;
                }
                TempData["CreatedUserSummary"] = JsonSerializer.Serialize(new
                {
                    code = request.Code,
                    initialPassword = request.Code,
                    initialStatus = "Inactive - sẽ tự kích hoạt khi đăng nhập lần đầu",
                    mustChangePassword = true,
                    nextSteps = new[]
                    {
                        "Gửi mã tài khoản và mật khẩu khởi tạo cho người dùng.",
                        "Yêu cầu người dùng đăng nhập bằng đúng mã tài khoản vừa tạo.",
                        "Nhắc người dùng đổi mật khẩu ngay sau lần đăng nhập đầu tiên."
                    }
                });

                _logger.LogInformation("Admin {AdminId} created user {Code}", CurrentUserId, request.Code);
            }
            else
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể tạo người dùng.");
            }

            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateRoles(UserManagementViewModel model)
        {
            var accessDenied = RequireAdmin();
            if (accessDenied != null)
            {
                return accessDenied;
            }

            ModelState.Clear();
            if (!TryValidateModel(model.UpdateRoles, nameof(model.UpdateRoles)))
            {
                SetErrorMessage("Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.");
                await LoadPositionOptionsAsync(model);
                await LoadUsersPageAsync(model);
                return View("Index", model);
            }

            var roles = SplitCsv(model.UpdateRoles.RolesCsv);
            if (roles.Count == 0)
            {
                SetErrorMessage("Roles không hợp lệ.");
                await LoadPositionOptionsAsync(model);
                await LoadUsersPageAsync(model);
                return View("Index", model);
            }

            var request = new UpdateUserRolesRequestDto { Roles = roles };
            var result = await _adminUsersApi.UpdateUserRolesAsync(model.UpdateRoles.UserId, request);

            if (result.Success)
            {
                SetSuccessMessage(string.IsNullOrWhiteSpace(result.ErrorMessage) ? "Cập nhật roles thành công." : result.ErrorMessage!);
                if (!string.IsNullOrWhiteSpace(result.Data))
                {
                    TempData["LastAdminUserApiData"] = result.Data;
                }
            }
            else
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể cập nhật roles.");
            }

            return RedirectToAction(nameof(Index));
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateStatus(UserManagementViewModel model)
        {
            var accessDenied = RequireAdmin();
            if (accessDenied != null)
            {
                return accessDenied;
            }

            ModelState.Clear();
            if (!TryValidateModel(model.UpdateStatus, nameof(model.UpdateStatus)))
            {
                SetErrorMessage("Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.");
                await LoadPositionOptionsAsync(model);
                await LoadUsersPageAsync(model);
                return View("Index", model);
            }

            var request = new UpdateUserStatusRequestDto { Status = model.UpdateStatus.Status };
            var result = await _adminUsersApi.UpdateUserStatusAsync(model.UpdateStatus.UserId, request);

            if (result.Success)
            {
                SetSuccessMessage(string.IsNullOrWhiteSpace(result.ErrorMessage) ? "Cập nhật trạng thái thành công." : result.ErrorMessage!);
                if (!string.IsNullOrWhiteSpace(result.Data))
                {
                    TempData["LastAdminUserApiData"] = result.Data;
                }
            }
            else
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể cập nhật trạng thái.");
            }

            return RedirectToAction(nameof(Index));
        }

        [HttpGet]
        public async Task<IActionResult> Detail(int id, string? returnUrl = null)
        {
            var accessDenied = RequireAdmin();
            if (accessDenied != null)
            {
                return accessDenied;
            }

            var result = await _adminUsersApi.GetUserByIdAsync(id);
            if (result.Success && result.Data != null)
            {
                ViewBag.ReturnUrl = returnUrl;
                return View(result.Data);
            }

            SetErrorMessage(result.ErrorMessage ?? "Không thể tải thông tin người dùng.");

            if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
            {
                return Redirect(returnUrl);
            }

            return RedirectToAction(nameof(Index));
        }

        [HttpGet]
        public async Task<IActionResult> EditProfile(int id, string? returnUrl = null)
        {
            var accessDenied = RequireAdmin();
            if (accessDenied != null)
            {
                return accessDenied;
            }

            var result = await _adminUsersApi.GetUserByIdAsync(id);
            if (!result.Success || result.Data == null)
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể tải thông tin người dùng.");
                return RedirectToAction(nameof(Index));
            }

            var vm = new UpdateAdminUserProfileViewModel
            {
                UserId = result.Data.UserId,
                Code = result.Data.Code,
                FullName = result.Data.FullName ?? string.Empty,
                Email = result.Data.Email ?? string.Empty,
                Phone = result.Data.Phone,
                Gender = result.Data.Gender,
                DateOfBirth = result.Data.DateOfBirth,
                Address = result.Data.Address,
                UnitName = result.Data.UnitName,
                PositionId = result.Data.PositionId,
                JoinDate = result.Data.JoinDate,
                ReturnUrl = returnUrl,
                PositionOptions = await GetPositionOptionsAsync()
            };

            return View(vm);
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> EditProfile(UpdateAdminUserProfileViewModel model)
        {
            var accessDenied = RequireAdmin();
            if (accessDenied != null)
            {
                return accessDenied;
            }

            if (!ModelState.IsValid)
            {
                model.PositionOptions = await GetPositionOptionsAsync();
                return View(model);
            }

            var request = new UpdateAdminUserRequestDto
            {
                FullName = model.FullName.Trim(),
                Email = model.Email.Trim(),
                Phone = string.IsNullOrWhiteSpace(model.Phone) ? null : model.Phone.Trim(),
                Gender = model.Gender,
                DateOfBirth = model.DateOfBirth.HasValue
                    ? DateOnly.FromDateTime(model.DateOfBirth.Value)
                    : null,
                Address = string.IsNullOrWhiteSpace(model.Address) ? null : model.Address.Trim(),
                PositionId = model.PositionId,
                JoinDate = model.JoinDate.HasValue
                    ? DateOnly.FromDateTime(model.JoinDate.Value)
                    : null
            };

            var result = await _adminUsersApi.UpdateUserAsync(model.UserId, request);
            if (result.Success)
            {
                SetSuccessMessage(string.IsNullOrWhiteSpace(result.ErrorMessage)
                    ? "Cập nhật thông tin người dùng thành công."
                    : result.ErrorMessage!);

                if (!string.IsNullOrWhiteSpace(model.ReturnUrl) && Url.IsLocalUrl(model.ReturnUrl))
                {
                    return Redirect(model.ReturnUrl);
                }

                return RedirectToAction(nameof(Detail), new { id = model.UserId });
            }

            ModelState.AddModelError(string.Empty, result.ErrorMessage ?? "Không thể cập nhật người dùng.");
            model.PositionOptions = await GetPositionOptionsAsync();
            return View(model);
        }

        private async Task LoadPositionOptionsAsync(UserManagementViewModel model)
        {
            model.PositionOptions = await GetPositionOptionsAsync();
        }

        private async Task<IReadOnlyList<PositionOptionDto>> GetPositionOptionsAsync()
        {
            var result = await _positionsApi.GetPositionsAsync();
            return result.Success && result.Data != null
                ? result.Data
                : Array.Empty<PositionOptionDto>();
        }

        private async Task LoadUsersPageAsync(UserManagementViewModel model)
        {
            var result = await _adminUsersApi.GetUsersAsync(1, 20, model.Search, model.Status, model.Role);
            model.UsersPage = result.Success && result.Data != null
                ? result.Data
                : new AdminUserListItemDtoPaginatedResultDto
                {
                    Items = new List<AdminUserListItemDto>(),
                    PageNumber = 1,
                    PageSize = 20,
                    TotalCount = 0,
                    TotalPages = 1,
                    HasNextPage = false,
                    HasPreviousPage = false
                };
        }

        private static List<string> SplitCsv(string? csv)
        {
            if (string.IsNullOrWhiteSpace(csv))
            {
                return new List<string>();
            }

            return csv
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Where(s => !string.IsNullOrWhiteSpace(s))
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();
        }
    }
}
