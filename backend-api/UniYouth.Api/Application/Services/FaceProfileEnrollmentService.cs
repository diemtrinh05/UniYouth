using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using UniYouth.Api.Contracts.DTOs.Users;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.FaceVerification;

namespace UniYouth.Api.Application.Services;

public interface IFaceProfileEnrollmentService
{
    Task<FaceProfileEnrollmentOtpRequestResult> RequestReEnrollmentOtpAsync(
        int userId,
        string? ipAddress = null,
        string? userAgent = null,
        CancellationToken cancellationToken = default);

    Task<FaceProfileEnrollmentServiceResult> EnrollAsync(
        int userId,
        EnrollFaceProfileRequestDto request,
        string webRootPath,
        string? ipAddress = null,
        string? userAgent = null,
        CancellationToken cancellationToken = default);
}

public enum FaceProfileEnrollmentFailureType
{
    None = 0,
    UserNotFound = 1,
    InvalidPayload = 2,
    NoFaceDetected = 3,
    MultipleFacesDetected = 4,
    BlurryImage = 5,
    TechnicalError = 6,
    CurrentFaceMismatch = 7,
    ReauthenticationFailed = 8,
    ReEnrollCooldownActive = 9
}

public sealed class FaceProfileEnrollmentServiceResult
{
    public FaceProfileEnrollmentResultDto? Data { get; init; }

    public FaceProfileEnrollmentFailureType FailureType { get; init; }

    public string? ErrorCode { get; init; }

    public string? ErrorMessage { get; init; }

    public bool Succeeded => Data is not null && FailureType == FaceProfileEnrollmentFailureType.None;
}

public sealed class FaceProfileEnrollmentOtpRequestResult
{
    public bool Success { get; init; }

    public string Message { get; init; } = string.Empty;

    public DateTime? ExpiresAt { get; init; }
}

public sealed class FaceProfileEnrollmentService : IFaceProfileEnrollmentService
{
    private const long MaxFaceImageBytes = 2 * 1024 * 1024;
    private const string UploadFolderName = "faces";
    private const string ReEnrollmentOtpPurpose = "FaceProfileReEnroll";

    private readonly UniYouthDbContext _context;
    private readonly IFaceProfileEnrollmentClient _client;
    private readonly IFaceVerificationClient _faceVerificationClient;
    private readonly IPasswordResetOtpService _passwordResetOtpService;
    private readonly IEmailService _emailService;
    private readonly FaceVerificationOptions _options;
    private readonly IPublicUrlBuilder _publicUrlBuilder;
    private readonly ILogger<FaceProfileEnrollmentService> _logger;

    public FaceProfileEnrollmentService(
        UniYouthDbContext context,
        IFaceProfileEnrollmentClient client,
        IFaceVerificationClient faceVerificationClient,
        IPasswordResetOtpService passwordResetOtpService,
        IEmailService emailService,
        IOptions<FaceVerificationOptions> options,
        IPublicUrlBuilder publicUrlBuilder,
        ILogger<FaceProfileEnrollmentService> logger)
    {
        _context = context;
        _client = client;
        _faceVerificationClient = faceVerificationClient;
        _passwordResetOtpService = passwordResetOtpService;
        _emailService = emailService;
        _options = options.Value;
        _publicUrlBuilder = publicUrlBuilder;
        _logger = logger;
    }

