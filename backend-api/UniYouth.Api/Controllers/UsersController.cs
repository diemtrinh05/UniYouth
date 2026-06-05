using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Users;
using UniYouth.Api.Shared.Extensions;
using UniYouth.Api.Shared.Helpers;

namespace UniYouth.Api.Controllers
{
    /// <summary>
    /// Controller quản lý hồ sơ người dùng
    /// Tất cả các API trong controller này đều yêu cầu xác thực
    /// </summary>
    [ApiController]
    [Route("api/[controller]")]
    [Authorize] // Bắt buộc xác thực cho tất cả endpoint
    [Produces("application/json")]
    public class UsersController : ControllerBase
    {
        private readonly IUserService _userService;
        private readonly IFaceProfileEnrollmentService _faceProfileEnrollmentService;
        private readonly ILogger<UsersController> _logger;
        private readonly IWebHostEnvironment _environment;

        public UsersController(
            IUserService userService,
            IFaceProfileEnrollmentService faceProfileEnrollmentService,
            ILogger<UsersController> logger,
            IWebHostEnvironment environment)
        {
            _userService = userService;
            _faceProfileEnrollmentService = faceProfileEnrollmentService;
            _logger = logger;
            _environment = environment;
        }

        /// <summary>
        /// Lấy thông tin hồ sơ của người dùng đang đăng nhập
        /// </summary>
        /// <returns>Dữ liệu hồ sơ người dùng</returns>
        /// <response code="200">Trả về thông tin hồ sơ người dùng</response>
        /// <response code="401">Người dùng chưa được xác thực</response>
        /// <response code="404">Không tìm thấy thông tin người dùng</response>
        /// <remarks>
        /// Ví dụ request:
        /// 
        ///     GET /api/users/me
        ///     Authorization: Bearer {token}
        /// 
        /// UserId sẽ được tự động lấy từ JWT token.
        /// Không cần truyền UserId trong request.
        /// </remarks>
        [HttpGet("me")]
        [ProducesResponseType(typeof(ApiResponseDto<UserProfileDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetMyProfile()
        {
            // IMPORTANT: Lấy UserId từ JWT claims
            // JWT token chứa claim "userId" được thiết lập khi đăng nhập
            // Không nhận UserId từ request để tránh truy cập trái phép hồ sơ người khác
            //var userIdClaim = User.FindFirst("userId")?.Value;
            var userId = User.GetUserId();

            //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            //{
            //    _logger.LogWarning("JWT token không hợp lệ hoặc thiếu claim userId");
            //    return Unauthorized(new
            //    {
            //        message = "Token không hợp lệ hoặc thiếu thông tin người dùng"
            //    });
            //}

            // Giao việc xử lý nghiệp vụ cho service
            var profile = await _userService.GetUserProfileAsync(userId);

            if (profile == null)
            {
                _logger.LogWarning("Không tìm thấy hồ sơ cho người dùng {UserId}", userId);
                return NotFound(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Không tìm thấy thông tin người dùng"
                });
            }

            return Ok(new ApiResponseDto<UserProfileDto>
            {
                Success = true,
                Message = "Lấy thông tin người dùng thành công",
                Data = profile
            });
        }

        /// <summary>
        /// Cập nhật thông tin hồ sơ của người dùng đang đăng nhập
        /// </summary>
        /// <param name="updateDto">Dữ liệu cập nhật hồ sơ</param>
        /// <returns>Thông tin hồ sơ sau khi cập nhật</returns>
        /// <response code="200">Cập nhật hồ sơ thành công</response>
        /// <response code="400">Dữ liệu đầu vào không hợp lệ</response>
        /// <response code="401">Người dùng chưa được xác thực</response>
        /// <response code="404">Không tìm thấy người dùng</response>
        /// <remarks>
        /// Ví dụ request:
        /// 
        ///     PUT /api/users/me
        ///     Authorization: Bearer {token}
        ///     Content-Type: application/json
        ///     
        ///     {
        ///         "fullName": "Nguyện Van A",
        ///         "phone": "0901234567",
        ///         "avatarUrl": "https://example.com/avatar.jpg",
        ///         "gender": true,
        ///         "dateOfBirth": "2000-01-01",
        ///         "address": "123 Đường ABC, Quận 1, TP.HCM"
        ///     }
        /// 
        /// Các trường KHÔNG được phép cập nhật:
        /// - Email (dùng để đăng nhập)
        /// - Code (định danh đặc biệt)
        /// - Role (chỉ admin được phép)
        /// - Status (chỉ admin được phép)
        /// - Mật khẩu (sử dụng API đổi mật khẩu riêng)
        /// </remarks>
        [HttpPut("me")]
        [ProducesResponseType(typeof(ApiResponseDto<UserProfileDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> UpdateMyProfile([FromBody] UpdateUserProfileDto updateDto)
        {
            // Kiểm tra dữ liệu đầu vào
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = errors
                });
            }

            // IMPORTANT: Lấy UserId từ JWT claims
                // Người dùng chỉ được phép cập nhật CHÍNH hồ sơ của mình
                // Không nhận UserId từ body để tránh leo thang dẫn quyền
                //var userIdClaim = User.FindFirst("userId")?.Value;

                //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                //{
                //    _logger.LogWarning("JWT token không hợp lệ hoặc thiếu claim userId");
                //    return Unauthorized(new
                //    {
                //        message = "Token không hợp lệ hoặc thiếu thông tin người dùng"
                //    });
                //}
                var userId = User.GetUserId();

                // Validate bổ sung: Ngày sinh không được nằm trong tương lai
                if (updateDto.DateOfBirth.HasValue && updateDto.DateOfBirth.Value > DateOnly.FromDateTime(DateTime.Today))
                {
                    return BadRequest(new ApiResponseDto<object>
                    {
                        Success = false,
                        Message = "Ngày sinh không được nằm trong tương lai"
                    });
                }

                // Validate bổ sung: Người dùng phải từ ít nhất 10 tuổi
                if (updateDto.DateOfBirth.HasValue && updateDto.DateOfBirth.Value > DateOnly.FromDateTime(DateTime.Today.AddYears(-10)))
                {
                    return BadRequest(new ApiResponseDto<object>
                    {
                        Success = false,
                        Message = "Người dùng phải ít nhất 10 tuổi"
                    });
                }

                // Giao việc xử lý nghiệp vụ cho service
                var updatedProfile = await _userService.UpdateUserProfileAsync(userId, updateDto);

                if (updatedProfile == null)
                {
                    _logger.LogWarning("Không tìm thấy hồ sơ để cập nhật cho UserId {UserId}", userId);
                    return NotFound(new ApiResponseDto<object>
                    {
                        Success = false,
                        Message = "Không tìm thấy thông tin người dùng để cập nhật"
                    });
                }

                _logger.LogInformation("Người dùng {UserId} đã cập nhật hồ sơ thành công", userId);

                return Ok(new ApiResponseDto<UserProfileDto>
                {
                    Success = true,
                    Message = "Cập nhật thông tin thành công",
                    Data = updatedProfile
                });
        }

        /// <summary>
        /// Đổi mật khẩu cho người dùng đang đăng nhập
        /// </summary>
        /// <param name="requestDto">Yêu cầu thay đổi mật khẩu chứa mật khẩu hiện tại và mật khẩu mới</param>
        /// <returns>Kết quả thành công hay thất bại</returns>
        /// <response code="200">Đã thay đổi mật khẩu thành công</response>
        /// <response code="400">Đầu vào không hợp lệ hoặc mật khẩu hiện tại không chính xác</response>
        /// <response code="401">Người dùng chưa được xác thực</response>
        /// <remarks>
        /// Yêu cầu mẫu:
        /// 
        ///     POST /api/users/change-password
        ///     Authorization: Bearer {token}
        ///     Content-Type: application/json
        ///     
        ///     {
        ///         "currentPassword": "OldPassword123!",
        ///         "newPassword": "NewPassword456!",
        ///         "confirmNewPassword": "NewPassword456!"
        ///     }
        /// 
        /// Yêu cầu về mật khẩu:
        /// - Tối thiểu 8 ký tự
        /// - Ít nhất một chữ hoa
        /// - Ít nhất một chữ cái viết thường
        /// - Ít nhất một chữ số
        /// - Ít nhất một ký tự đặc biệt
        /// 
        /// SECURITY NOTES:
        /// - Phải cung cấp mật khẩu hiện tại để ngăn chặn những thay đổi trái phép
        /// - Mật khẩu mới phải khác với mật khẩu hiện tại
        /// - Sau khi đổi mật khẩu, người dùng nên đăng nhập lại để bảo mật
        /// - Dữ liệu mật khẩu không bao giờ được trả về trong phản hồi
        /// </remarks>
        [HttpPost("change-password")]
        [ProducesResponseType(typeof(ApiResponseDto<ChangePasswordResultDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequestDto requestDto)
        {
            // 1. Xác thực trạng thái mô hình
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = errors
                });
            }

            // 2. SECURITY: Trích xuất UserId từ JWT
                // User có thể thay đổi mật khẩu RIÊNG của mình
                // UserId KHÔNG được chấp nhận từ nội dung yêu cầu để ngăn chặn việc leo thang đặc quyền
                //var userIdClaim = User.FindFirst("userId")?.Value;

                //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
                //{
                //    _logger.LogWarning("Cố gắng đổi mật khẩu với claim userId không hợp lệ");
                //    return Unauthorized(new
                //    {
                //        message = "Token không hợp lệ hoặc thiếu thông tin người dùng"
                //    });
                //}
                var userId = User.GetUserId();
                // 3. Xác thực bổ sung: NewPassword và ConfirmNewPassword phải khớp
                // Điều này đã được xác thực bằng thuộc tính [Compare], nhưng hãy kiểm tra kỹ tính bảo mật
                if (requestDto.NewPassword != requestDto.ConfirmNewPassword)
                {
                    return BadRequest(new ApiResponseDto<object>
                    {
                        Success = false,
                        Message = "Mật khẩu mới và xác nhận mật khẩu không khớp"
                    });
                }

                // 4. Xử lý quyền logic thay đổi mật khẩu cho lớp dịch vụ
                var result = await _userService.ChangePasswordAsync(userId, requestDto);

                // 5. Trả về phản hồi thích hợp dựa trên kết quả
                if (!result.Success)
                {
                    // Thay đổi mật khẩu không thành công (ví dụ: mật khẩu hiện tại không chính xác)
                    _logger.LogWarning("Đổi mật khẩu không thành công cho UserId {UserId}: {Message}", userId, result.Message);
                    return BadRequest(new ApiResponseDto<ChangePasswordResultDto>
                    {
                        Success = false,
                        Message = result.Message,
                        Data = result
                    });
                }

                // Thay đổi mật khẩu thành công
                _logger.LogInformation("Đổi mật khẩu thành công cho UserId {UserId}", userId);

                // SECURITY NOTE: Sau khi thay đổi mật khẩu, hăy xem xét các tùy chọn sau:
                // 1. Buộc đăng xuất (vô hiệu hóa mã thông báo JWT hiện tại) - yêu cầu danh sách đen mã thông báo
                // 2. Thông báo cho người dùng qua email về việc thay đổi mật khẩu
                // 3. Ghi nhật ký sự kiện bảo mật cho dấu vết kiểm tra (đã được thực hiện qua ILogger)

                return Ok(new ApiResponseDto<ChangePasswordResultDto>
                {
                    Success = true,
                    Message = result.Message,
                    Data = result
                });
        }

        /// <summary>
        /// Lấy thông tin người dùng đang đăng nhập từ JWT token
        /// Hữu ích cho việc debug hoặc hiển thị thông tin người dùng hiện tại
        /// </summary>
        /// <returns>Thông tin các claim trong JWT token</returns>
        /// <response code="200">Trả về danh sách claim trong JWT</response>
        [HttpGet("me/token-info")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        public IActionResult GetTokenInfo()
        {
            // Trích xuất tất cả các yêu cầu có liên quan từ token JWT
            var claims = new
            {
                userId = User.FindFirst("userId")?.Value,
                email = User.FindFirst("email")?.Value,
                fullName = User.FindFirst("fullName")?.Value,
                code = User.FindFirst("code")?.Value,
                roles = User.Claims
                    .Where(c => c.Type == "role" || c.Type == ClaimTypes.Role)
                    .Select(c => c.Value)
                    .Distinct()
                    .ToList(),
                unitId = User.FindFirst("unitId")?.Value,
                unitName = User.FindFirst("unitName")?.Value,
                position = User.FindFirst("position")?.Value
            };

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Lấy thông tin token thành công",
                Data = claims
            });
        }

