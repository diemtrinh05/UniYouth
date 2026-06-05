using Microsoft.AspNetCore.Mvc;
using UniYouth.Admin.Models.ViewModels.Profile;
using UniYouth.Admin.Services.Positions;
using UniYouth.Admin.Services.Users;

namespace UniYouth.Admin.Controllers
{
    public class ProfileController : BaseController
    {
        private readonly IUserProfileApiService _userProfileApi;
        private readonly IPositionsApiService _positionsApi;
        private readonly ILogger<ProfileController> _logger;
        private readonly long _maxFileSize;
        private readonly HashSet<string> _allowedMimeTypes;

        public ProfileController(
            IUserProfileApiService userProfileApi,
            IPositionsApiService positionsApi,
            ILogger<ProfileController> logger,
            IConfiguration configuration)
        {
            _userProfileApi = userProfileApi;
            _positionsApi = positionsApi;
            _logger = logger;

            _maxFileSize = configuration.GetValue<long>("FileUpload:MaxFileSize");
            if (_maxFileSize <= 0)
            {
                _maxFileSize = 5 * 1024 * 1024;
                _logger.LogWarning("Thiếu/không hợp lệ cấu hình FileUpload:MaxFileSize. Dùng fallback {Max} bytes.", _maxFileSize);
            }

            var configuredMimeTypes = configuration
                .GetSection("FileUpload:AllowedMimeTypes")
                .Get<string[]>();
            _allowedMimeTypes = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (configuredMimeTypes != null)
            {
                foreach (var mimeType in configuredMimeTypes)
                {
                    if (!string.IsNullOrWhiteSpace(mimeType))
                    {
                        _allowedMimeTypes.Add(mimeType.Trim());
                    }
                }
            }

            if (_allowedMimeTypes.Contains("image/jpeg"))
            {
                _allowedMimeTypes.Add("image/jpg");
            }
        }

