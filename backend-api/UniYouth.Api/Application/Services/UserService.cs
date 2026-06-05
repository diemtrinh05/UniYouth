using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Users;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Helpers;
using BC = BCrypt.Net.BCrypt;

namespace UniYouth.Api.Application.Services
{
    /// <summary>
    /// Interface định nghĩa các chức năng quản lý hồ sơ người dùng
    /// </summary>
    public interface IUserService
    {
        /// <summary>
        /// Lấy thông tin hồ sơ người dùng theo UserId
        /// </summary>
        Task<UserProfileDto?> GetUserProfileAsync(int userId);
        /// <summary>
        /// Cập nhật thông tin hồ sơ người dùng
        /// </summary>
        Task<UserProfileDto?> UpdateUserProfileAsync(int userId, UpdateUserProfileDto updateDto);
        /// <summary>
        /// Đổi mật khẩu người dùng
        /// </summary>
        Task<ChangePasswordResultDto> ChangePasswordAsync(int userId, ChangePasswordRequestDto requestDto);
        /// <summary>
        /// Tải ảnh đại diện cho người dùng
        /// </summary>
        Task<AvatarUploadResultDto?> UploadAvatarAsync(int userId, IFormFile file, string webRootPath);

        /// <summary>
        /// Xóa ảnh đại diện của người dùng (xóa file vật lý nếu có) và đặt AvatarUrl về null
        /// </summary>
        Task DeleteAvatarAsync(int userId, string webRootPath, CancellationToken cancellationToken);
    }

    /// <summary>
    /// Service xử lý các nghiệp vụ liên quan đến hồ sơ người dùng
    /// </summary>
    public class UserService : IUserService
    {
        private readonly UniYouthDbContext _context;
        private readonly IPublicUrlBuilder _publicUrlBuilder;
        private readonly ILogger<UserService> _logger;

        public UserService(
            UniYouthDbContext context,
            IPublicUrlBuilder publicUrlBuilder,
            ILogger<UserService> logger)
        {
            _context = context;
            _publicUrlBuilder = publicUrlBuilder;
            _logger = logger;
        }

