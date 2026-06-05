using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Domain.Entities;

namespace UniYouth.Api.Infrastructure.Data;

public partial class UniYouthDbContext
{
    public virtual DbSet<LocationPreset> LocationPresets { get; set; }
}