        [HttpGet]
        public async Task<IActionResult> Index()
        {
            var result = await _userProfileApi.GetMeAsync();
            if (!result.Success)
            {
                SetErrorMessage(result.ErrorMessage ?? "Không thể tải thông tin cá nhân.");
                return View(new ProfileIndexViewModel
                {
                    PositionOptions = await GetPositionOptionsAsync()
                });
            }

            var profile = result.Data;
            SyncAvatarSession(profile?.AvatarUrl);
            return View(new ProfileIndexViewModel
            {
                Profile = profile,
                Update = new UpdateProfileForm
                {
                    FullName = profile?.FullName ?? string.Empty,
                    Phone = profile?.Phone,
                    Gender = profile?.Gender,
                    DateOfBirth = profile?.DateOfBirth,
                    Address = profile?.Address,
                    InstituteId = profile?.InstituteId,
                    PositionId = profile?.PositionId,
                    JoinDate = profile?.JoinDate,
                    UnitName = profile?.UnitName
                },
                PositionOptions = await GetPositionOptionsAsync()
            });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Update([Bind(Prefix = "Update")] UpdateProfileForm model)
        {
            if (!ModelState.IsValid)
            {
                var current = await _userProfileApi.GetMeAsync();
                return View("Index", new ProfileIndexViewModel
                {
                    Profile = current.Success ? current.Data : null,
                    Update = model,
                    PositionOptions = await GetPositionOptionsAsync()
                });
            }

            var request = new Models.DTOs.Users.UpdateUserProfileDto
            {
                FullName = model.FullName.Trim(),
                Phone = string.IsNullOrWhiteSpace(model.Phone) ? null : model.Phone.Trim(),
                Gender = model.Gender,
                DateOfBirth = model.DateOfBirth.HasValue
                    ? DateOnly.FromDateTime(model.DateOfBirth.Value)
                    : null,
                Address = string.IsNullOrWhiteSpace(model.Address) ? null : model.Address.Trim(),
                InstituteId = model.InstituteId,
                PositionId = model.PositionId,
                JoinDate = model.JoinDate.HasValue
                    ? DateOnly.FromDateTime(model.JoinDate.Value)
                    : null
            };

            var result = await _userProfileApi.UpdateMeAsync(request);
            if (result.Success)
            {
                SetSuccessMessage(string.IsNullOrWhiteSpace(result.ErrorMessage) ? "Cập nhật thông tin cá nhân thành công." : result.ErrorMessage!);
                _logger.LogInformation("User {UserId} updated profile", CurrentUserId);
                return RedirectToAction(nameof(Index));
            }

            SetErrorMessage(result.ErrorMessage ?? "Không thể cập nhật thông tin cá nhân.");
            var currentProfile = await _userProfileApi.GetMeAsync();
            return View("Index", new ProfileIndexViewModel
            {
                Profile = currentProfile.Success ? currentProfile.Data : null,
                Update = model,
                PositionOptions = await GetPositionOptionsAsync()
            });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> ChangePassword([Bind(Prefix = "ChangePassword")] ChangePasswordForm model)
        {
            if (!ModelState.IsValid)
            {
                var current = await _userProfileApi.GetMeAsync();
                return View("Index", new ProfileIndexViewModel
                {
                    Profile = current.Success ? current.Data : null,
                    Update = current.Success && current.Data != null
                        ? new UpdateProfileForm
                        {
                            FullName = current.Data.FullName ?? string.Empty,
                            Phone = current.Data.Phone,
                            Gender = current.Data.Gender,
                            DateOfBirth = current.Data.DateOfBirth,
                            Address = current.Data.Address,
                            InstituteId = current.Data.InstituteId,
                            PositionId = current.Data.PositionId,
                            JoinDate = current.Data.JoinDate,
                            UnitName = current.Data.UnitName
                        }
                        : new UpdateProfileForm(),
                    ChangePassword = model,
                    PositionOptions = await GetPositionOptionsAsync()
                });
            }

            var request = new Models.DTOs.Users.ChangePasswordRequestDto
            {
                CurrentPassword = model.CurrentPassword,
                NewPassword = model.NewPassword,
                ConfirmNewPassword = model.ConfirmNewPassword
            };

            var result = await _userProfileApi.ChangePasswordAsync(request);
            if (result.Success)
            {
                var message = result.Data?.Message;
                SetSuccessMessage(string.IsNullOrWhiteSpace(message) ? "Đổi mật khẩu thành công." : message!);
                return RedirectToAction(nameof(Index));
            }

            SetErrorMessage(result.ErrorMessage ?? "Không thể đổi mật khẩu.");
            var currentProfile = await _userProfileApi.GetMeAsync();
            return View("Index", new ProfileIndexViewModel
            {
                Profile = currentProfile.Success ? currentProfile.Data : null,
                Update = currentProfile.Success && currentProfile.Data != null
                    ? new UpdateProfileForm
                    {
                        FullName = currentProfile.Data.FullName ?? string.Empty,
                        Phone = currentProfile.Data.Phone,
                        Gender = currentProfile.Data.Gender,
                        DateOfBirth = currentProfile.Data.DateOfBirth,
                        Address = currentProfile.Data.Address,
                        InstituteId = currentProfile.Data.InstituteId,
                        PositionId = currentProfile.Data.PositionId,
                        JoinDate = currentProfile.Data.JoinDate,
                        UnitName = currentProfile.Data.UnitName
                    }
                    : new UpdateProfileForm(),
                ChangePassword = model,
                PositionOptions = await GetPositionOptionsAsync()
            });
        }

        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UploadAvatar(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                SetErrorMessage("Vui lòng chọn file ảnh.");
                return RedirectToAction(nameof(Index));
            }

            var contentType = (file.ContentType ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(contentType) || (_allowedMimeTypes.Count > 0 && !_allowedMimeTypes.Contains(contentType)))
            {
                SetErrorMessage($"Chỉ hỗ trợ: {string.Join(", ", _allowedMimeTypes.OrderBy(x => x))}.");
                return RedirectToAction(nameof(Index));
            }

            if (file.Length > _maxFileSize)
            {
                var sizeMB = _maxFileSize / (1024.0 * 1024.0);
                SetErrorMessage($"File ảnh quá lớn (tối đa {sizeMB:F0}MB).");
                return RedirectToAction(nameof(Index));
            }

            await using var stream = file.OpenReadStream();
            var result = await _userProfileApi.UploadAvatarAsync(stream, file.FileName, contentType);
            if (result.Success)
            {
                SyncAvatarSession(result.Data?.AvatarUrl);
                var message = result.Data?.Message;
                SetSuccessMessage(string.IsNullOrWhiteSpace(message) ? "Cập nhật avatar thành công." : message!);
                return RedirectToAction(nameof(Index));
            }

            SetErrorMessage(result.ErrorMessage ?? "Không thể tải lên avatar.");
            return RedirectToAction(nameof(Index));
        }

        private async Task<IReadOnlyList<Models.DTOs.Positions.PositionOptionDto>> GetPositionOptionsAsync()
        {
            var result = await _positionsApi.GetPositionsAsync();
            return result.Success && result.Data != null
                ? result.Data
                : Array.Empty<Models.DTOs.Positions.PositionOptionDto>();
        }

        private void SyncAvatarSession(string? avatarUrl)
        {
            if (HttpContext?.Session == null || string.IsNullOrWhiteSpace(avatarUrl))
            {
                return;
            }

            var current = HttpContext.Session.GetString("CurrentUserAvatarUrl");
            if (!string.Equals(current, avatarUrl, StringComparison.Ordinal))
            {
                HttpContext.Session.SetString("CurrentUserAvatarUrl", avatarUrl);
                HttpContext.Session.SetString("CurrentUserAvatarVer", DateTimeOffset.UtcNow.ToUnixTimeMilliseconds().ToString());
            }
        }
    }
}