    public async Task<FaceProfileEnrollmentOtpRequestResult> RequestReEnrollmentOtpAsync(
        int userId,
        string? ipAddress = null,
        string? userAgent = null,
        CancellationToken cancellationToken = default)
    {
        var user = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(candidate => candidate.UserID == userId, cancellationToken);

        if (user is null || user.Status != 1)
        {
            QueueEnrollmentAudit(
                userId,
                "FACE_PROFILE_REENROLL_OTP_REJECT_USER_NOT_FOUND",
                null,
                new { UserId = userId },
                ipAddress,
                userAgent);
            await PersistAuditAsync(cancellationToken);

            return new FaceProfileEnrollmentOtpRequestResult
            {
                Success = false,
                Message = "Không tìm thấy người dùng."
            };
        }

        var currentActiveProfile = await _context.FaceProfiles
            .AsNoTracking()
            .Where(profile => profile.UserID == userId && profile.IsActive == true)
            .OrderByDescending(profile => profile.UpdatedDate ?? profile.CreatedDate)
            .FirstOrDefaultAsync(cancellationToken);

        if (currentActiveProfile?.FaceEmbedding is not { Length: > 0 })
        {
            QueueEnrollmentAudit(
                userId,
                "FACE_PROFILE_REENROLL_OTP_REJECT_NO_ACTIVE_PROFILE",
                null,
                new { UserId = userId },
                ipAddress,
                userAgent);
            await PersistAuditAsync(cancellationToken);

            return new FaceProfileEnrollmentOtpRequestResult
            {
                Success = false,
                Message = "Tài khoản chưa có hồ sơ khuôn mặt để cập nhật."
            };
        }

        var cooldownFailure = CreateCooldownFailureIfAny(currentActiveProfile);
        if (cooldownFailure is not null)
        {
            QueueEnrollmentAudit(
                userId,
                "FACE_PROFILE_REENROLL_OTP_REJECT_COOLDOWN",
                currentActiveProfile.FaceProfileID,
                new
                {
                    CurrentFaceProfileId = currentActiveProfile.FaceProfileID,
                    currentActiveProfile.UpdatedDate,
                    currentActiveProfile.CreatedDate,
                    CooldownMinutes = _options.Enrollment.ReEnrollCooldownMinutes
                },
                ipAddress,
                userAgent);
            await PersistAuditAsync(cancellationToken);

            return new FaceProfileEnrollmentOtpRequestResult
            {
                Success = false,
                Message = cooldownFailure.ErrorMessage ?? "Bạn chưa thể cập nhật khuôn mặt lúc này."
            };
        }

        var otpResult = await _passwordResetOtpService.IssueOtpAsync(
            userId,
            ReEnrollmentOtpPurpose,
            ipAddress,
            userAgent,
            cancellationToken);

        try
        {
            var subject = "UniYouth - Mã OTP xác nhận cập nhật khuôn mặt";
            var html = $@"
<p>Bạn vừa yêu cầu cập nhật hồ sơ khuôn mặt cho tài khoản UniYouth.</p>
<p>Mã OTP của bạn là:</p>
<h2 style=""letter-spacing: 4px;"">{otpResult.OtpCode}</h2>
<p>Mã có hiệu lực đến <b>{otpResult.ExpiresAt:HH:mm dd/MM/yyyy}</b>.</p>
<p>Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email.</p>";

            await _emailService.SendAsync(user.Email, subject, html, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Gửi OTP cập nhật khuôn mặt thất bại cho UserId {UserId}", userId);
            await _passwordResetOtpService.RevokeActiveOtpsAsync(userId, ReEnrollmentOtpPurpose, cancellationToken);

            QueueEnrollmentAudit(
                userId,
                "FACE_PROFILE_REENROLL_OTP_REJECT_EMAIL_FAILED",
                currentActiveProfile.FaceProfileID,
                new { currentActiveProfile.FaceProfileID, otpResult.ExpiresAt },
                ipAddress,
                userAgent);
            await PersistAuditAsync(cancellationToken);

            return new FaceProfileEnrollmentOtpRequestResult
            {
                Success = false,
                Message = "Không thể gửi mã OTP lúc này. Vui lòng thử lại sau."
            };
        }

        QueueEnrollmentAudit(
            userId,
            "FACE_PROFILE_REENROLL_OTP_REQUESTED",
            currentActiveProfile.FaceProfileID,
            new
            {
                currentActiveProfile.FaceProfileID,
                otpResult.ExpiresAt
            },
            ipAddress,
            userAgent);
        await PersistAuditAsync(cancellationToken);

        return new FaceProfileEnrollmentOtpRequestResult
        {
            Success = true,
            Message = "Mã OTP xác nhận cập nhật khuôn mặt đã được gửi tới email của tài khoản.",
            ExpiresAt = otpResult.ExpiresAt
        };
    }

    public async Task<FaceProfileEnrollmentServiceResult> EnrollAsync(
        int userId,
        EnrollFaceProfileRequestDto request,
        string webRootPath,
        string? ipAddress = null,
        string? userAgent = null,
        CancellationToken cancellationToken = default)
    {
        var user = await _context.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(candidate => candidate.UserID == userId, cancellationToken);

        if (user is null)
        {
            QueueEnrollmentAudit(
                userId,
                "FACE_PROFILE_ENROLL_REJECT_USER_NOT_FOUND",
                null,
                new { UserId = userId },
                ipAddress,
                userAgent);
            await PersistAuditAsync(cancellationToken);

            return new FaceProfileEnrollmentServiceResult
            {
                FailureType = FaceProfileEnrollmentFailureType.UserNotFound,
                ErrorMessage = "Không tìm thấy người dùng."
            };
        }

        if (!string.Equals(request.FaceImageMimeType?.Trim(), "image/jpeg", StringComparison.OrdinalIgnoreCase))
        {
            QueueEnrollmentAudit(
                userId,
                "FACE_PROFILE_ENROLL_REJECT_INVALID_MIME",
                null,
                new { request.FaceImageMimeType },
                ipAddress,
                userAgent);
            await PersistAuditAsync(cancellationToken);

            return CreateClientFailure(
                FaceProfileEnrollmentFailureType.InvalidPayload,
                "UNSUPPORTED_MIME_TYPE",
                "Ảnh khuôn mặt phải ở định dạng JPEG.");
        }

        byte[] imageBytes;
        try
        {
            imageBytes = Convert.FromBase64String(request.FaceImageBase64);
        }
        catch (FormatException)
        {
            QueueEnrollmentAudit(
                userId,
                "FACE_PROFILE_ENROLL_REJECT_INVALID_BASE64",
                null,
                new { userId },
                ipAddress,
                userAgent);
            await PersistAuditAsync(cancellationToken);

            return CreateClientFailure(
                FaceProfileEnrollmentFailureType.InvalidPayload,
                "INVALID_BASE64",
                "Ảnh khuôn mặt không hợp lệ.");
        }

        if (imageBytes.Length == 0 || imageBytes.Length > MaxFaceImageBytes)
        {
            QueueEnrollmentAudit(
                userId,
                "FACE_PROFILE_ENROLL_REJECT_INVALID_IMAGE_SIZE",
                null,
                new { ImageBytes = imageBytes.Length },
                ipAddress,
                userAgent);
            await PersistAuditAsync(cancellationToken);

            return CreateClientFailure(
                FaceProfileEnrollmentFailureType.InvalidPayload,
                "INVALID_IMAGE_SIZE",
                "Kích thước ảnh khuôn mặt không hợp lệ.");
        }

        var clientResponse = await _client.EnrollAsync(
            new FaceProfileEnrollmentClientRequest
            {
                UserId = userId,
                FaceImageBase64 = request.FaceImageBase64,
                FaceImageMimeType = request.FaceImageMimeType ?? string.Empty
            },
            cancellationToken);

        if (!string.Equals(clientResponse.Status, FaceProfileEnrollmentClientResponse.StatusReady, StringComparison.OrdinalIgnoreCase))
        {
            return MapFailure(clientResponse);
        }

        if (string.IsNullOrWhiteSpace(clientResponse.EmbeddingBase64))
        {
            return CreateTechnicalFailure(
                "EMPTY_EMBEDDING",
                "Face enrollment service returned empty embedding.");
        }

        byte[] embeddingBytes;
        try
        {
            embeddingBytes = Convert.FromBase64String(clientResponse.EmbeddingBase64);
        }
        catch (FormatException)
        {
            return CreateTechnicalFailure(
                "INVALID_EMBEDDING",
                "Face enrollment service returned invalid embedding.");
        }

        if (embeddingBytes.Length == 0)
        {
            return CreateTechnicalFailure(
                "EMPTY_EMBEDDING",
                "Face enrollment service returned empty embedding.");
        }

        var currentActiveProfile = await _context.FaceProfiles
            .AsNoTracking()
            .Where(profile => profile.UserID == userId && profile.IsActive == true)
            .OrderByDescending(profile => profile.UpdatedDate ?? profile.CreatedDate)
            .FirstOrDefaultAsync(cancellationToken);

        if (currentActiveProfile?.FaceEmbedding is { Length: > 0 })
        {
            var cooldownFailure = CreateCooldownFailureIfAny(currentActiveProfile);
            if (cooldownFailure is not null)
            {
                QueueEnrollmentAudit(
                    userId,
                    "FACE_PROFILE_REENROLL_REJECT_COOLDOWN",
                    currentActiveProfile.FaceProfileID,
                    new
                    {
                        CurrentFaceProfileId = currentActiveProfile.FaceProfileID,
                        currentActiveProfile.UpdatedDate,
                        currentActiveProfile.CreatedDate,
                        CooldownMinutes = _options.Enrollment.ReEnrollCooldownMinutes
                    },
                    ipAddress,
                    userAgent);
                await PersistAuditAsync(cancellationToken);

                return cooldownFailure;
            }

            var reauthFailure = await CreateReauthenticationFailureIfAny(userId, request, cancellationToken);
            if (reauthFailure is not null)
            {
                QueueEnrollmentAudit(
                    userId,
                    "FACE_PROFILE_REENROLL_REJECT_REAUTH",
                    currentActiveProfile.FaceProfileID,
                    new
                    {
                        CurrentFaceProfileId = currentActiveProfile.FaceProfileID
                    },
                    ipAddress,
                    userAgent);
                await PersistAuditAsync(cancellationToken);

                return reauthFailure;
            }

            var guardResult = await VerifyAgainstCurrentProfileAsync(
                userId,
                request,
                currentActiveProfile,
                ipAddress,
                userAgent,
                cancellationToken);

            if (guardResult is not null)
            {
                return guardResult;
            }
        }

        var normalizedWebRootPath = ResolveWebRootPath(webRootPath);
        var uploadDirectory = Path.Combine(normalizedWebRootPath, "uploads", UploadFolderName);
        Directory.CreateDirectory(uploadDirectory);

        var fileName = $"face_profile_{userId}_{DateTimeOffset.UtcNow.ToUnixTimeMilliseconds()}.jpg";
        var absoluteFilePath = Path.Combine(uploadDirectory, fileName);
        var relativeImageUrl = $"/uploads/{UploadFolderName}/{fileName}";

        await File.WriteAllBytesAsync(absoluteFilePath, imageBytes, cancellationToken);

        try
        {
            var now = DateTime.Now;
            var activeProfiles = await _context.FaceProfiles
                .Where(profile => profile.UserID == userId && profile.IsActive == true)
                .ToListAsync(cancellationToken);

            foreach (var activeProfile in activeProfiles)
            {
                activeProfile.IsActive = false;
                activeProfile.UpdatedDate = now;
            }

            if (activeProfiles.Count > 0)
            {
                await _context.SaveChangesAsync(cancellationToken);
            }

            var profile = new FaceProfile
            {
                UserID = userId,
                FaceEmbedding = embeddingBytes,
                Algorithm = clientResponse.Model,
                Version = clientResponse.Version,
                QualityScore = clientResponse.QualityScore,
                ImageUrl = relativeImageUrl,
                IsActive = true,
                CreatedDate = now,
                UpdatedDate = now
            };

            _context.FaceProfiles.Add(profile);
            await _context.SaveChangesAsync(cancellationToken);

            _logger.LogInformation(
                "Enrolled face profile for user {UserId}. FaceProfileID {FaceProfileId}",
                userId,
                profile.FaceProfileID);

            QueueEnrollmentAudit(
                userId,
                activeProfiles.Count > 0
                    ? "FACE_PROFILE_REENROLL_SUCCESS"
                    : "FACE_PROFILE_ENROLL_SUCCESS",
                profile.FaceProfileID,
                new
                {
                    profile.FaceProfileID,
                    profile.QualityScore,
                    profile.Algorithm,
                    profile.Version,
                    ReplacedPreviousProfile = activeProfiles.Count > 0
                },
                ipAddress,
                userAgent);

            await PersistAuditAsync(cancellationToken);

            return new FaceProfileEnrollmentServiceResult
            {
                FailureType = FaceProfileEnrollmentFailureType.None,
                Data = new FaceProfileEnrollmentResultDto
                {
                    FaceProfileId = profile.FaceProfileID,
                    ImageUrl = _publicUrlBuilder.BuildAbsoluteUrl(relativeImageUrl),
                    QualityScore = profile.QualityScore,
                    Algorithm = profile.Algorithm ?? string.Empty,
                    Version = profile.Version ?? string.Empty,
                    UpdatedDate = profile.UpdatedDate ?? now,
                    ReplacedPreviousProfile = activeProfiles.Count > 0
                }
            };
        }
        catch
        {
            try
            {
                if (File.Exists(absoluteFilePath))
                {
                    File.Delete(absoluteFilePath);
                }
            }
            catch
            {
            }

            throw;
        }
    }

    private static string ResolveWebRootPath(string webRootPath)
    {
        if (!string.IsNullOrWhiteSpace(webRootPath))
        {
            return webRootPath;
        }

        return Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
    }

    private static FaceProfileEnrollmentServiceResult CreateClientFailure(
        FaceProfileEnrollmentFailureType failureType,
        string errorCode,
        string errorMessage)
    {
        return new FaceProfileEnrollmentServiceResult
        {
            FailureType = failureType,
            ErrorCode = errorCode,
            ErrorMessage = errorMessage
        };
    }

    private static FaceProfileEnrollmentServiceResult CreateTechnicalFailure(string errorCode, string errorMessage)
    {
        return new FaceProfileEnrollmentServiceResult
        {
            FailureType = FaceProfileEnrollmentFailureType.TechnicalError,
            ErrorCode = errorCode,
            ErrorMessage = errorMessage
        };
    }

    private static FaceProfileEnrollmentServiceResult MapFailure(FaceProfileEnrollmentClientResponse response)
    {
        var status = response.Status?.Trim() ?? string.Empty;
        return status switch
        {
            "InvalidPayload" => CreateClientFailure(
                FaceProfileEnrollmentFailureType.InvalidPayload,
                response.ErrorCode ?? "INVALID_PAYLOAD",
                "Ảnh khuôn mặt không hợp lệ."),
            "NoFaceDetected" => CreateClientFailure(
                FaceProfileEnrollmentFailureType.NoFaceDetected,
                response.ErrorCode ?? "NO_FACE_DETECTED",
                "Không phát hiện khuôn mặt rõ ràng. Vui lòng thử lại."),
            "MultipleFacesDetected" => CreateClientFailure(
                FaceProfileEnrollmentFailureType.MultipleFacesDetected,
                response.ErrorCode ?? "MULTIPLE_FACES_DETECTED",
                "Phát hiện nhiều khuôn mặt. Vui lòng chỉ để một người trong khung hình."),
            "BlurryImage" => CreateClientFailure(
                FaceProfileEnrollmentFailureType.BlurryImage,
                response.ErrorCode ?? "BLURRY_IMAGE",
                "Ảnh khuôn mặt bị mờ. Vui lòng giữ máy ổn định và thử lại."),
            _ => CreateTechnicalFailure(
                response.ErrorCode ?? "FACE_ENROLL_TECHNICAL_ERROR",
                response.ErrorMessage ?? "Không thể đăng ký khuôn mặt lúc này.")
        };
    }

    private async Task<FaceProfileEnrollmentServiceResult?> VerifyAgainstCurrentProfileAsync(
        int userId,
        EnrollFaceProfileRequestDto request,
        FaceProfile currentActiveProfile,
        string? ipAddress,
        string? userAgent,
        CancellationToken cancellationToken)
    {
        var verifyResponse = await _faceVerificationClient.VerifyAsync(
            new FaceVerificationClientRequest
            {
                UserId = userId,
                EventId = 0,
                FaceProfileId = currentActiveProfile.FaceProfileID,
                Algorithm = currentActiveProfile.Algorithm ?? "ArcFace",
                Version = currentActiveProfile.Version,
                ReferenceEmbedding = currentActiveProfile.FaceEmbedding ?? Array.Empty<byte>(),
                FaceImageBase64 = request.FaceImageBase64,
                FaceImageMimeType = request.FaceImageMimeType ?? "image/jpeg"
            },
            cancellationToken);

        if (string.Equals(verifyResponse.Status, "Matched", StringComparison.OrdinalIgnoreCase))
        {
            return null;
        }

        if (string.Equals(
                verifyResponse.Status,
                FaceVerificationClientResponse.StatusTechnicalError,
                StringComparison.OrdinalIgnoreCase))
        {
            _logger.LogWarning(
                "Rejected face profile re-enrollment for user {UserId} because current-face verification failed technically. ErrorCode {ErrorCode}",
                userId,
                verifyResponse.ErrorCode);

            QueueEnrollmentAudit(
                userId,
                "FACE_PROFILE_REENROLL_REJECT_GUARD_TECHNICAL_ERROR",
                currentActiveProfile.FaceProfileID,
                new
                {
                    CurrentFaceProfileId = currentActiveProfile.FaceProfileID,
                    verifyResponse.Status,
                    verifyResponse.ErrorCode,
                    verifyResponse.ErrorMessage
                },
                ipAddress,
                userAgent);
            await PersistAuditAsync(cancellationToken);

            return CreateTechnicalFailure(
                verifyResponse.ErrorCode ?? "REENROLL_GUARD_TECHNICAL_ERROR",
                "Không thể xác minh hồ sơ khuôn mặt hiện tại. Vui lòng thử lại sau.");
        }

        _logger.LogInformation(
            "Rejected face profile re-enrollment for user {UserId}. Verification against current profile returned status {Status} with confidence {Confidence}",
            userId,
            verifyResponse.Status,
            verifyResponse.NormalizedConfidence);

        QueueEnrollmentAudit(
            userId,
            "FACE_PROFILE_REENROLL_REJECT_CURRENT_FACE_MISMATCH",
            currentActiveProfile.FaceProfileID,
            new
            {
                CurrentFaceProfileId = currentActiveProfile.FaceProfileID,
                verifyResponse.Status,
                verifyResponse.NormalizedConfidence,
                verifyResponse.ErrorCode
            },
            ipAddress,
            userAgent);
        await PersistAuditAsync(cancellationToken);

        return CreateClientFailure(
            FaceProfileEnrollmentFailureType.CurrentFaceMismatch,
            verifyResponse.ErrorCode ?? "CURRENT_FACE_MISMATCH",
            "Khuôn mặt mới không khớp với hồ sơ khuôn mặt hiện tại của tài khoản này.");
    }

    private FaceProfileEnrollmentServiceResult? CreateCooldownFailureIfAny(FaceProfile currentActiveProfile)
    {
        var cooldownMinutes = Math.Max(0, _options.Enrollment.ReEnrollCooldownMinutes);
        if (cooldownMinutes <= 0)
        {
            return null;
        }

        var lastChangedAt = currentActiveProfile.UpdatedDate ?? currentActiveProfile.CreatedDate;
        if (lastChangedAt is null)
        {
            return null;
        }

        var nextAllowedAt = lastChangedAt.Value.AddMinutes(cooldownMinutes);
        if (DateTime.Now >= nextAllowedAt)
        {
            return null;
        }

        return CreateClientFailure(
            FaceProfileEnrollmentFailureType.ReEnrollCooldownActive,
            "REENROLL_COOLDOWN_ACTIVE",
            $"Bạn vừa cập nhật khuôn mặt gần đây. Vui lòng thử lại sau {nextAllowedAt:dd/MM/yyyy HH:mm}.");
    }

    private async Task<FaceProfileEnrollmentServiceResult?> CreateReauthenticationFailureIfAny(
        int userId,
        EnrollFaceProfileRequestDto request,
        CancellationToken cancellationToken)
    {
        var otpCode = (request.ReauthOtpCode ?? string.Empty).Trim();
        if (string.IsNullOrWhiteSpace(otpCode))
        {
            return CreateClientFailure(
                FaceProfileEnrollmentFailureType.ReauthenticationFailed,
                "REAUTH_OTP_REQUIRED",
                "Vui lòng nhập mã OTP đã gửi về email để cập nhật khuôn mặt.");
        }

        if (otpCode.Length != 6 || !otpCode.All(char.IsDigit))
        {
            return CreateClientFailure(
                FaceProfileEnrollmentFailureType.ReauthenticationFailed,
                "REAUTH_OTP_INVALID_FORMAT",
                "Mã OTP phải gồm đúng 6 chữ số.");
        }

        var verifyResult = await _passwordResetOtpService.VerifyOtpAsync(
            userId,
            ReEnrollmentOtpPurpose,
            otpCode,
            cancellationToken);

        if (!verifyResult.Success)
        {
            return CreateClientFailure(
                FaceProfileEnrollmentFailureType.ReauthenticationFailed,
                "REAUTH_OTP_INVALID",
                verifyResult.Message);
        }

        await _passwordResetOtpService.RevokeActiveOtpsAsync(userId, ReEnrollmentOtpPurpose, cancellationToken);

        return null;
    }

    private void QueueEnrollmentAudit(
        int? actorUserId,
        string action,
        int? faceProfileId,
        object details,
        string? ipAddress,
        string? userAgent)
    {
        _context.AuditLogs.Add(new AuditLog
        {
            UserID = actorUserId,
            Action = action,
            TableName = "FaceProfiles",
            RecordID = faceProfileId,
            OldValue = null,
            NewValue = System.Text.Json.JsonSerializer.Serialize(details),
            IPAddress = ipAddress,
            UserAgent = userAgent,
            CreatedDate = DateTime.UtcNow
        });
    }

    private async Task PersistAuditAsync(CancellationToken cancellationToken)
    {
        await _context.SaveChangesAsync(cancellationToken);
    }
}











