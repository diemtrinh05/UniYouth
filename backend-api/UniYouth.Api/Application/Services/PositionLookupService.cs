using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Positions;
using UniYouth.Api.Infrastructure.Data;

namespace UniYouth.Api.Application.Services
{
    public interface IPositionLookupService
    {
        Task<IReadOnlyList<PositionOptionDto>> GetPositionsAsync(bool activeOnly = true, CancellationToken cancellationToken = default);
        Task<PositionOptionDto?> GetPositionByIdAsync(int positionId, CancellationToken cancellationToken = default);
    }

    public class PositionLookupService : IPositionLookupService
    {
        private readonly UniYouthDbContext _context;

        public PositionLookupService(UniYouthDbContext context)
        {
            _context = context;
        }

        public async Task<IReadOnlyList<PositionOptionDto>> GetPositionsAsync(bool activeOnly = true, CancellationToken cancellationToken = default)
        {
            var query = _context.Positions
                .AsNoTracking()
                .Include(position => position.Unit)
                    .ThenInclude(unit => unit.Institute)
                .AsQueryable();

            if (activeOnly)
            {
                query = query.Where(position => position.IsActive == null || position.IsActive == 1);
            }

            return await query
                .OrderBy(position => position.Unit.Institute.InstituteName)
                .ThenBy(position => position.Unit.UnitName)
                .ThenBy(position => position.SortOrder ?? int.MaxValue)
                .ThenBy(position => position.PositionName)
                .Select(position => new PositionOptionDto
                {
                    PositionId = position.PositionID,
                    PositionCode = position.PositionCode,
                    PositionName = position.PositionName,
                    UnitId = position.UnitID,
                    UnitName = position.Unit.UnitName,
                    InstituteId = position.Unit.InstituteID,
                    InstituteName = position.Unit.Institute != null ? position.Unit.Institute.InstituteName : null,
                    IsActive = position.IsActive,
                    SortOrder = position.SortOrder ?? 0
                })
                .ToListAsync(cancellationToken);
        }

        public async Task<PositionOptionDto?> GetPositionByIdAsync(int positionId, CancellationToken cancellationToken = default)
        {
            return await _context.Positions
                .AsNoTracking()
                .Include(position => position.Unit)
                    .ThenInclude(unit => unit.Institute)
                .Where(position => position.PositionID == positionId)
                .Select(position => new PositionOptionDto
                {
                    PositionId = position.PositionID,
                    PositionCode = position.PositionCode,
                    PositionName = position.PositionName,
                    UnitId = position.UnitID,
                    UnitName = position.Unit.UnitName,
                    InstituteId = position.Unit.InstituteID,
                    InstituteName = position.Unit.Institute != null ? position.Unit.Institute.InstituteName : null,
                    IsActive = position.IsActive,
                    SortOrder = position.SortOrder ?? 0
                })
                .FirstOrDefaultAsync(cancellationToken);
        }
    }
}
