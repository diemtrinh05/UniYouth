using UniYouth.Api.Application.Services.AttendanceSupport;
using UniYouth.Api.Contracts.DTOs.Points;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Shared.FaceVerification;

namespace UniYouth.Api.Tests.Attendance;

public class AttendanceResultMapperTests
{
    [Fact]
    public void MapCheckInResult_AppendsRetryHint_ForRetryableInvalidFaceStatus()
    {
        var retryPolicy = new AttendanceRetryPolicyService(new FaceVerificationOptions
        {
            Attendance = new AttendanceOptions { MaxFaceRetryAttempts = 2 }
        });
        var mapper = new AttendanceResultMapper(retryPolicy);
        var attendance = new UniYouth.Api.Domain.Entities.Attendance
        {
            AttendanceID = 50,
            FaceVerificationStatus = "Mismatch",
            FaceRetryCount = 1,
            FaceVerified = false,
            LivenessPassed = true
        };
        var eventEntity = new Event
        {
            EventName = "Sinh hoạt chi đoàn",
            EnableFaceVerification = true
        };

        var result = mapper.MapCheckInResult(
            eventEntity,
            attendance,
            new DateTime(2026, 4, 14, 8, 0, 0),
            false,
            "[ATTENDANCE_FACE_MISMATCH] Khuôn mặt không khớp hồ sơ đã đăng ký.",
            12,
            null);

        Assert.Contains("Bạn còn 1 lượt thử lại khuôn mặt.", result.InvalidReason);
        Assert.False(result.IsValid);
    }
}
