using UniYouth.Admin.Models.DTOs.AdminUsers;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.AdminUsers
{
    public interface IAdminUsersApiService
    {
        Task<ApiResult<AdminUserListItemDtoPaginatedResultDto>> GetUsersAsync(
            int pageNumber = 1,
            int pageSize = 20,
            string? search = null,
            int? status = null,
            string? role = null);

        Task<ApiResult<AdminUserDetailDto>> GetUserByIdAsync(int userId);
        Task<ApiResult<AdminUserDetailDto>> UpdateUserAsync(int userId, UpdateAdminUserRequestDto request);

        Task<ApiResult<string?>> CreateUserAsync(CreateUserRequestDto request);
        Task<ApiResult<string?>> UpdateUserRolesAsync(int userId, UpdateUserRolesRequestDto request);
        Task<ApiResult<string?>> UpdateUserStatusAsync(int userId, UpdateUserStatusRequestDto request);
    }
}
