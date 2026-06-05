using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Users;
using UniYouth.Api.Shared.Constants;

namespace UniYouth.Api.Controllers
{
    [ApiController]
    [Route("api/admin/users")]
    [Authorize(Roles = RoleNames.Admin)]
    [Produces("application/json")]
    public class AdminUsersController : ControllerBase
    {
        private readonly IUserManagementService _userManagementService;

        public AdminUsersController(IUserManagementService userManagementService)
        {
            _userManagementService = userManagementService;
        }

        [HttpGet]
        [ProducesResponseType(typeof(ApiResponseDto<PaginatedResultDto<AdminUserListItemDto>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        public async Task<IActionResult> GetUsers(
            [FromQuery] int pageNumber = 1,
            [FromQuery] int pageSize = 20,
            [FromQuery] string? search = null,
            [FromQuery] int? status = null,
            [FromQuery] string? role = null,
            CancellationToken cancellationToken = default)
        {
            var result = await _userManagementService.GetUsersAsync(pageNumber, pageSize, search, status, role, cancellationToken);
            return Ok(new ApiResponseDto<PaginatedResultDto<AdminUserListItemDto>>
            {
                Success = true,
                Message = "Lấy danh sách user thành công.",
                Data = result
            });
        }

        [HttpGet("{userId:int}")]
        [ProducesResponseType(typeof(ApiResponseDto<AdminUserDetailDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> GetUserDetail(int userId, CancellationToken cancellationToken)
        {
            var result = await _userManagementService.GetUserDetailAsync(userId, cancellationToken);
            return Ok(new ApiResponseDto<AdminUserDetailDto>
            {
                Success = true,
                Message = "Lấy chi tiết user thành công.",
                Data = result
            });
        }

        [HttpPut("{userId:int}")]
        [ProducesResponseType(typeof(ApiResponseDto<AdminUserDetailDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status409Conflict)]
        public async Task<IActionResult> UpdateUser(
            int userId,
            [FromBody] UpdateAdminUserRequestDto requestDto,
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

            var result = await _userManagementService.UpdateUserAsync(userId, requestDto, cancellationToken);
            return Ok(new ApiResponseDto<AdminUserDetailDto>
            {
                Success = true,
                Message = "Cập nhật user thành công.",
                Data = result
            });
        }

        [HttpPost]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status409Conflict)]
        public async Task<IActionResult> CreateUser([FromBody] CreateUserRequestDto requestDto, CancellationToken cancellationToken)
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

            var userId = await _userManagementService.CreateUserAsync(requestDto, cancellationToken);
            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Tạo tài khoản thành công.",
                Data = new { userId }
            });
        }

        [HttpPut("{userId:int}/roles")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status409Conflict)]
        public async Task<IActionResult> UpdateUserRoles(int userId, [FromBody] UpdateUserRolesRequestDto requestDto, CancellationToken cancellationToken)
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

            await _userManagementService.UpdateUserRolesAsync(userId, requestDto, cancellationToken);
            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Cập nhật phân quyền thành công."
            });
        }

        [HttpPut("{userId:int}/status")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status409Conflict)]
        public async Task<IActionResult> UpdateUserStatus(int userId, [FromBody] UpdateUserStatusRequestDto requestDto, CancellationToken cancellationToken)
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

            await _userManagementService.UpdateUserStatusAsync(userId, requestDto, cancellationToken);
            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Cập nhật trạng thái tài khoản thành công."
            });
        }
    }
}
