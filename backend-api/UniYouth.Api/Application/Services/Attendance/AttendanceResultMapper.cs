using UniYouth.Api.Contracts.DTOs.Attendance;
using UniYouth.Api.Contracts.DTOs.Points;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Shared.Helpers;

namespace UniYouth.Api.Application.Services.AttendanceSupport;

public sealed class AttendanceResultMapper
{
    private readonly AttendanceRetryPolicyService _retryPolicyService;

    public AttendanceResultMapper(AttendanceRetryPolicyService retryPolicyService)
    {
        _retryPolicyService = retryPolicyService;
    }

    public CheckInResultDto MapCheckInResult(
        Event eventEntity,
        UniYouth.Api.Domain.Entities.Attendance attendance,
        DateTime now,
        bool isValid,
        string? invalidReason,
        double distance,
        PointAwardedDto? pointsAwarded)
    {
        var normalizedInvalidReason = invalidReason;
        var remainingRetryAttempts = _retryPolicyService.GetRemainingFaceRetryAttempts(attendance.FaceRetryCount.GetValueOrDefault());

        if (!isValid
            && eventEntity.EnableFaceVerification
            && _retryPolicyService.IsRetryableFaceStatus(attendance.FaceVerificationStatus))
        {
            normalizedInvalidReason = _retryPolicyService.AppendInvalidReason(
                normalizedInvalidReason,
                _retryPolicyService.BuildFaceRetryHint(remainingRetryAttempts));
        }

        return new CheckInResultDto
        {
            IsSuccess = true,
            Message = isValid ? "Điểm danh thành công!" : $"Điểm danh không hợp lệ: {normalizedInvalidReason}",
            EventName = eventEntity.EventName,
            CheckInTime = DateTimeHelper.ToVietnamTime(now),
            Distance = distance,
            IsValid = isValid,
            InvalidReason = normalizedInvalidReason,
            AttendanceID = attendance.AttendanceID,
            PointsAwarded = pointsAwarded,
            FaceVerified = string.IsNullOrWhiteSpace(attendance.FaceVerificationStatus) ? null : attendance.FaceVerified,
            FaceConfidence = attendance.FaceConfidence,
            FaceVerificationStatus = attendance.FaceVerificationStatus,
            FaceVerificationMessage = attendance.FaceVerificationReason,
            LivenessPassed = attendance.LivenessPassed,
            LivenessScore = attendance.LivenessScore,
            LivenessReason = attendance.LivenessReason,
            RiskScore = attendance.RiskScore,
            RiskLevel = attendance.RiskLevel
        };
    }
}