        /// <summary>
        /// Lấy đầy đủ thông tin hồ sơ người dùng
        /// Bao gồm thông tin cá nhân, vai trò, đơn vị và viện trực thuộc
        /// </summary>
        /// <param name="userId">ID người dùng lấy từ JWT claims</param>
        /// <returns>
        /// DTO hồ sơ người dùng hoặc null nếu không tìm thấy người dùng
        /// </returns>
        public async Task<UserProfileDto?> GetUserProfileAsync(int userId)
        {
            try
            {
                // Truy vấn người dùng kèm theo các dữ liệu liên quan
                // Include UserRoles -> Role: lấy thông tin vai trò
                // Include UserUnits -> Unit: lấy thông tin đơn vị đang hoạt động
                var user = await _context.Users
                    .Include(u => u.UserRoles)
                        .ThenInclude(ur => ur.Role)
                    .Include(u => u.UserUnits.Where(uu => uu.Status == 1))
                        .ThenInclude(uu => uu.Unit)
                    .FirstOrDefaultAsync(u => u.UserID == userId);

                if (user == null)
                {
                    _logger.LogWarning("Không tìm thấy hồ sơ người dùng với UserId: {UserId}", userId);
                    return null;
                }

                // Lấy vai trò chính (vai trò đầu tiên của người dùng)
                var primaryRole = user.UserRoles
                    .Select(ur => ur.Role.RoleName)
                    .FirstOrDefault();

                // Lấy thông tin đơn vị đang hoạt động
                var activeUserUnit = user.UserUnits
                    .Where(uu => uu.Status == 1)
                    .OrderByDescending(uu => uu.JoinDate)
                    .FirstOrDefault();

                // Lấy thông tin viện nếu người dùng đang thuộc một đơn vị
                string? instituteName = null;
                if (activeUserUnit != null)
                {
                    var institute = await _context.Set<Domain.Entities.Institute>()
                        .FirstOrDefaultAsync(i => i.InstituteID == activeUserUnit.Unit.InstituteID);
                    instituteName = institute?.InstituteName;
                }

                var activeFaceProfile = await _context.FaceProfiles
                    .AsNoTracking()
                    .Where(profile => profile.UserID == userId && profile.IsActive == true)
                    .OrderByDescending(profile => profile.UpdatedDate)
                    .ThenByDescending(profile => profile.CreatedDate)
                    .ThenByDescending(profile => profile.FaceProfileID)
                    .FirstOrDefaultAsync();

                var hasActiveFaceProfile = activeFaceProfile?.FaceEmbedding is { Length: > 0 };

                // Ánh xạ dữ liệu từ Entity sang DTO
                // IMPORTANT: Tuyệt đối KHÔNG trả về PasswordHash hoặc các thông tin nhạy cảm
                var profileDto = new UserProfileDto
                {
                    UserId = user.UserID,
                    Code = user.Code,
                    FullName = user.FullName,
                    Email = user.Email,
                    Phone = user.Phone,
                    AvatarUrl = BuildFullUrl(user.AvatarUrl),
                    HasActiveFaceProfile = hasActiveFaceProfile,
                    FaceProfileImageUrl = BuildFullUrl(activeFaceProfile?.ImageUrl),
                    FaceProfileUpdatedDate = activeFaceProfile?.UpdatedDate ?? activeFaceProfile?.CreatedDate,
                    FaceProfileQualityScore = activeFaceProfile?.QualityScore,
                    Gender = user.Gender,
                    DateOfBirth = user.DateOfBirth,
                    Address = user.Address,
                    Role = primaryRole,
                    UnitName = activeUserUnit?.Unit.UnitName,
                    UnitId = activeUserUnit?.UnitID,
                    PositionId = activeUserUnit?.PositionID,
                    JoinDate = activeUserUnit?.JoinDate,
                    Position = activeUserUnit?.Position,
                    InstituteName = instituteName,
                    InstituteId = activeUserUnit?.Unit.InstituteID,
                    Status = user.Status,
                    LastLoginDate = user.LastLoginDate,
                    CreatedDate = user.CreatedDate
                };

                _logger.LogInformation("Đã lấy thông tin hồ sơ cho người dùng {UserId}", userId);
                return profileDto;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi lấy thông tin hồ sơ người dùng {UserId}", userId);
                throw;
            }
        }

