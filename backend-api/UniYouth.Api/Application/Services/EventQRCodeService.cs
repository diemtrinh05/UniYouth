using System.Security.Cryptography;
using Microsoft.AspNetCore.Hosting.Server;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Events.Qr;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Enums;
using UniYouth.Api.Shared.Extensions;
using UniYouth.Api.Shared.Helpers;

namespace UniYouth.Api.Application.Services
{
    public interface IEventQRCodeService
    {
        Task<EventQrResponseDto> GenerateQRCodeAsync(int eventId, GenerateEventQrRequestDto request, int createdBy, int? unitId = null, int? instituteId = null);
        Task<PaginatedResultDto<EventQrListItemDto>> GetEventQRCodesAsync(int eventId, GetEventQRCodesQueryDto query, int? unitId = null, int? instituteId = null);
        Task<DeactivateQrResponseDto> DeactivateQRCodeAsync(int qrId, int userId, int? unitId = null, int? instituteId = null);
        Task<QrCodeDetailResponseDto> GetQRCodeDetailAsync(int qrId, int requesterUserId, bool isAdmin, CancellationToken cancellationToken = default);
    }
    /// <summary>
    /// Service xử lý toàn bộ nghiệp vụ liên quan đến mã QR của sự kiện.
    /// 
    /// Bao gồm:
    /// - Tạo mới QR code
    /// - Lấy danh sách QR code của sự kiện
    /// - Vô hiệu hóa QR code thủ công
    /// 
    /// TẤT CẢ business logic đều phải nằm ở lớp này,
    /// Controller chỉ đóng vai trò điều phối request/response.
    /// </summary>
    public class EventQRCodeService : IEventQRCodeService
    {
        private readonly UniYouthDbContext _context;
        private readonly INotificationService _notificationService;
        private readonly ILogger<EventQRCodeService> _logger;

        public EventQRCodeService(
            UniYouthDbContext context,
            INotificationService notificationService,
            ILogger<EventQRCodeService> logger)
        {
            _context = context;
            _notificationService = notificationService;
            _logger = logger;
        }

