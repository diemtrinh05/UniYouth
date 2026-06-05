using UniYouth.Admin.Models.DTOs.Users;
using UniYouth.Admin.Services.Common;

namespace UniYouth.Admin.Services.Users
{
    public interface IUserProfileApiService
    {
        Task<ApiResult<UserProfileDto>> GetMeAsync();
        Task<ApiResult<UserProfileDto>> UpdateMeAsync(UpdateUserProfileDto request);
        Task<ApiResult<ChangePasswordResultDto>> ChangePasswordAsync(ChangePasswordRequestDto request);
        Task<ApiResult<AvatarUploadResultDto>> UploadAvatarAsync(Stream fileStream, string fileName, string contentType);
    }
}