        /// <summary>
        /// Tải ảnh đại diện cho người dùng hiện tại
        /// </summary>
        /// <param name="file">Tệp ảnh đại diện (JPG, PNG hoặc WEBP, tối đa 2MB)</param>
        /// <returns>URL công khai của ảnh đại diện đã tải lên</returns>
        /// <response code="200">Tải ảnh đại diện thành công</response>
        /// <response code="400">Tệp không hợp lệ hoặc lại kiểm tra</response>
        /// <response code="401">Người dùng chưa được xác thực</response>
        /// <response code="404">Không tìm thấy người dùng</response>
        /// <remarks>
        /// Yêu cầu mẫu (sử dụng multipart/form-data):
        ///
        ///     POST /api/users/me/avatar
        ///     Authorization: Bearer {token}
        ///     Content-Type: multipart/form-data
        ///
        ///     file: [dữ liệu nhị phân của ảnh]
        /// 
        /// Yêu cầu đối với tệp:
        /// - Định dạng: JPEG, PNG hoặc WebP
        /// - Kích thước tối đa: 2 MB
        /// - Tên trường tệp phải là "file"
        /// 
        /// The uploaded avatar will:
        /// - Được lưu trên máy chủ
        /// - Thay thế ảnh đại diện hiện có (nếu có)
        /// - Có thể truy cập thông qua URL được trả về
        /// 
        /// SECURITY NOTES:
        /// - Kiểm tra chỉ ký tệp (magic bytes)
        /// - Chỉ chấp nhận MIME type của ảnh
        /// - Giới hạn kích thước tệp để tránh làm dụng
        /// - Người dùng chỉ có thể tải ảnh đại diện của chính mình
        /// </remarks>
        [HttpPost("me/avatar")]
        [Consumes("multipart/form-data")]
        [ProducesResponseType(typeof(ApiResponseDto<AvatarUploadResultDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> UploadAvatar([FromForm] AvatarUploadRequestDto request)
        {
            // 1. SECURITY: Trích xuất UserId từ JWT claims
            // Người dùng CHẤP NHẬN được tải ảnh đại diện của CHÍNH mình
            // Không nhận UserId từ request để tránh leo thang dẫn quyền
            //var userIdClaim = User.FindFirst("userId")?.Value;

            //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            //{
            //    _logger.LogWarning("Cố gắng tải ảnh đại diện với claim userId không hợp lệ");
            //    return Unauthorized(new
            //    {
            //        message = "Token không hợp lệ hoặc thiếu thông tin người dùng"
            //    });
            //}
            var userId = User.GetUserId();
            // 2. Kiểm tra có tệp được gửi lên hay không
            if (request?.File == null || request.File.Length == 0)
            {
                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Vui lòng chọn file ảnh để tải lên"
                });
            }

            // 3. Ghi log cho mục đích kiểm tra bảo mật
            _logger.LogInformation(
                "Yêu cầu tải ảnh đại diện bởi UserId: {UserId}, Tên tệp: {FileName}, Kích thước: {Size} byte",
                userId, request.File.FileName, request.File.Length);

            // 4. Giao việc xử lý tệp cho từng service
            // Truyền webRootPath để service biết nơi lưu tệp
            var result = await _userService.UploadAvatarAsync(
                userId,
                request.File,
                _environment.WebRootPath);

            if (result == null)
            {
                _logger.LogWarning("Tải ảnh đại diện thất bại: Không tìm thấy người dùng với UserId {UserId}", userId);
                return NotFound(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Không tìm thấy người dùng"
                });
            }

            // 5. Trả về kết quả thành công kèm URL ảnh đại diện
            _logger.LogInformation("Tải ảnh đại diện thành công cho UserId: {UserId}", userId);

            return Ok(new ApiResponseDto<AvatarUploadResultDto>
            {
                Success = true,
                Message = "Tải ảnh đại diện thành công",
                Data = result
            });
        }