        /// <summary>
        /// Tạo QR code mới cho sự kiện
        /// 
        /// WHY ONLY ONE ACTIVE QR PER EVENT:
        /// - Tránh nhầm lẫn khi sinh viên quét QR (không biết quét cái nào)
        /// - Đơn giản hóa quản lý (CanBo chỉ cần theo dõi 1 QR)
        /// - Tăng bảo mật (giảm số QR token có thể bị lộ)
        /// - Dễ dàng thu hồi quyền truy cập (deactivate 1 QR là xong)
        /// 
        /// SECURITY CONSIDERATIONS:
        /// - QRToken được tạo bằng cryptographically secure random
        /// - Token dài 64 ký tự (256 bits entropy)
        /// - Kiểm tra uniqueness trong database
        /// - Tự động deactivate QR cũ trước khi tạo mới
        /// </summary>
        public async Task<EventQrResponseDto> GenerateQRCodeAsync(
            int eventId,
            GenerateEventQrRequestDto request,
            int createdBy,
            int? unitId = null,
            int? instituteId = null)
        {
            // 1. Kiểm tra khoảng thời gian hiệu lực
            if (request.ValidUntil <= request.ValidFrom)
            {
                throw new InvalidOperationException("Thời điểm hết hạn phải sau thời điểm bắt đầu hiệu lực của mã QR");
            }

            // 2. Kiểm tra sự kiện tồn tại
            var eventEntity = await _context.Events
                .Where(e => e.EventID == eventId)
                .FirstOrDefaultAsync();

            if (eventEntity == null)
            {
                throw new KeyNotFoundException($"Không tìm thấy sự kiện với ID {eventId}");
            }

            // Kiểm tra trạng thái sự kiện (chỉ cho phép Open hoặc Ongoing)
            if ((EventStatus?)eventEntity.Status != EventStatus.Open &&
                (EventStatus?)eventEntity.Status != EventStatus.Ongoing)
            {
                throw new InvalidOperationException("Chỉ có thể tạo QR code cho sự kiện đang mở hoặc đang diễn ra");
            }

            // Data-level authorization: CanBo chỉ được thao tác event thuộc viện/đơn vị của mình
            var scopeInstituteId = await ResolveInstituteScopeAsync(instituteId, unitId);
            if (scopeInstituteId.HasValue && eventEntity.InstituteID != scopeInstituteId.Value)
            {
                throw new UnauthorizedAccessException("Bạn không có quyền quản lý QR của sự kiện thuộc viện khác");
            }

            //Sử dụng ExecutionStrategy để tránh lỗi trong môi trường có retry(SQL Server)
            var strategy = _context.Database.CreateExecutionStrategy();

            return await strategy.ExecuteAsync(async () =>
            {
                using var transaction = await _context.Database.BeginTransactionAsync();

                try
                {
                    // 3. Vô hiệu hóa các QR code đang active trước đó (nếu có)
                    // Chỉ cho phép 1 QR active tại một thời điểm
                    var existingActiveQRs = await _context.EventQRCodes
                        .Where(qr => qr.EventID == eventId && qr.IsActive == true)
                        .ToListAsync();

                    if (existingActiveQRs.Any())
                    {
                        _logger.LogInformation(
                            "Phát hiện {Count} QR code đang hoạt động, tiến hành vô hiệu hóa trước khi tạo mới",
                            existingActiveQRs.Count);

                        foreach (var qr in existingActiveQRs)
                        {
                            qr.IsActive = false;
                            qr.UpdatedDate = DateTime.Now;
                        }

                        _context.EventQRCodes.UpdateRange(existingActiveQRs);
                    }

                    // 4. Sinh QR token bảo mật
                    // Sử dụng cryptographically secure random number generator
                    string qrToken = GenerateSecureToken();

                    // 5. Đảm bảo token là duy nhất (xử lý collision cực hiếm)
                    // Trong trường hợp cực kỳ hiếm có collision, retry
                    int retryCount = 0;
                    while (await _context.EventQRCodes.AnyAsync(qr => qr.QRToken == qrToken) && retryCount < 3)
                    {
                        qrToken = GenerateSecureToken();
                        retryCount++;
                        _logger.LogWarning("QR Token collision detected, regenerating... (attempt {Count})", retryCount);
                    }

                    if (retryCount >= 3)
                    {
                        throw new InvalidOperationException("Không thể tạo QR token duy nhất sau 3 lần thử");
                    }

                    // 6. Tạo QR code mới
                    var newQRCode = new EventQRCode
                    {
                        EventID = eventId,
                        QRToken = qrToken,
                        ValidFrom = DateTimeHelper.FromVietnamTimeToUtc(request.ValidFrom),
                        ValidUntil = DateTimeHelper.FromVietnamTimeToUtc(request.ValidUntil),
                        IsActive = true,
                        ScanLimit = request.ScanLimit,
                        CurrentScans = 0,
                        CreatedBy = createdBy,
                        CreatedDate = DateTime.Now,
                        UpdatedDate = DateTime.Now
                    };

                    _context.EventQRCodes.Add(newQRCode);

                    // 7. Lưu thay đổi
                    try
                    {
                        await _context.SaveChangesAsync();
                        await transaction.CommitAsync();
                    }
                    catch (DbUpdateException ex) when (IsOneActiveQrPerEventConflict(ex))
                    {
                        await transaction.RollbackAsync();

                        // Race condition: có request khác vừa tạo QR active cho event này
                        throw new InvalidOperationException(
                            "Sự kiện hiện đã có mã QR đang hoạt động. Vui lòng tải lại danh sách QR và thử lại.");
                    }

                    _logger.LogInformation(
                        "QR code mới đã được tạo cho Event {EventId} bởi User {UserId}. " +
                        "Hiệu lực từ {ValidFrom} đến {ValidUntil}",
                        eventId, createdBy, request.ValidFrom, request.ValidUntil);

                    // 8. FETCH CREATOR INFO FOR RESPONSE
                    var creator = await _context.Users.FindAsync(createdBy);

                    try
                    {
                        await _notificationService.CreateActorEventQrActionConfirmationAsync(
                            createdBy,
                            eventEntity.EventID,
                            eventEntity.EventName,
                            newQRCode.QRID,
                            "tạo mới");
                    }
                    catch (Exception ex)
                    {
                        // Notification là best-effort, không làm fail nghiệp vụ chính.
                        _logger.LogError(
                            ex,
                            "Không thể tạo thông báo xác nhận tạo QR: EventID={EventId}, QRID={QrId}, UserID={UserId}",
                            eventEntity.EventID,
                            newQRCode.QRID,
                            createdBy);
                    }

                    return new EventQrResponseDto
                    {
                        QRID = newQRCode.QRID,
                        EventID = eventEntity.EventID,
                        EventName = eventEntity.EventName,
                        QRToken = newQRCode.QRToken,
                        ValidFrom = DateTimeHelper.ToVietnamTime(newQRCode.ValidFrom),
                        ValidUntil = DateTimeHelper.ToVietnamTime(newQRCode.ValidUntil),
                        IsActive = newQRCode.IsActive,
                        ScanLimit = newQRCode.ScanLimit,
                        CurrentScans = newQRCode.CurrentScans,
                        Status = GetQRStatus(newQRCode).ToDisplayString(),
                        CreatedByName = creator?.FullName ?? "Không xác định",
                        CreatedDate = newQRCode.CreatedDate.HasValue
                                        ? DateTimeHelper.ToVietnamTime(newQRCode.CreatedDate.Value)
                                        : null
                    };
                }
                catch (Exception ex)
                {
                    await transaction.RollbackAsync();
                    _logger.LogError(ex, "Lỗi khi tạo QR code cho Event {EventId}", eventId);
                    throw;
                }
            });
        }

