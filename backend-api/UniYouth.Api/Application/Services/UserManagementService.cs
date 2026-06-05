using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Users;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Constants;
using UniYouth.Api.Shared.Exceptions;
using UniYouth.Api.Shared.Helpers;

namespace UniYouth.Api.Application.Services
{
    public interface IUserManagementService
    {
        Task<int> CreateUserAsync(CreateUserRequestDto requestDto, CancellationToken cancellationToken = default);
        Task<AdminUserDetailDto> UpdateUserAsync(int userId, UpdateAdminUserRequestDto requestDto, CancellationToken cancellationToken = default);
        Task UpdateUserRolesAsync(int userId, UpdateUserRolesRequestDto requestDto, CancellationToken cancellationToken = default);
        Task UpdateUserStatusAsync(int userId, UpdateUserStatusRequestDto requestDto, CancellationToken cancellationToken = default);
        Task<PaginatedResultDto<AdminUserListItemDto>> GetUsersAsync(int pageNumber, int pageSize, string? search, int? status, string? role, CancellationToken cancellationToken = default);
        Task<AdminUserDetailDto> GetUserDetailAsync(int userId, CancellationToken cancellationToken = default);
    }

    public class UserManagementService : IUserManagementService
    {
        private readonly UniYouthDbContext _context;
        private readonly IPublicUrlBuilder _publicUrlBuilder;

        public UserManagementService(
            UniYouthDbContext context,
            IPublicUrlBuilder publicUrlBuilder)
        {
            _context = context;
            _publicUrlBuilder = publicUrlBuilder;
        }

        public async Task<int> CreateUserAsync(CreateUserRequestDto requestDto, CancellationToken cancellationToken = default)
        {
            var email = (requestDto.Email ?? string.Empty).Trim();
            var code = (requestDto.Code ?? string.Empty).Trim();
            var fullName = (requestDto.FullName ?? string.Empty).Trim();
            var phone = string.IsNullOrWhiteSpace(requestDto.Phone) ? null : requestDto.Phone.Trim();

            if (string.IsNullOrWhiteSpace(email))
            {
                throw new InvalidOperationException("Email là bắt buộc");
            }

            if (string.IsNullOrWhiteSpace(code))
            {
                throw new InvalidOperationException("Code là bắt buộc");
            }

            if (string.IsNullOrWhiteSpace(fullName))
            {
                throw new InvalidOperationException("FullName là bắt buộc");
            }

            var roleNames = (requestDto.Roles ?? new List<string>())
                .Where(r => !string.IsNullOrWhiteSpace(r))
                .Select(r => r.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            if (!roleNames.Any())
            {
                throw new InvalidOperationException("Cần ít nhất 1 role");
            }

            var emailExists = await _context.Users.AnyAsync(u => u.Email == email, cancellationToken);
            if (emailExists)
            {
                throw new InvalidOperationException("Email đã tồn tại");
            }

            var codeExists = await _context.Users.AnyAsync(u => u.Code == code, cancellationToken);
            if (codeExists)
            {
                throw new InvalidOperationException("Code đã tồn tại");
            }

            var roles = await _context.Roles
                .Where(r => roleNames.Contains(r.RoleName))
                .ToListAsync(cancellationToken);

            var missingRoles = roleNames
                .Except(roles.Select(r => r.RoleName), StringComparer.OrdinalIgnoreCase)
                .ToList();

            if (missingRoles.Any())
            {
                throw new InvalidOperationException($"Role không tồn tại: {string.Join(", ", missingRoles)}");
            }

            var selectedPosition = await _context.Positions
                .AsNoTracking()
                .FirstOrDefaultAsync(
                    p => p.PositionID == requestDto.PositionId && (p.IsActive == null || p.IsActive == 1),
                    cancellationToken);

            if (selectedPosition == null)
            {
                throw new KeyNotFoundException("Không tìm thấy Position");
            }
            var executionStrategy = _context.Database.CreateExecutionStrategy();

            var createdUserId = 0;
            await executionStrategy.ExecuteAsync(async () =>
            {
                await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);
                try
                {
                    _context.ChangeTracker.Clear();

                    // Mật khẩu khởi tạo: dùng Code theo yêu cầu nghiệp vụ hiện tại.
                    // LƯU Ý: Code có thể dễ đoán -> cân nhắc yêu cầu user đổi mật khẩu sau khi đăng nhập lần đầu.
                    var initialPassword = code;

                    var user = new Domain.Entities.User
                    {
                        Code = code,
                        FullName = fullName,
                        Email = email,
                    Phone = phone,
                    Gender = requestDto.Gender,
                    DateOfBirth = requestDto.DateOfBirth,
                    // Trạng thái khởi tạo: 0 (chưa kích hoạt). Sẽ tự kích hoạt (=1) khi đăng nhập lần đầu.
                    Status = 0,
                    PasswordHash = PasswordHelper.HashPassword(initialPassword),
                    CreatedDate = DateTime.Now,
                    UpdatedDate = DateTime.Now
                };

                    _context.Users.Add(user);
                    await _context.SaveChangesAsync(cancellationToken);

                    var joinDate = requestDto.JoinDate ?? DateOnly.FromDateTime(DateTime.Now);

                    _context.UserUnits.Add(new Domain.Entities.UserUnit
                    {
                        UserID = user.UserID,
                        UnitID = selectedPosition.UnitID,
                        JoinDate = joinDate,
                        PositionID = selectedPosition.PositionID,
                        Position = selectedPosition.PositionName,
                        Status = 1,
                        CreatedDate = DateTime.Now,
                        UpdatedDate = DateTime.Now
                    });

                    foreach (var role in roles)
                    {
                        _context.UserRoles.Add(new Domain.Entities.UserRole
                        {
                            UserID = user.UserID,
                            RoleID = role.RoleID,
                            AssignDate = DateTime.Now
                        });
                    }

                    await _context.SaveChangesAsync(cancellationToken);
                    await tx.CommitAsync(cancellationToken);

                    createdUserId = user.UserID;
                }
                catch
                {
                    await tx.RollbackAsync(cancellationToken);
                    throw;
                }
            });

            return createdUserId;
        }