        /// <summary>
        /// Gửi OTP xác nhận cập nhật khuôn mặt tới email của tài khoản hiện tại
        /// </summary>
        [HttpPost("me/face-profile/re-auth-otp")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status502BadGateway)]
        public async Task<IActionResult> RequestFaceProfileReAuthOtp(CancellationToken cancellationToken)
        {
            var userId = User.GetUserId();

            var result = await _faceProfileEnrollmentService.RequestReEnrollmentOtpAsync(
                userId,
                ClientIpHelper.GetClientIpAddress(HttpContext),
                Request.Headers["User-Agent"].ToString(),
                cancellationToken);

            if (result.Success)
            {
                return Ok(new ApiResponseDto<object>
                {
                    Success = true,
                    Message = result.Message,
                    Data = new
                    {
                        result.ExpiresAt
                    }
                });
            }

            return BadRequest(new ApiResponseDto<object>
            {
                Success = false,
                Message = result.Message
            });
        }

        /// <summary>
        /// Đăng ký hoặc thay thế FaceProfile active cho người dùng hiện tại
        /// </summary>
        /// <param name="request">Ảnh khuôn mặt dạng base64 JPEG</param>
        /// <param name="cancellationToken">Cancellation token</param>
        /// <returns>Thông tin FaceProfile active sau khi đăng ký</returns>
        [HttpPost("me/face-profile")]
        [ProducesResponseType(typeof(ApiResponseDto<FaceProfileEnrollmentResultDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status409Conflict)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status502BadGateway)]
        public async Task<IActionResult> EnrollFaceProfile(
            [FromBody] EnrollFaceProfileRequestDto request,
            CancellationToken cancellationToken)
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = errors
                });
            }

            var userId = User.GetUserId();
            var webRootPath = string.IsNullOrWhiteSpace(_environment.WebRootPath)
                ? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot")
                : _environment.WebRootPath;

            var result = await _faceProfileEnrollmentService.EnrollAsync(
                userId,
                request,
                webRootPath,
                ClientIpHelper.GetClientIpAddress(HttpContext),
                Request.Headers["User-Agent"].ToString(),
                cancellationToken);

            if (result.Succeeded)
            {
                return Ok(new ApiResponseDto<FaceProfileEnrollmentResultDto>
                {
                    Success = true,
                    Message = "Đăng ký khuôn mặt thành công",
                    Data = result.Data
                });
            }

            return result.FailureType switch
            {
                FaceProfileEnrollmentFailureType.UserNotFound => NotFound(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = result.ErrorMessage ?? "Không tìm thấy người dùng"
                }),
                FaceProfileEnrollmentFailureType.InvalidPayload
                or FaceProfileEnrollmentFailureType.NoFaceDetected
                or FaceProfileEnrollmentFailureType.MultipleFacesDetected
                or FaceProfileEnrollmentFailureType.BlurryImage
                or FaceProfileEnrollmentFailureType.ReauthenticationFailed
                or FaceProfileEnrollmentFailureType.ReEnrollCooldownActive => BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = result.ErrorMessage ?? "Không thể đăng ký khuôn mặt"
                }),
                FaceProfileEnrollmentFailureType.CurrentFaceMismatch => Conflict(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = result.ErrorMessage ?? "Khuôn mặt mới không khớp với hồ sơ hiện tại"
                }),
                _ => StatusCode(StatusCodes.Status502BadGateway, new ApiResponseDto<object>
                {
                    Success = false,
                    Message = result.ErrorMessage ?? "Không thể đăng ký khuôn mặt lúc này"
                })
            };
        }

        /// <summary>
        /// Xóa ảnh đại diện của người dùng hiện tại
        /// Đặt AvatarUrl về null trong cơ sở dữ liệu
        /// </summary>
        /// <returns>Thông báo thành công</returns>
        /// <response code="200">Xóa ảnh đại diện thành công</response>
        /// <response code="401">Người dùng chưa được xác thực</response>
        /// <response code="404">Không tìm thấy người dùng</response>
        [HttpDelete("me/avatar")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> DeleteAvatar(CancellationToken cancellationToken)
        {
            //var userIdClaim = User.FindFirst("userId")?.Value;

            //if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out int userId))
            //{
            //    return Unauthorized(new
            //    {
            //        message = "Token không hợp lệ hoặc thiếu thông tin người dùng"
            //    });
            //}
            var userId = User.GetUserId();

            await _userService.DeleteAvatarAsync(userId, _environment.WebRootPath, cancellationToken);

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Đã xóa ảnh đại diện thành công"
            });
        }
    }
}