        /// <summary>
        /// Lấy danh sách tất cả QR codes của sự kiện (active và inactive)
        /// Dùng cho màn hình quản lý của CanBo/Admin
        /// </summary>
        public async Task<PaginatedResultDto<EventQrListItemDto>> GetEventQRCodesAsync(
            int eventId,
            GetEventQRCodesQueryDto query,
            int? unitId = null,
            int? instituteId = null)
        {
            // Validate event exists
            var eventEntity = await _context.Events
                .Where(e => e.EventID == eventId)
                .Select(e => new { e.EventID, e.InstituteID })
                .FirstOrDefaultAsync();

            if (eventEntity == null)
            {
                throw new KeyNotFoundException($"Không tìm thấy sự kiện với ID {eventId}");
            }

            var scopeInstituteId = await ResolveInstituteScopeAsync(instituteId, unitId);
            if (scopeInstituteId.HasValue && eventEntity.InstituteID != scopeInstituteId.Value)
            {
                throw new UnauthorizedAccessException("Bạn không có quyền xem QR của sự kiện thuộc viện khác");
            }

            var pageNumber = query.PageNumber < 1 ? 1 : query.PageNumber;
            var pageSize = query.PageSize is < 1 or > 200 ? 20 : query.PageSize;

            var baseQuery = _context.EventQRCodes
                .AsNoTracking()
                .Where(qr => qr.EventID == eventId);

            if (query.IsActive.HasValue)
            {
                baseQuery = baseQuery.Where(qr => qr.IsActive == query.IsActive.Value);
            }

            if (query.ValidNow.HasValue)
            {
                var now = DateTime.Now;
                if (query.ValidNow.Value)
                {
                    baseQuery = baseQuery.Where(qr => qr.ValidFrom <= now && now <= qr.ValidUntil);
                }
                else
                {
                    baseQuery = baseQuery.Where(qr => !(qr.ValidFrom <= now && now <= qr.ValidUntil));
                }
            }

            var totalCount = await baseQuery.CountAsync();

            var qrCodes = await baseQuery
                .Include(qr => qr.CreatedByNavigation)
                .OrderByDescending(qr => qr.CreatedDate)
                .ThenByDescending(qr => qr.QRID)
                .Skip((pageNumber - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            var items = qrCodes.Select(qr =>
            {
                var status = GetQRStatus(qr);
                return new EventQrListItemDto
                {
                    QRID = qr.QRID,
                    EventID = qr.EventID,
                    QRTokenPreview = MaskToken(qr.QRToken), // Chỉ hiện một phần token
                    ValidFrom = DateTimeHelper.ToVietnamTime(qr.ValidFrom),
                    ValidUntil = DateTimeHelper.ToVietnamTime(qr.ValidUntil),
                    IsActive = qr.IsActive,
                    ScanLimit = qr.ScanLimit,
                    CurrentScans = qr.CurrentScans,
                    Status = status.ToDisplayString(),
                    CreatedByName = qr.CreatedByNavigation?.FullName ?? "Không xác định",
                    CreatedDate = qr.CreatedDate.HasValue
                                ? DateTimeHelper.ToVietnamTime(qr.CreatedDate.Value)
                                : null
                };
            }).ToList();

            return new PaginatedResultDto<EventQrListItemDto>
            {
                Items = items,
                TotalCount = totalCount,
                PageNumber = pageNumber,
                PageSize = pageSize
            };
        }

        /// <summary>
        /// Vô hiệu hóa mã QR thủ công.
        /// 
        /// Sử dụng trong các trường hợp:
        /// - QR code bị lộ
        /// - Sự kiện bị hủy
        /// - Cần dừng điểm danh sớm
        /// </summary>
        public async Task<DeactivateQrResponseDto> DeactivateQRCodeAsync(int qrId, int userId, int? unitId = null, int? instituteId = null)
        {
            var qrCode = await _context.EventQRCodes
                .Include(qr => qr.Event)
                .Where(qr => qr.QRID == qrId)
                .FirstOrDefaultAsync();

            if (qrCode == null)
            {
                throw new KeyNotFoundException($"Không tìm thấy QR code với ID {qrId}");
            }

            var scopeInstituteId = await ResolveInstituteScopeAsync(instituteId, unitId);
            if (scopeInstituteId.HasValue && qrCode.Event.InstituteID != scopeInstituteId.Value)
            {
                throw new UnauthorizedAccessException("Bạn không có quyền vô hiệu hóa QR của sự kiện thuộc viện khác");
            }

            if (qrCode.IsActive != true)
            {
                //throw new InvalidOperationException("QR code này đã bị vô hiệu hóa trước đó");
                return new DeactivateQrResponseDto
                {
                    Success = true,
                    Message = "QR code đã ở trạng thái vô hiệu hóa",
                    QRID = qrId,
                    DeactivatedAt = DateTimeHelper.ToVietnamTime(qrCode.UpdatedDate ?? DateTime.Now)
                };
            }

            // Deactivate the QR code
            qrCode.IsActive = false;
            qrCode.UpdatedDate = DateTime.Now;

            _context.EventQRCodes.Update(qrCode);
            await _context.SaveChangesAsync();

            _logger.LogInformation(
                "QR code {QRID} của Event {EventId} đã bị vô hiệu hóa bởi User {UserId}",
                qrId, qrCode.EventID, userId);

            try
            {
                await _notificationService.CreateQrDeactivatedAlertAsync(
                    qrCode.EventID,
                    qrCode.Event.EventName,
                    qrCode.QRID,
                    userId);
            }
            catch (Exception ex)
            {
                // Notification là best-effort, không làm fail nghiệp vụ chính.
                _logger.LogError(
                    ex,
                    "Không thể tạo thông báo QR bị vô hiệu hóa: EventID={EventId}, QRID={QrId}, UserID={UserId}",
                    qrCode.EventID,
                    qrCode.QRID,
                    userId);
            }

            try
            {
                await _notificationService.CreateActorEventQrActionConfirmationAsync(
                    userId,
                    qrCode.EventID,
                    qrCode.Event.EventName,
                    qrCode.QRID,
                    "vô hiệu hóa");
            }
            catch (Exception ex)
            {
                // Notification là best-effort, không làm fail nghiệp vụ chính.
                _logger.LogError(
                    ex,
                    "Không thể tạo thông báo xác nhận vô hiệu hóa QR: EventID={EventId}, QRID={QrId}, UserID={UserId}",
                    qrCode.EventID,
                    qrCode.QRID,
                    userId);
            }

            return new DeactivateQrResponseDto
            {
                Success = true,
                Message = "QR code đã được vô hiệu hóa thành công",
                QRID = qrId,
                DeactivatedAt = DateTimeHelper.ToVietnamTime(DateTime.Now)
            };
        }

        /// <summary>
        /// Tạo token bảo mật sử dụng cryptographically secure RNG
        /// Token có độ dài 64 ký tự (256 bits entropy)
        /// 
        /// SECURITY RATIONALE:
        /// - RandomNumberGenerator là CSPRNG (cryptographically secure)
        /// - 32 bytes = 256 bits entropy (rất khó brute force)
        /// - Base64 URL-safe encoding (phù hợp cho QR code)
        /// </summary>
        private static string GenerateSecureToken()
        {
            byte[] randomBytes = new byte[32]; // 256 bits
            using (var rng = RandomNumberGenerator.Create())
            {
                rng.GetBytes(randomBytes);
            }

            // Convert to Base64 URL-safe string
            string token = Convert.ToBase64String(randomBytes)
                .Replace("+", "-")
                .Replace("/", "_")
                .Replace("=", "");

            return token;
        }

        /// <summary>
        /// Xác định trạng thái hiện tại của QR code
        /// </summary>
        private static QrCodeStatus GetQRStatus(EventQRCode qr)
        {
            if (qr.IsActive != true)
            {
                return QrCodeStatus.Inactive;
            }

            var now = DateTime.Now;

            if (now < qr.ValidFrom)
            {
                return QrCodeStatus.NotStarted;
            }

            if (now > qr.ValidUntil)
            {
                return QrCodeStatus.Expired;
            }

            if (qr.ScanLimit.HasValue && qr.CurrentScans.HasValue && qr.CurrentScans >= qr.ScanLimit.Value)
            {
                return QrCodeStatus.ScanLimitReached;
            }

            return QrCodeStatus.Active;
        }

        /// <summary>
        /// Lấy chi tiết một QR code (phục vụ Web quản lý).
        /// - Admin: xem tất cả
        /// - CanBo: chỉ xem QR thuộc sự kiện do mình tạo
        /// </summary>
        public async Task<QrCodeDetailResponseDto> GetQRCodeDetailAsync(
            int qrId,
            int requesterUserId,
            bool isAdmin,
            CancellationToken cancellationToken = default)
        {
            var qrCode = await _context.EventQRCodes
                .AsNoTracking()
                .Include(qr => qr.Event)
                .Include(qr => qr.CreatedByNavigation)
                .FirstOrDefaultAsync(qr => qr.QRID == qrId, cancellationToken);

            if (qrCode == null)
            {
                throw new KeyNotFoundException($"Không tìm thấy QR code với ID {qrId}");
            }

            if (!isAdmin && qrCode.Event.CreatedBy != requesterUserId)
            {
                throw new UnauthorizedAccessException("Bạn không có quyền truy cập QR code này");
            }

            var nowUtc = DateTime.Now;
            var attendanceCount = await _context.Attendances
                .AsNoTracking()
                .Where(a => a.QRID == qrId)
                .CountAsync(cancellationToken);

            var isActive = qrCode.IsActive == true;
            var isExpired = nowUtc > qrCode.ValidUntil;
            var isOverScanLimit = qrCode.ScanLimit.HasValue && attendanceCount >= qrCode.ScanLimit.Value;

            return new QrCodeDetailResponseDto
            {
                QrId = qrCode.QRID,
                EventId = qrCode.EventID,
                EventName = qrCode.Event.EventName,
                QrToken = qrCode.QRToken,
                IsActive = isActive,
                ValidFrom = DateTimeHelper.ToVietnamTime(qrCode.ValidFrom),
                ValidUntil = DateTimeHelper.ToVietnamTime(qrCode.ValidUntil),
                ScanLimit = qrCode.ScanLimit,
                CurrentScans = attendanceCount,
                CreatedBy = new QrCodeCreatorDto
                {
                    UserId = qrCode.CreatedBy,
                    FullName = qrCode.CreatedByNavigation?.FullName ?? "Không xác định"
                },
                CreatedDate = qrCode.CreatedDate.HasValue
                    ? DateTimeHelper.ToVietnamTime(qrCode.CreatedDate.Value)
                    : null,
                IsExpired = isExpired,
                IsOverScanLimit = isOverScanLimit
            };
        }

        private static bool IsOneActiveQrPerEventConflict(DbUpdateException ex)
        {
            if (ex.InnerException is not SqlException sqlEx)
            {
                return false;
            }

            // SQL Server duplicate key: 2601 (unique index) / 2627 (unique constraint)
            if (sqlEx.Number is 2601 or 2627)
            {
                return true;
            }

            return sqlEx.Message.Contains(
                "UQ_EventQRCodes_Active_EventID",
                StringComparison.OrdinalIgnoreCase);
        }

        private async Task<int?> ResolveInstituteScopeAsync(int? instituteId, int? unitId)
        {
            if (instituteId.HasValue)
            {
                return instituteId.Value;
            }

            if (!unitId.HasValue)
            {
                return null;
            }

            var resolvedInstituteId = await _context.Units
                .Where(u => u.UnitID == unitId.Value)
                .Select(u => u.InstituteID)
                .FirstOrDefaultAsync();

            if (resolvedInstituteId == 0)
            {
                throw new UnauthorizedAccessException("unitId trong token không hợp lệ");
            }

            return resolvedInstituteId;
        }

        /// <summary>
        /// Che token để hiển thị an toàn
        /// Ví dụ: "ABC...XYZ" thay vì full token
        /// </summary>
        private static string MaskToken(string token)
        {
            if (string.IsNullOrEmpty(token) || token.Length < 10)
            {
                return "***";
            }

            return $"{token.Substring(0, 6)}...{token.Substring(token.Length - 6)}";
        }
    }
}