        public async Task<AdminUserDetailDto> UpdateUserAsync(
            int userId,
            UpdateAdminUserRequestDto requestDto,
            CancellationToken cancellationToken = default)
        {
            var email = (requestDto.Email ?? string.Empty).Trim();
            var fullName = (requestDto.FullName ?? string.Empty).Trim();
            var phone = string.IsNullOrWhiteSpace(requestDto.Phone) ? null : requestDto.Phone.Trim();
            var address = string.IsNullOrWhiteSpace(requestDto.Address) ? null : requestDto.Address.Trim();
            if (string.IsNullOrWhiteSpace(email))
            {
                throw new InvalidOperationException("Email là bắt buộc");
            }

            if (string.IsNullOrWhiteSpace(fullName))
            {
                throw new InvalidOperationException("FullName là bắt buộc");
            }

            if (requestDto.PositionId.HasValue && requestDto.PositionId.Value <= 0)
            {
                throw new InvalidOperationException("PositionId không hợp lệ");
            }

            Domain.Entities.Position? targetPosition = null;
            if (requestDto.PositionId.HasValue)
            {
                targetPosition = await _context.Positions
                    .AsNoTracking()
                    .FirstOrDefaultAsync(
                        p => p.PositionID == requestDto.PositionId.Value && (p.IsActive == null || p.IsActive == 1),
                        cancellationToken);

                if (targetPosition == null)
                {
                    throw new KeyNotFoundException("Không tìm thấy Position");
                }
            }

            var executionStrategy = _context.Database.CreateExecutionStrategy();
            await executionStrategy.ExecuteAsync(async () =>
            {
                await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);
                try
                {
                    _context.ChangeTracker.Clear();

                    var user = await _context.Users
                        .AsSplitQuery()
                        .Include(u => u.UserRoles)
                            .ThenInclude(ur => ur.Role)
                        .Include(u => u.UserUnits)
                            .ThenInclude(uu => uu.Unit)
                                .ThenInclude(unit => unit.Institute)
                        .FirstOrDefaultAsync(u => u.UserID == userId, cancellationToken);

                    if (user == null)
                    {
                        throw new KeyNotFoundException("Không tìm thấy user");
                    }

                    if (!string.Equals(user.Email, email, StringComparison.OrdinalIgnoreCase))
                    {
                        var emailExists = await _context.Users
                            .AnyAsync(u => u.Email == email && u.UserID != userId, cancellationToken);

                        if (emailExists)
                        {
                            throw new InvalidOperationException("Email đã tồn tại");
                        }
                    }

                    user.FullName = fullName;
                    user.Email = email;
                    user.Phone = phone;
                    user.Gender = requestDto.Gender;
                    user.DateOfBirth = requestDto.DateOfBirth;
                    user.Address = address;
                    user.UpdatedDate = DateTime.Now;

                    var activeUserUnit = user.UserUnits
                        .Where(uu => uu.Status == 1)
                        .OrderByDescending(uu => uu.JoinDate)
                        .FirstOrDefault();

                    if (targetPosition != null)
                    {
                        var targetUnitId = targetPosition.UnitID;

                        if (activeUserUnit == null)
                        {
                            _context.UserUnits.Add(new Domain.Entities.UserUnit
                            {
                                UserID = user.UserID,
                                UnitID = targetUnitId,
                                JoinDate = requestDto.JoinDate ?? DateOnly.FromDateTime(DateTime.Now),
                                PositionID = targetPosition.PositionID,
                                Position = targetPosition.PositionName,
                                Status = 1,
                                CreatedDate = DateTime.Now,
                                UpdatedDate = DateTime.Now
                            });
                        }
                        else if (activeUserUnit.UnitID == targetUnitId)
                        {
                            if (requestDto.JoinDate.HasValue)
                            {
                                activeUserUnit.JoinDate = requestDto.JoinDate.Value;
                            }

                            activeUserUnit.PositionID = targetPosition.PositionID;
                            activeUserUnit.Position = targetPosition.PositionName;
                            activeUserUnit.UpdatedDate = DateTime.Now;
                        }
                        else
                        {
                            var activeUnits = user.UserUnits.Where(uu => uu.Status == 1).ToList();
                            foreach (var active in activeUnits)
                            {
                                active.Status = 0;
                                active.UpdatedDate = DateTime.Now;
                            }

                            _context.UserUnits.Add(new Domain.Entities.UserUnit
                            {
                                UserID = user.UserID,
                                UnitID = targetUnitId,
                                JoinDate = requestDto.JoinDate ?? DateOnly.FromDateTime(DateTime.Now),
                                PositionID = targetPosition.PositionID,
                                Position = targetPosition.PositionName,
                                Status = 1,
                                CreatedDate = DateTime.Now,
                                UpdatedDate = DateTime.Now
                            });
                        }
                    }

                    await _context.SaveChangesAsync(cancellationToken);
                    await tx.CommitAsync(cancellationToken);
                }
                catch
                {
                    await tx.RollbackAsync(cancellationToken);
                    throw;
                }
            });

