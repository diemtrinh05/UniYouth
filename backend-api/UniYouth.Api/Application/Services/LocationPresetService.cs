using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Locations;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;

namespace UniYouth.Api.Application.Services
{
    public interface ILocationPresetService
    {
        Task<PaginatedResultDto<LocationPresetDto>> GetPresetsAsync(
            int requesterUserId,
            bool isAdmin,
            int? instituteId,
            string? q,
            bool includeInactive,
            int pageNumber,
            int pageSize,
            CancellationToken cancellationToken);
        Task<LocationPresetDto> GetPresetByIdAsync(int requesterUserId, bool isAdmin, int? scopeInstituteId, int presetId, CancellationToken cancellationToken);
        Task<LocationPresetDto> CreateAsync(int requesterUserId, bool isAdmin, int? scopeInstituteId, CreateLocationPresetRequestDto dto, CancellationToken cancellationToken);
        Task<LocationPresetDto> UpdateAsync(int requesterUserId, bool isAdmin, int? scopeInstituteId, int presetId, UpdateLocationPresetRequestDto dto, CancellationToken cancellationToken);
        Task DeleteAsync(int requesterUserId, bool isAdmin, int? scopeInstituteId, int presetId, CancellationToken cancellationToken);
    }

    public sealed class LocationPresetService : ILocationPresetService
    {
        private readonly UniYouthDbContext _context;

        public LocationPresetService(UniYouthDbContext context)
        {
            _context = context;
        }

