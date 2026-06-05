using UniYouth.Api.Application.Services.AttendanceSupport;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Shared.FaceVerification;

namespace UniYouth.Api.Tests.Attendance;

public class AttendanceRetryPolicyServiceTests
{
    private readonly AttendanceRetryPolicyService _service = new(new FaceVerificationOptions
    {
        Attendance = new AttendanceOptions { MaxFaceRetryAttempts = 2 }
    });

    [Fact]
    public void CanRetryFaceCheckIn_ReturnsFalse_WhenGpsOutOfRange()
    {
        var attendance = new UniYouth.Api.Domain.Entities.Attendance
        {
            IsValid = false,
            FaceVerificationStatus = "Mismatch",
            FaceRetryCount = 0,
            Distance = 60
        };
        var eventEntity = new Event
        {
            EnableFaceVerification = true,
            Latitude = 10,
            Longitude = 106,
            AllowRadius = 50
        };

        var canRetry = _service.CanRetryFaceCheckIn(attendance, eventEntity);

        Assert.False(canRetry);
    }

    [Fact]
    public void BuildInvalidFaceReason_MapsExpectedErrorCode()
    {
        var result = new FaceVerificationOutcome
        {
            FaceVerificationStatus = "Mismatch",
            FaceVerificationMessage = "Khuôn mặt không khớp hồ sơ đã đăng ký."
        };

        var message = _service.BuildInvalidFaceReason(result);

        Assert.Equal("[ATTENDANCE_FACE_MISMATCH] Khuôn mặt không khớp hồ sơ đã đăng ký.", message);
    }
}