            return await GetUserDetailAsync(userId, cancellationToken);
        }

        public async Task UpdateUserRolesAsync(int userId, UpdateUserRolesRequestDto requestDto, CancellationToken cancellationToken = default)
        {
            var roleNames = (requestDto.Roles ?? new List<string>())
                .Where(r => !string.IsNullOrWhiteSpace(r))
                .Select(r => r.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            if (!roleNames.Any())
            {
                throw new InvalidOperationException("Cần ít nhất 1 role");
            }

            var executionStrategy = _context.Database.CreateExecutionStrategy();
            await executionStrategy.ExecuteAsync(async () =>
            {
                await using var tx = await _context.Database.BeginTransactionAsync(cancellationToken);
                try
                {
                    _context.ChangeTracker.Clear();

                    var user = await _context.Users
                        .Include(u => u.UserRoles)
                        .FirstOrDefaultAsync(u => u.UserID == userId, cancellationToken);

                    if (user == null)
                    {
                        throw new KeyNotFoundException("Không tìm thấy user");
                    }

                    var roles = await _context.Roles
                        .Where(r => roleNames.Contains(r.RoleName))
                        .ToListAsync(cancellationToken);

                    var missingRoles = roleNames
                        .Except(roles.Select(r => r.RoleName), StringComparer.OrdinalIgnoreCase)
                        .ToList();

                    if (missingRoles.Any())
                    {
                        throw new InvalidOperationException($"Role không tồn tại: {string.Join(", ", missingRoles)}");
                    }

                    var adminRoleId = await GetAdminRoleIdAsync(cancellationToken);
                    var desiredRoleIds = roles.Select(r => r.RoleID).ToHashSet();

                    var isRemovingAdminFromThisUser =
                        user.UserRoles.Any(ur => ur.RoleID == adminRoleId) && !desiredRoleIds.Contains(adminRoleId);

                    if (isRemovingAdminFromThisUser)
                    {
                        await EnsureNotRemovingLastAdminAsync(userId, adminRoleId, cancellationToken);
                    }

                    var currentRoleIds = user.UserRoles.Select(ur => ur.RoleID).ToHashSet();

                    var toRemove = user.UserRoles.Where(ur => !desiredRoleIds.Contains(ur.RoleID)).ToList();
                    if (toRemove.Any())
                    {
                        _context.UserRoles.RemoveRange(toRemove);
                    }

                    var toAdd = desiredRoleIds.Except(currentRoleIds).ToList();
                    foreach (var roleId in toAdd)
                    {
                        _context.UserRoles.Add(new Domain.Entities.UserRole
                        {
                            UserID = userId,
                            RoleID = roleId,
                            AssignDate = DateTime.Now
                        });
                    }

                    await _context.SaveChangesAsync(cancellationToken);
                    await tx.CommitAsync(cancellationToken);
                }
                catch
                {
                    await tx.RollbackAsync(cancellationToken);
                    throw;
                }
            });
        }

        public async Task UpdateUserStatusAsync(int userId, UpdateUserStatusRequestDto requestDto, CancellationToken cancellationToken = default)
        {
            if (requestDto.Status is not (0 or 1))
            {
                throw new InvalidOperationException("Status chỉ hợp lệ 0 hoặc 1");
            }

            var user = await _context.Users
                .Include(u => u.UserRoles)
                .FirstOrDefaultAsync(u => u.UserID == userId, cancellationToken);

            if (user == null)
            {
                throw new KeyNotFoundException("Không tìm thấy user");
            }

            if (requestDto.Status == 0)
            {
                var adminRoleId = await GetAdminRoleIdAsync(cancellationToken);
                var isAdmin = user.UserRoles.Any(ur => ur.RoleID == adminRoleId);
                if (isAdmin)
                {
                    await EnsureNotRemovingLastAdminAsync(userId, adminRoleId, cancellationToken);
                }
            }

            user.Status = (byte)requestDto.Status;
            user.UpdatedDate = DateTime.Now;
            await _context.SaveChangesAsync(cancellationToken);
        }

        public async Task<PaginatedResultDto<AdminUserListItemDto>> GetUsersAsync(
            int pageNumber,
            int pageSize,
            string? search,
            int? status,
            string? role,
            CancellationToken cancellationToken = default)
        {
            if (pageNumber < 1)
            {
                throw new InvalidOperationException("PageNumber phải >= 1");
            }

            if (pageSize is < 1 or > 200)
            {
                throw new InvalidOperationException("PageSize phải trong khoảng 1..200");
            }

            search = string.IsNullOrWhiteSpace(search) ? null : search.Trim();
            role = string.IsNullOrWhiteSpace(role) ? null : role.Trim();

            if (status.HasValue && status.Value is not (0 or 1))
            {
                throw new InvalidOperationException("Status chỉ hợp lệ 0 hoặc 1");
            }

            var query = _context.Users
                .AsNoTracking()
                .AsSplitQuery()
                .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                .Include(u => u.UserUnits.Where(uu => uu.Status == 1))
                    .ThenInclude(uu => uu.Unit)
                        .ThenInclude(unit => unit.Institute)
                .AsQueryable();

            if (search != null)
            {
                query = query.Where(u =>
                    u.Email.StartsWith(search) ||
                    u.FullName.Contains(search) ||
                    u.Code.StartsWith(search));
            }

            if (status.HasValue)
            {
                var statusValue = (byte)status.Value;
                query = query.Where(u => u.Status == statusValue);
            }

            if (role != null)
            {
                query = query.Where(u => u.UserRoles.Any(ur => ur.Role.RoleName == role));
            }

            var totalCount = await query.CountAsync(cancellationToken);

            var users = await query
                .OrderByDescending(u => u.UserID)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync(cancellationToken);

            var items = users.Select(u =>
            {
                var activeUserUnit = u.UserUnits
                    .Where(uu => uu.Status == 1)
                    .OrderByDescending(uu => uu.JoinDate)
                    .FirstOrDefault();

                return new AdminUserListItemDto
                {
                    UserId = u.UserID,
                    Code = u.Code,
                    FullName = u.FullName,
                    Email = u.Email,
                    Phone = u.Phone,
                    Status = u.Status,
                    Roles = u.UserRoles
                        .Select(ur => ur.Role.RoleName)
                        .Distinct(StringComparer.OrdinalIgnoreCase)
                        .ToList(),
                    UnitId = activeUserUnit?.UnitID,
                    UnitName = activeUserUnit?.Unit.UnitName,
                    InstituteId = activeUserUnit?.Unit.InstituteID,
                    InstituteName = activeUserUnit?.Unit.Institute?.InstituteName,
                    LastLoginDate = u.LastLoginDate,
                    CreatedDate = u.CreatedDate
                };
            }).ToList();

            return new PaginatedResultDto<AdminUserListItemDto>
            {
                Items = items,
                TotalCount = totalCount,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }

        public async Task<AdminUserDetailDto> GetUserDetailAsync(int userId, CancellationToken cancellationToken = default)
        {
            var user = await _context.Users
                .AsNoTracking()
                .AsSplitQuery()
                .Include(u => u.UserRoles)
                    .ThenInclude(ur => ur.Role)
                .Include(u => u.UserUnits.Where(uu => uu.Status == 1))
                    .ThenInclude(uu => uu.Unit)
                        .ThenInclude(unit => unit.Institute)
                .FirstOrDefaultAsync(u => u.UserID == userId, cancellationToken);

            if (user == null)
            {
                throw new KeyNotFoundException("Không tìm thấy user");
            }

            var activeUserUnit = user.UserUnits
                .Where(uu => uu.Status == 1)
                .OrderByDescending(uu => uu.JoinDate)
                .FirstOrDefault();

            return new AdminUserDetailDto
            {
                UserId = user.UserID,
                Code = user.Code,
                FullName = user.FullName,
                Email = user.Email,
                Phone = user.Phone,
                AvatarUrl = BuildFullUrl(user.AvatarUrl),
                Gender = user.Gender,
                DateOfBirth = user.DateOfBirth,
                Address = user.Address,
                Status = user.Status,
                Roles = user.UserRoles
                    .Select(ur => ur.Role.RoleName)
                    .Distinct(StringComparer.OrdinalIgnoreCase)
                    .ToList(),
                UnitId = activeUserUnit?.UnitID,
                UnitName = activeUserUnit?.Unit.UnitName,
                InstituteId = activeUserUnit?.Unit.InstituteID,
                InstituteName = activeUserUnit?.Unit.Institute?.InstituteName,
                JoinDate = activeUserUnit?.JoinDate,
                PositionId = activeUserUnit?.PositionID,
                Position = activeUserUnit?.Position,
                LastLoginDate = user.LastLoginDate,
                CreatedDate = user.CreatedDate,
                UpdatedDate = user.UpdatedDate
            };
        }

        private string? BuildFullUrl(string? relativeUrl)
        {
            return _publicUrlBuilder.BuildAbsoluteUrl(relativeUrl);
        }

        private async Task<int> GetAdminRoleIdAsync(CancellationToken cancellationToken)
        {
            var adminRoleId = await _context.Roles
                .Where(r => r.RoleName == RoleNames.Admin)
                .Select(r => r.RoleID)
                .FirstOrDefaultAsync(cancellationToken);

            if (adminRoleId == 0)
            {
                throw new InvalidOperationException("Role Admin chưa tồn tại trong hệ thống");
            }

            return adminRoleId;
        }

        private async Task EnsureNotRemovingLastAdminAsync(int userId, int adminRoleId, CancellationToken cancellationToken)
        {
            var adminUserCount = await _context.UserRoles
                .Where(ur => ur.RoleID == adminRoleId)
                .Select(ur => ur.UserID)
                .Distinct()
                .CountAsync(cancellationToken);

            if (adminUserCount <= 1)
            {
                throw new ConflictException("Không thể xoá/vô hiệu hoá Admin cuối cùng của hệ thống");
            }
        }

    }
}