        /// <summary>
        /// Cập nhật thông tin hồ sơ người dùng
        /// Chỉ cho phép cập nhật các trường không nhạy cảm
        /// </summary>
        /// <param name="userId">ID người dùng lấy từ JWT claims</param>
        /// <param name="updateDto">Dữ liệu cập nhật từ request</param>
        /// <returns>
        /// DTO hồ sơ đã được cập nhật hoặc null nếu không tìm thấy người dùng
        /// </returns>
        public async Task<UserProfileDto?> UpdateUserProfileAsync(int userId, UpdateUserProfileDto updateDto)
        {
            try
            {
                // Tìm người dùng theo ID
                var user = await _context.Users.FindAsync(userId);

                if (user == null)
                {
                    _logger.LogWarning("Không tìm thấy người dùng để cập nhật với UserId {UserId}", userId);
                    return null;
                }

                // Cập nhật thông tin đơn vị (UserUnits) nếu có request
                // - UnitName/InstituteName là dữ liệu suy ra từ Unit/Institute, không cập nhật trực tiếp ở đây.
                var hasUnitRelatedChange =
                    updateDto.PositionId.HasValue ||
                    updateDto.InstituteId.HasValue ||
                    updateDto.JoinDate.HasValue ||
                    !string.IsNullOrWhiteSpace(updateDto.Position);

                if (hasUnitRelatedChange)
                {
                    var activeUserUnit = await _context.UserUnits
                        .Include(uu => uu.Unit)
                        .Where(uu => uu.UserID == userId && uu.Status == 1)
                        .OrderByDescending(uu => uu.JoinDate)
                        .FirstOrDefaultAsync();

                    if (updateDto.PositionId.HasValue)
                    {
                        var positionEntry = await _context.Positions
                            .AsNoTracking()
                            .FirstOrDefaultAsync(p => p.PositionID == updateDto.PositionId.Value && (p.IsActive == null || p.IsActive == 1));

                        if (positionEntry == null)
                        {
                            throw new KeyNotFoundException("Không tìm thấy Position");
                        }

                        if (updateDto.InstituteId.HasValue && positionEntry.UnitID != 0)
                        {
                            var unitInstituteId = await _context.Units
                                .Where(unit => unit.UnitID == positionEntry.UnitID)
                                .Select(unit => unit.InstituteID)
                                .FirstOrDefaultAsync();

                            if (unitInstituteId != updateDto.InstituteId.Value)
                            {
                                throw new InvalidOperationException("InstituteId không khớp với PositionId đã chọn");
                            }
                        }

                        var joinDate = updateDto.JoinDate ?? DateOnly.FromDateTime(DateTime.Today);

                        if (activeUserUnit == null)
                        {
                            var newUserUnit = new Domain.Entities.UserUnit
                            {
                                UserID = userId,
                                UnitID = positionEntry.UnitID,
                                JoinDate = joinDate,
                                PositionID = positionEntry.PositionID,
                                Position = positionEntry.PositionName,
                                Status = 1,
                                CreatedDate = DateTime.Now,
                                UpdatedDate = DateTime.Now
                            };

                            _context.UserUnits.Add(newUserUnit);
                        }
                        else if (activeUserUnit.UnitID == positionEntry.UnitID)
                        {
                            if (updateDto.JoinDate.HasValue)
                            {
                                activeUserUnit.JoinDate = joinDate;
                            }

                            activeUserUnit.PositionID = positionEntry.PositionID;
                            activeUserUnit.Position = positionEntry.PositionName;

                            activeUserUnit.UpdatedDate = DateTime.Now;
                        }
                        else
                        {
                            // Chuyển đơn vị: deactivate record cũ và tạo record mới active
                            activeUserUnit.Status = 0;
                            activeUserUnit.UpdatedDate = DateTime.Now;

                            var newUserUnit = new Domain.Entities.UserUnit
                            {
                                UserID = userId,
                                UnitID = positionEntry.UnitID,
                                JoinDate = joinDate,
                                PositionID = positionEntry.PositionID,
                                Position = positionEntry.PositionName,
                                Status = 1,
                                CreatedDate = DateTime.Now,
                                UpdatedDate = DateTime.Now
                            };

                            _context.UserUnits.Add(newUserUnit);
                        }
                    }
                    else
                    {
                        // Không đổi PositionId: chỉ cho phép cập nhật JoinDate trên unit active hiện tại
                        if (activeUserUnit == null)
                        {
                            throw new InvalidOperationException("Người dùng chưa có đơn vị active. Vui lòng cung cấp PositionId để cập nhật.");
                        }

                        if (updateDto.InstituteId.HasValue && activeUserUnit.Unit.InstituteID != updateDto.InstituteId.Value)
                        {
                            throw new InvalidOperationException("InstituteId không khớp với đơn vị hiện tại");
                        }

                        if (updateDto.JoinDate.HasValue)
                        {
                            activeUserUnit.JoinDate = updateDto.JoinDate.Value;
                        }

                        activeUserUnit.UpdatedDate = DateTime.Now;
                    }
                }

                // SECURITY: Chỉ cho phép cập nhật các trường được phép
                // KHÔNG cho phép cập nhật:
                // - Email (dùng để đăng nhập)
                // - Code (định danh bất biến)
                // - PasswordHash (sử dụng API đổi mật khẩu riêng)
                // - Status (chỉ admin được phép)
                // - Role (chỉ admin được phép)

                user.FullName = updateDto.FullName;
                user.Phone = updateDto.Phone;
                user.AvatarUrl = updateDto.AvatarUrl;
                user.Gender = updateDto.Gender;
                user.DateOfBirth = updateDto.DateOfBirth;
                user.Address = updateDto.Address;

                // Tự động cập nhật thời điểm chỉnh sửa
                user.UpdatedDate = DateTime.Now;

                // Lưu thay đổi xuống database
                await _context.SaveChangesAsync();

                _logger.LogInformation("Người dùng {UserId} đã cập nhật hồ sơ thành công", userId);

                // Trả về thông tin hồ sơ đã được cập nhật
                return await GetUserProfileAsync(userId);
            }
            catch (DbUpdateException ex)
            {
                _logger.LogError(ex, "Lỗi database khi cập nhật hồ sơ người dùng {UserId}", userId);
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật hồ sơ người dùng {UserId}", userId);
                throw;
            }
        }

