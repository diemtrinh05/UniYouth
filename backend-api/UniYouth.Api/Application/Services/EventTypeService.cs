using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Events;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Exceptions;

namespace UniYouth.Api.Application.Services
{
    public interface IEventTypeService
    {
        Task<List<EventTypeDto>> GetEventTypesAsync(CancellationToken cancellationToken = default);
        Task<int> CreateEventTypeAsync(CreateEventTypeRequestDto requestDto, CancellationToken cancellationToken = default);
        Task UpdateEventTypeAsync(int typeId, UpdateEventTypeRequestDto requestDto, CancellationToken cancellationToken = default);
        Task DeleteEventTypeAsync(int typeId, CancellationToken cancellationToken = default);
    }

    public class EventTypeService : IEventTypeService
    {
        private readonly UniYouthDbContext _context;
        private readonly ILogger<EventTypeService> _logger;

        public EventTypeService(UniYouthDbContext context, ILogger<EventTypeService> logger)
        {
            _context = context;
            _logger = logger;
        }

        public async Task<List<EventTypeDto>> GetEventTypesAsync(CancellationToken cancellationToken = default)
        {
            var list = await _context.EventTypes
                .AsNoTracking()
                .OrderBy(et => et.TypeName)
                .Select(et => new EventTypeDto
                {
                    TypeId = et.TypeID,
                    TypeName = et.TypeName,
                    Description = et.Description
                })
                .ToListAsync(cancellationToken);

            return list;
        }

        public async Task<int> CreateEventTypeAsync(CreateEventTypeRequestDto requestDto, CancellationToken cancellationToken = default)
        {
            var typeName = (requestDto.TypeName ?? string.Empty).Trim();
            var description = string.IsNullOrWhiteSpace(requestDto.Description) ? null : requestDto.Description.Trim();

            if (string.IsNullOrWhiteSpace(typeName))
            {
                throw new InvalidOperationException("TypeName là bắt buộc");
            }

            var exists = await _context.EventTypes.AnyAsync(et => et.TypeName == typeName, cancellationToken);
            if (exists)
            {
                throw new InvalidOperationException("TypeName đã tồn tại");
            }

            var entity = new Domain.Entities.EventType
            {
                TypeName = typeName,
                Description = description,
                CreatedDate = DateTime.Now
            };

            _context.EventTypes.Add(entity);
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Đã tạo EventType {TypeId} - {TypeName}", entity.TypeID, entity.TypeName);

            return entity.TypeID;
        }

        public async Task UpdateEventTypeAsync(int typeId, UpdateEventTypeRequestDto requestDto, CancellationToken cancellationToken = default)
        {
            var typeName = (requestDto.TypeName ?? string.Empty).Trim();
            var description = string.IsNullOrWhiteSpace(requestDto.Description) ? null : requestDto.Description.Trim();

            if (string.IsNullOrWhiteSpace(typeName))
            {
                throw new InvalidOperationException("TypeName là bắt buộc");
            }

            var entity = await _context.EventTypes.FirstOrDefaultAsync(et => et.TypeID == typeId, cancellationToken);
            if (entity == null)
            {
                throw new KeyNotFoundException("Không tìm thấy loại sự kiện");
            }

            var duplicatedName = await _context.EventTypes
                .AnyAsync(et => et.TypeID != typeId && et.TypeName == typeName, cancellationToken);

            if (duplicatedName)
            {
                throw new InvalidOperationException("TypeName đã tồn tại");
            }

            entity.TypeName = typeName;
            entity.Description = description;

            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Đã cập nhật EventType {TypeId}", typeId);
        }

        public async Task DeleteEventTypeAsync(int typeId, CancellationToken cancellationToken = default)
        {
            var entity = await _context.EventTypes.FirstOrDefaultAsync(et => et.TypeID == typeId, cancellationToken);
            if (entity == null)
            {
                throw new KeyNotFoundException("Không tìm thấy loại sự kiện");
            }

            var isUsed = await _context.Events.AnyAsync(e => e.EventTypeID == typeId, cancellationToken);
            if (isUsed)
            {
                throw new ConflictException("Loại sự kiện đang được sử dụng, không thể xoá");
            }

            _context.EventTypes.Remove(entity);
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation("Đã xoá EventType {TypeId}", typeId);
        }
    }
}
