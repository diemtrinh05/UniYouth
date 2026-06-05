using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Units;
using UniYouth.Api.Infrastructure.Data;

namespace UniYouth.Api.Application.Services
{
    public interface IUnitLookupService
    {
        Task<IReadOnlyList<UnitOptionDto>> GetUnitsAsync(bool activeOnly = true, CancellationToken cancellationToken = default);
    }

    public class UnitLookupService : IUnitLookupService
    {
        private readonly UniYouthDbContext _context;

        public UnitLookupService(UniYouthDbContext context)
        {
            _context = context;
        }

        public async Task<IReadOnlyList<UnitOptionDto>> GetUnitsAsync(bool activeOnly = true, CancellationToken cancellationToken = default)
        {
            var query = _context.Units
                .AsNoTracking()
                .Include(u => u.Institute)
                .AsQueryable();

            if (activeOnly)
            {
                query = query.Where(u => u.Status == null || u.Status == 1);
            }

            return await query
                .OrderBy(u => u.Institute.InstituteName)
                .ThenBy(u => u.UnitName)
                .Select(u => new UnitOptionDto
                {
                    UnitId = u.UnitID,
                    UnitName = u.UnitName,
                    UnitType = u.UnitType,
                    InstituteId = u.InstituteID,
                    InstituteName = u.Institute != null ? u.Institute.InstituteName : null,
                    Status = u.Status
                })
                .ToListAsync(cancellationToken);
        }
    }
}