        /// <summary>
        /// Đổi mật khẩu người dùng
        /// Thực hiện kiểm tra mật khẩu hiện tại, kiểm soát độ mạnh mật khẩu mới
        /// và mã hoá mật khẩu mới một cách an toàn
        /// </summary>
        /// <param name="userId">ID người dùng từ thông tin xác thực JWT</param>
        /// <param name="requestDto">Yêu cầu thay đổi mật khẩu bao gồm mật khẩu hiện tại và mật khẩu mới</param>
        /// <returns>Kết quả cho biết thành công hay thất bại kèm theo thông báo phù hợp</returns>
        public async Task<ChangePasswordResultDto> ChangePasswordAsync(int userId, ChangePasswordRequestDto requestDto)
        {
            try
            {
                _logger.LogInformation("Yêu cầu đổi mật khẩu cho UserId: {UserId}", userId);

                // 1. Tìm người dùng trong cơ sở dữ liệu
                var user = await _context.Users.FindAsync(userId);

                if (user == null)
                {
                    _logger.LogWarning("Đổi mật khẩu thất bại: Không tìm thấy UserId {UserId}", userId);
                    return new ChangePasswordResultDto
                    {
                        Success = false,
                        Message = "Người dùng không tồn tại"
                    };
                }

                // 2. SECURITY CHECK: Xác thực mật khẩu hiện tại
                // Điều này ngăn chặn việc thay đổi mật khẩu trái phép nếu ai đó truy cập vào phiên đang hoạt động
                // BCrypt.Verify so sánh mật khẩu dạng văn bản thuần với mã băm đã lưu trữ
                if (!BC.Verify(requestDto.CurrentPassword, user.PasswordHash))
                {
                    _logger.LogWarning("Thay đổi mật khẩu thất bại: Mật khẩu hiện tại không chính xác cho UserId {UserId}", userId);

                    // SECURITY: Sử dụng thông báo lỗi chung để tránh lộ thông tin
                    return new ChangePasswordResultDto
                    {
                        Success = false,
                        Message = "Mật khẩu hiện tại không đúng"
                    };
                }

                // 3. Không cho phép đặt mật khẩu mới trùng với mật khẩu cũ
                // Ngăn người dùng "thay đổi" mật khẩu
                if (BC.Verify(requestDto.NewPassword, user.PasswordHash))
                {
                    _logger.LogWarning("Thay đổi mật khẩu thất bại: Mật khẩu mới giống với mật khẩu hiện tại cho UserId {UserId}", userId);
                    return new ChangePasswordResultDto
                    {
                        Success = false,
                        Message = "Mật khẩu mới phải khác mật khẩu hiện tại"
                    };
                }

                // 4. Kiểm tra độ mạnh mật khẩu bổ sung (ngoài độ dài tối thiểu)
                var passwordValidation = ValidatePasswordStrength(requestDto.NewPassword);
                if (!passwordValidation.IsValid)
                {
                    return new ChangePasswordResultDto
                    {
                        Success = false,
                        Message = passwordValidation.ErrorMessage
                    };
                }

                // 5. Mã hoá mật khẩu mới bằng BCrypt
                // BCrypt tự động sinh và sử dụng salt
                // Hệ số work factor: 11 vòng (mặc định) – cân bằng giữa bảo mật và hiệu năng
                var newPasswordHash = BC.HashPassword(requestDto.NewPassword);

                // 6. Cập nhật mật khẩu và thời gian chỉnh sửa
                user.PasswordHash = newPasswordHash;
                user.UpdatedDate = DateTime.Now;

                var activeRefreshTokens = await _context.RefreshTokens
                    .Where(rt => rt.UserID == userId && !rt.RevokedAt.HasValue)
                    .ToListAsync();

                foreach (var refreshToken in activeRefreshTokens)
                {
                    refreshToken.RevokedAt = DateTime.Now;
                    refreshToken.RevokedReason = "password_changed";
                    refreshToken.UpdatedDate = DateTime.Now;
                }

                await _context.SaveChangesAsync();

                _logger.LogInformation("Mật khẩu đã được thay đổi thành công cho UserId: {UserId}", userId);

                // VẤN ĐỀ BẢO MẬT: Vô hiệu hóa Token
                // Token JWT hiện tại vẫn còn hiệu lực cho đến khi hết hạn
                // Để tăng cường bảo mật, hãy cân nhắc triển khai:
                // 1. Danh sách đen / danh sách thu hồi token
                // 2. Token có thời hạn ngắn kèm token làm mới
                // 3. Kiểm tra số phiên bản trong bảng người dùng trong quá trình xác thực token
                // Hiện tại, thông báo người dùng đăng nhập lại để đảm bảo an toàn

                return new ChangePasswordResultDto
                {
                    Success = true,
                    Message = "Đổi mật khẩu thành công",
                    AdditionalInfo = "Các phiên đăng nhập hiện tại đã bị thu hồi. Vui lòng đăng nhập lại bằng mật khẩu mới"
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi đổi mật khẩu cho UserId {UserId}", userId);
                throw;
            }
        }

        /// <summary>
        /// Kiểm tra độ mạnh mật khẩu vượt quá yêu cầu độ dài cơ bản
        /// Áp dụng các quy tắc bảo mật bổ sung cho mật khẩu mạnh
        /// </summary>
        /// <param name="password">Mật khẩu cần kiểm tra</param>
        /// <returns>Kết quả kiểm tra kèm thông báo lỗi nếu không hợp lệ</returns>
        private (bool IsValid, string ErrorMessage) ValidatePasswordStrength(string password)
        {
            return PasswordStrengthValidator.Validate(password);
        }

        /// <summary>
        /// Tải lên và lưu ảnh đại diện của người dùng
        /// Kiểm tra tệp, lưu trên đĩa và cập nhật cơ sở dữ liệu
        /// </summary>
        /// <param name="userId">ID người dùng lấy từ JWT claims</param>
        /// <param name="file">Tệp ảnh đại diện được tải lên</param>
        /// <param name="webRootPath">Đường dẫn vật lý tới thư mục wwwroot (từ IWebHostEnvironment)</param>
        /// <returns>Kết quả tải ảnh đại diện kèm URL công khai hoặc null nếu không tìm thấy người dùng</returns>
        public async Task<AvatarUploadResultDto?> UploadAvatarAsync(int userId, IFormFile file, string webRootPath)
        {
            try
            {
                _logger.LogInformation("Yêu cầu tải ảnh đại diện cho UserId: {UserId}, Tên tệp: {FileName}",
                    userId, file.FileName);

                // 1. ìm người dùng trong cơ sở dữ liệu
                var user = await _context.Users.FindAsync(userId);
                if (user == null)
                {
                    _logger.LogWarning("Tải ảnh đại diện thất bại: Không tìm thấy người dùng với UserId {UserId}", userId);
                    return null;
                }

                // 2. Kiểm tra tệp được tải lên
                // SECURITY: Kiểm tra toàn diện trước khi chấp nhận bất kỳ tệp nào
                var (isValid, errorMessage) = FileUploadHelper.ValidateAvatarFile(file);
                if (!isValid)
                {
                    _logger.LogWarning("Kiểm tra tải ảnh đại diện thất bại cho UserId {UserId}: {Error}",
                        userId, errorMessage);
                    throw new InvalidOperationException(errorMessage);
                }

                // 3. SECURITY: Kiểm tra chữ ký tệp (magic bytes)
                // Kiểm tra quan trọng để ngăn tải tệp độc hại giả dạng ảnh
                using (var stream = file.OpenReadStream())
                {
                    var isValidImage = await FileUploadHelper.IsValidImageFileSignature(stream);
                    if (!isValidImage)
                    {
                        _logger.LogWarning("Tải ảnh đại diện thất bại: Chữ ký tệp không hợp lệ cho UserId {UserId}", userId);
                        throw new InvalidOperationException("File không phải là ảnh hợp lệ");
                    }
                }

                // 4. Chuẩn bị lưu trữ tệp
                var extension = Path.GetExtension(file.FileName).ToLower();
                var fileName = FileUploadHelper.GenerateAvatarFileName(userId, extension);

                // SECURITY: Lưu tệp trong wwwroot/uploads/avatars/
                // Không bao giờ lưu trong thư mục mã nguồn ứng dụng
                var uploadDirectory = Path.Combine(webRootPath, "uploads", "avatars");
                FileUploadHelper.EnsureUploadDirectoryExists(uploadDirectory);

                var filePath = Path.Combine(uploadDirectory, fileName);

                // 5. Xóa ảnh đại diện cũ nếu tồn tại
                // Kiểm tra tất cả phần mở rộng có thể có
                var oldExtensions = new[] { ".jpg", ".jpeg", ".png", ".webp" };
                foreach (var oldExt in oldExtensions)
                {
                    var oldFileName = FileUploadHelper.GenerateAvatarFileName(userId, oldExt);
                    var oldFilePath = Path.Combine(uploadDirectory, oldFileName);
                    FileUploadHelper.DeleteFileIfExists(oldFilePath);
                }

                // 6. Lưu tệp ảnh đại diện mới xuống đĩa
                using (var stream = new FileStream(filePath, FileMode.Create))
                {
                    await file.CopyToAsync(stream);
                }

                _logger.LogInformation("Avatar file saved successfully: {FilePath}", filePath);

                // 7. Sinh URL công khai cho ảnh đại diện
                // SECURITY: Chỉ lưu và trả về URL công khai, không trả về đường dẫn vật lý
                var publicUrl = FileUploadHelper.GetPublicAvatarUrl(fileName);

                // 8. Cập nhật cơ sở dữ liệu với URL ảnh đại diện mới
                user.AvatarUrl = publicUrl;
                user.UpdatedDate = DateTime.Now;
                await _context.SaveChangesAsync();

                _logger.LogInformation("Tải ảnh đại diện thành công cho UserId: {UserId}, URL: {Url}",
                    userId, publicUrl);

                return new AvatarUploadResultDto
                {
                    AvatarUrl = $"{BuildFullUrl(publicUrl)}?v={DateTimeOffset.UtcNow.ToUnixTimeSeconds()}",
                    Message = "Tải ảnh đại diện thành công"
                };
            }
            catch (InvalidOperationException)
            {
                // Ném lại các ngoại lệ kiểm tra hợp lệ
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải ảnh đại diện cho người dùng {UserId}", userId);
                throw;
            }
        }

        public async Task DeleteAvatarAsync(int userId, string webRootPath, CancellationToken cancellationToken)
        {
            var user = await _context.Users.FindAsync(new object?[] { userId }, cancellationToken);
            if (user == null)
            {
                _logger.LogWarning("Không tìm thấy người dùng để xóa avatar với UserId: {UserId}", userId);
                throw new KeyNotFoundException("Không tìm thấy người dùng");
            }

            if (!string.IsNullOrEmpty(user.AvatarUrl))
            {
                var fileName = Path.GetFileName(user.AvatarUrl);
                var filePath = Path.Combine(webRootPath, "uploads", "avatars", fileName);

                if (System.IO.File.Exists(filePath))
                {
                    System.IO.File.Delete(filePath);
                }
            }

            user.AvatarUrl = null;
            user.UpdatedDate = DateTime.Now;
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Đã xóa ảnh đại diện cho UserId: {UserId}", userId);
        }

        private string? BuildFullUrl(string? relativeUrl)
        {
            return _publicUrlBuilder.BuildAbsoluteUrl(relativeUrl);
        }
    }
}

