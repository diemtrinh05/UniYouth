using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.DependencyInjection;
using UniYouth.Admin.Helpers;
using UniYouth.Admin.Services.Users;

namespace UniYouth.Admin.Controllers
{
    /// <summary>
    /// Base Controller cho tất cả controllers trong Admin Web
    /// Cung cấp các properties và methods chung cho việc truy cập thông tin user
    /// </summary>
    public class BaseController : Controller
    {
        /// <summary>
        /// Thông tin user hiện tại (được lấy từ JWT token)
        /// </summary>
        protected UserInfo? CurrentUser { get; private set; }

        /// <summary>
        /// User ID của user đang đăng nhập
        /// </summary>
        protected int CurrentUserId => CurrentUser?.UserId ?? 0;

        /// <summary>
        /// Role của user đang đăng nhập
        /// </summary>
        protected string CurrentUserRole => CurrentUser?.RolesDisplay ?? string.Empty;

        protected int? CurrentUserInstituteId => CurrentUser?.InstituteId;
        protected int? CurrentUserUnitId => CurrentUser?.UnitId;

        /// <summary>
        /// Tên đầy đủ của user đang đăng nhập
        /// </summary>
        protected string CurrentUserFullName => CurrentUser?.FullName ?? string.Empty;

        /// <summary>
        /// Kiểm tra user hiện tại có phải Admin không
        /// </summary>
        protected bool IsAdmin => CurrentUser?.IsAdmin ?? false;

        /// <summary>
        /// Kiểm tra user hiện tại có phải CanBo không
        /// </summary>
        protected bool IsCanBo => CurrentUser?.IsCanBo ?? false;

        /// <summary>
        /// Method được gọi TRƯỚC mỗi action
        /// Dùng để load user info từ HttpContext
        /// </summary>
        public override async Task OnActionExecutionAsync(
            ActionExecutingContext context,
            ActionExecutionDelegate next)
        {
            // Lấy UserInfo từ HttpContext.Items
            // (đã được set bởi AdminAuthorizeFilter)
            if (HttpContext.Items.TryGetValue("UserInfo", out var userInfoObj)
                && userInfoObj is UserInfo userInfo)
            {
                CurrentUser = userInfo;

                // Truyền thông tin user vào ViewBag để dùng trong Views
                ViewBag.CurrentUser = userInfo;
                ViewBag.CurrentUserRole = userInfo.RolesDisplay;
                ViewBag.CurrentUserFullName = userInfo.FullName;
                ViewBag.IsAdmin = userInfo.IsAdmin;
                ViewBag.IsCanBo = userInfo.IsCanBo;
                ViewBag.CurrentUserInstituteId = userInfo.InstituteId;
                ViewBag.CurrentUserUnitId = userInfo.UnitId;
            }

            var avatarLoadedFromApi = false;

            if (CurrentUser != null)
            {
                var userProfileApi = HttpContext.RequestServices.GetService<IUserProfileApiService>();
                if (userProfileApi != null)
                {
                    var profileResult = await userProfileApi.GetMeAsync();
                    if (profileResult.Success && profileResult.Data != null)
                    {
                        if (!string.IsNullOrWhiteSpace(profileResult.Data.AvatarUrl))
                        {
                            ViewBag.CurrentUserAvatarUrl = profileResult.Data.AvatarUrl;
                            ViewBag.CurrentUserAvatarVer = HttpContext.Session.GetString("CurrentUserAvatarVer");
                            HttpContext.Session.SetString("CurrentUserAvatarUrl", profileResult.Data.AvatarUrl);
                            avatarLoadedFromApi = true;
                        }

                        if (!string.IsNullOrWhiteSpace(profileResult.Data.Position))
                        {
                            ViewBag.CurrentUserPosition = profileResult.Data.Position;
                            HttpContext.Session.SetString("CurrentUserPosition", profileResult.Data.Position);
                        }
                    }
                }
            }

            if (!avatarLoadedFromApi)
            {
                // Fallback an toàn khi API lỗi hoặc request hiện tại chưa có identity hợp lệ.
                var avatarUrl = HttpContext.Session.GetString("CurrentUserAvatarUrl");
                if (!string.IsNullOrWhiteSpace(avatarUrl))
                {
                    ViewBag.CurrentUserAvatarUrl = avatarUrl;
                    ViewBag.CurrentUserAvatarVer = HttpContext.Session.GetString("CurrentUserAvatarVer");
                }
            }

            var position = HttpContext.Session.GetString("CurrentUserPosition");
            if (!string.IsNullOrWhiteSpace(position))
            {
                ViewBag.CurrentUserPosition = position;
            }

            await base.OnActionExecutionAsync(context, next);
        }

        /// <summary>
        /// Helper method: Kiểm tra user có quyền Admin không
        /// Nếu không, redirect về AccessDenied
        /// </summary>
        protected IActionResult RequireAdmin()
        {
            if (!IsAdmin)
            {
                return RedirectToAction("AccessDenied", "Account");
            }
            return null!;
        }

        /// <summary>
        /// Helper method: Tạo success message trong TempData
        /// </summary>
        protected void SetSuccessMessage(string message)
        {
            TempData["SuccessMessage"] = message;
        }

        /// <summary>
        /// Helper method: Tạo error message trong TempData
        /// </summary>
        protected void SetErrorMessage(string message)
        {
            TempData["ErrorMessage"] = message;
        }

        /// <summary>
        /// Helper method: Tạo info message trong TempData
        /// </summary>
        protected void SetInfoMessage(string message)
        {
            TempData["InfoMessage"] = message;
        }
    }
}