        public async Task<PaginatedResultDto<LocationPresetDto>> GetPresetsAsync(
            int requesterUserId,
            bool isAdmin,
            int? instituteId,
            string? q,
            bool includeInactive,
            int pageNumber,
            int pageSize,
            CancellationToken cancellationToken)
        {
            q = string.IsNullOrWhiteSpace(q) ? null : q.Trim();

            if (pageNumber < 1)
            {
                pageNumber = 1;
            }

            if (pageSize is < 1 or > 200)
            {
                pageSize = 20;
            }

            var query = _context.LocationPresets.AsNoTracking().AsQueryable();

            if (!includeInactive)
            {
                query = query.Where(p => p.IsActive);
            }

            if (instituteId.HasValue)
            {
                query = query.Where(p => p.InstituteID == instituteId.Value || p.InstituteID == null);
            }

            if (q != null)
            {
                query = query.Where(p => p.Name.Contains(q) || (p.Address != null && p.Address.Contains(q)));
            }

            var totalCount = await query.CountAsync(cancellationToken);

            var items = await query
                .OrderByDescending(p => p.IsActive)
                .ThenBy(p => p.Name)
                .ThenBy(p => p.LocationPresetID)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .Select(p => ToDto(p))
                .ToListAsync(cancellationToken);

            return new PaginatedResultDto<LocationPresetDto>
            {
                Items = items,
                TotalCount = totalCount,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }

        public async Task<LocationPresetDto> GetPresetByIdAsync(
            int requesterUserId,
            bool isAdmin,
            int? scopeInstituteId,
            int presetId,
            CancellationToken cancellationToken)
        {
            var preset = await _context.LocationPresets
                .AsNoTracking()
                .FirstOrDefaultAsync(p => p.LocationPresetID == presetId, cancellationToken);

            if (preset == null)
            {
                throw new KeyNotFoundException("Không tìm thấy vị trí preset");
            }

            if (!isAdmin)
            {
                var isGlobalPreset = preset.InstituteID == null;
                var inScope = scopeInstituteId.HasValue && preset.InstituteID == scopeInstituteId.Value;

                if (!isGlobalPreset && !inScope)
                {
                    throw new UnauthorizedAccessException("Bạn không có quyền truy cập preset này");
                }
            }

            return ToDto(preset);
        }

        public async Task<LocationPresetDto> CreateAsync(
            int requesterUserId,
            bool isAdmin,
            int? scopeInstituteId,
            CreateLocationPresetRequestDto dto,
            CancellationToken cancellationToken)
        {
            var name = (dto.Name ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new InvalidOperationException("Name là bắt buộc");
            }

            if (dto.RadiusMeters.HasValue && dto.RadiusMeters.Value <= 0)
            {
                throw new InvalidOperationException("RadiusMeters không hợp lệ");
            }

            if (!isAdmin)
            {
                if (scopeInstituteId.HasValue)
                {
                    if (!dto.InstituteId.HasValue || dto.InstituteId.Value != scopeInstituteId.Value)
                    {
                        throw new UnauthorizedAccessException("Bạn chỉ được tạo preset trong viện của mình");
                    }
                }
            }

            if (dto.InstituteId.HasValue)
            {
                var instituteExists = await _context.Institutes.AnyAsync(i => i.InstituteID == dto.InstituteId.Value, cancellationToken);
                if (!instituteExists)
                {
                    throw new KeyNotFoundException("Không tìm thấy Institute");
                }
            }

            var now = DateTime.Now;
            var preset = new LocationPreset
            {
                Name = name,
                Address = string.IsNullOrWhiteSpace(dto.Address) ? null : dto.Address.Trim(),
                Latitude = dto.Latitude,
                Longitude = dto.Longitude,
                RadiusMeters = dto.RadiusMeters,
                InstituteID = dto.InstituteId,
                IsActive = dto.IsActive ?? true,
                CreatedBy = requesterUserId,
                CreatedDate = now,
                UpdatedDate = now
            };

            _context.LocationPresets.Add(preset);
            await _context.SaveChangesAsync(cancellationToken);

            return ToDto(preset);
        }

        public async Task<LocationPresetDto> UpdateAsync(
            int requesterUserId,
            bool isAdmin,
            int? scopeInstituteId,
            int presetId,
            UpdateLocationPresetRequestDto dto,
            CancellationToken cancellationToken)
        {
            var preset = await _context.LocationPresets
                .FirstOrDefaultAsync(p => p.LocationPresetID == presetId, cancellationToken);

            if (preset == null)
            {
                throw new KeyNotFoundException("Không tìm thấy vị trí preset");
            }

            if (!isAdmin)
            {
                var isGlobalPreset = preset.InstituteID == null;
                var inScope = scopeInstituteId.HasValue && preset.InstituteID == scopeInstituteId.Value;

                if (!isGlobalPreset && !inScope)
                {
                    throw new UnauthorizedAccessException("Bạn không có quyền cập nhật preset này");
                }
            }

            var name = (dto.Name ?? string.Empty).Trim();
            if (string.IsNullOrWhiteSpace(name))
            {
                throw new InvalidOperationException("Name là bắt buộc");
            }

            if (dto.RadiusMeters.HasValue && dto.RadiusMeters.Value <= 0)
            {
                throw new InvalidOperationException("RadiusMeters không hợp lệ");
            }

            if (dto.InstituteId.HasValue)
            {
                var instituteExists = await _context.Institutes.AnyAsync(i => i.InstituteID == dto.InstituteId.Value, cancellationToken);
                if (!instituteExists)
                {
                    throw new KeyNotFoundException("Không tìm thấy Institute");
                }
            }

            preset.Name = name;
            preset.Address = string.IsNullOrWhiteSpace(dto.Address) ? null : dto.Address.Trim();
            preset.Latitude = dto.Latitude;
            preset.Longitude = dto.Longitude;
            preset.RadiusMeters = dto.RadiusMeters;
            preset.InstituteID = dto.InstituteId;
            preset.IsActive = dto.IsActive ?? preset.IsActive;
            preset.UpdatedDate = DateTime.Now;

            await _context.SaveChangesAsync(cancellationToken);

            return ToDto(preset);
        }

        public async Task DeleteAsync(
            int requesterUserId,
            bool isAdmin,
            int? scopeInstituteId,
            int presetId,
            CancellationToken cancellationToken)
        {
            var preset = await _context.LocationPresets
                .FirstOrDefaultAsync(p => p.LocationPresetID == presetId, cancellationToken);

            if (preset == null)
            {
                throw new KeyNotFoundException("Không tìm thấy vị trí preset");
            }

            if (!isAdmin)
            {
                var isGlobalPreset = preset.InstituteID == null;
                var inScope = scopeInstituteId.HasValue && preset.InstituteID == scopeInstituteId.Value;

                if (!isGlobalPreset && !inScope)
                {
                    throw new UnauthorizedAccessException("Bạn không có quyền xóa preset này");
                }
            }

            _context.LocationPresets.Remove(preset);

            try
            {
                await _context.SaveChangesAsync(cancellationToken);
            }
            catch (DbUpdateException ex)
            {
                throw new InvalidOperationException("Không thể xóa vị trí preset do dữ liệu đang được sử dụng.", ex);
            }
        }

        private static LocationPresetDto ToDto(LocationPreset p)
        {
            return new LocationPresetDto
            {
                LocationPresetId = p.LocationPresetID,
                Name = p.Name,
                Address = p.Address,
                Latitude = p.Latitude,
                Longitude = p.Longitude,
                RadiusMeters = p.RadiusMeters,
                InstituteId = p.InstituteID,
                IsActive = p.IsActive,
                CreatedDate = p.CreatedDate,
                UpdatedDate = p.UpdatedDate
            };
        }
    }
}
