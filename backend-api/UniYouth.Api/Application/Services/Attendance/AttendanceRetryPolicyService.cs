using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Shared.FaceVerification;
using UniYouth.Api.Shared.Helpers;

namespace UniYouth.Api.Application.Services.AttendanceSupport;

public sealed class AttendanceRetryPolicyService
{
    private readonly FaceVerificationOptions _options;

    public AttendanceRetryPolicyService(FaceVerificationOptions options)
    {
        _options = options;
    }

    public bool CanRetryFaceCheckIn(UniYouth.Api.Domain.Entities.Attendance attendance, Event eventEntity)
    {
        if (attendance.IsValid == true || !eventEntity.EnableFaceVerification)
        {
            return false;
        }

        if (!IsRetryableFaceStatus(attendance.FaceVerificationStatus))
        {
            return false;
        }

        if (eventEntity.Latitude.HasValue
            && eventEntity.Longitude.HasValue
            && attendance.Distance.HasValue
            && attendance.Distance.Value > eventEntity.AllowRadius)
        {
            return false;
        }

        return attendance.FaceRetryCount.GetValueOrDefault() < _options.Attendance.MaxFaceRetryAttempts;
    }

    public int GetRemainingFaceRetryAttempts(int currentRetryCount)
    {
        var remaining = _options.Attendance.MaxFaceRetryAttempts - currentRetryCount;
        return remaining > 0 ? remaining : 0;
    }

    public bool IsRetryableFaceStatus(string? status)
    {
        if (string.IsNullOrWhiteSpace(status))
        {
            return false;
        }

        return status.Trim() switch
        {
            "Mismatch" => true,
            "Review" => true,
            "NoFaceDetected" => true,
            "MultipleFacesDetected" => true,
            "BlurryImage" => true,
            _ => false
        };
    }

    public string BuildDuplicateCheckInMessage(UniYouth.Api.Domain.Entities.Attendance attendance, Event eventEntity)
    {
        if (eventEntity.EnableFaceVerification && IsRetryableFaceStatus(attendance.FaceVerificationStatus))
        {
            var remaining = GetRemainingFaceRetryAttempts(attendance.FaceRetryCount.GetValueOrDefault());
            if (remaining <= 0)
            {
                return BuildErrorMessage(
                    AttendanceErrorCodes.FaceRetryLimitReached,
                    "Bạn đã hết số lượt thử lại xác minh khuôn mặt cho sự kiện này. Vui lòng liên hệ cán bộ phụ trách nếu cần hỗ trợ.");
            }
        }

        return BuildErrorMessage(
            AttendanceErrorCodes.AlreadyCheckedIn,
            $"Bạn đã điểm danh lúc {DateTimeHelper.ToVietnamTime(attendance.CheckInTime!.Value):HH:mm:ss dd/MM/yyyy}");
    }

    public string ResolveDuplicateCheckInReason(UniYouth.Api.Domain.Entities.Attendance attendance, Event eventEntity)
    {
        if (eventEntity.EnableFaceVerification && IsRetryableFaceStatus(attendance.FaceVerificationStatus))
        {
            var remaining = GetRemainingFaceRetryAttempts(attendance.FaceRetryCount.GetValueOrDefault());
            if (remaining <= 0)
            {
                return "FACE_RETRY_LIMIT_REACHED";
            }
        }

        return "DUPLICATE_CHECKIN";
    }

    public string? BuildFaceRetryHint(int remainingFaceRetryAttempts)
    {
        return remainingFaceRetryAttempts switch
        {
            > 1 => $"Bạn còn {remainingFaceRetryAttempts} lượt thử lại khuôn mặt.",
            1 => "Bạn còn 1 lượt thử lại khuôn mặt.",
            _ => "Bạn đã hết lượt thử lại khuôn mặt cho sự kiện này."
        };
    }

    public string? AppendInvalidReason(string? currentReason, string? nextReason)
    {
        var normalizedCurrent = string.IsNullOrWhiteSpace(currentReason) ? null : currentReason.Trim();
        var normalizedNext = string.IsNullOrWhiteSpace(nextReason) ? null : nextReason.Trim();

        if (normalizedCurrent is null)
        {
            return normalizedNext;
        }

        if (normalizedNext is null)
        {
            return normalizedCurrent;
        }

        if (string.Equals(normalizedCurrent, normalizedNext, StringComparison.Ordinal))
        {
            return normalizedCurrent;
        }

        return $"{normalizedCurrent} {normalizedNext}";
    }

    public string BuildInvalidFaceReason(FaceVerificationOutcome faceResult)
    {
        var code = faceResult.FaceVerificationStatus switch
        {
            "Mismatch" => AttendanceErrorCodes.FaceMismatch,
            "Review" => AttendanceErrorCodes.FaceReview,
            "NoFaceDetected" => AttendanceErrorCodes.FaceNoFace,
            "MultipleFacesDetected" => AttendanceErrorCodes.FaceMultipleFaces,
            "BlurryImage" => AttendanceErrorCodes.FaceBlurry,
            "InvalidPayload" => AttendanceErrorCodes.FaceInvalidPayload,
            "ProfileMissing" => AttendanceErrorCodes.FaceProfileMissing,
            "PayloadMissing" => AttendanceErrorCodes.FacePayloadMissing,
            _ => AttendanceErrorCodes.FaceTechnical
        };

        return BuildErrorMessage(code, faceResult.FaceVerificationMessage ?? "Xác minh khuôn mặt không đạt yêu cầu.");
    }

    public static string BuildErrorMessage(string code, string message)
    {
        return $"[{code}] {message}";
    }
}
