using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using Moq;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Application.Services.AttendanceSupport;
using UniYouth.Api.Contracts.DTOs.Attendance;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Enums;
using UniYouth.Api.Shared.FaceVerification;

namespace UniYouth.Api.Tests.Attendance;

public class AttendanceCheckInPrecheckServiceTests
{
    [Fact]
    public async Task PrepareAsync_Throws_WhenQrTokenNotFound()
    {
        await using var context = CreateContext(nameof(PrepareAsync_Throws_WhenQrTokenNotFound));
        var service = CreateService(context);

        var ex = await Assert.ThrowsAsync<KeyNotFoundException>(() => service.PrepareAsync(
            new CheckInRequestDto { QRToken = "missing", Latitude = 10, Longitude = 106 },
            7,
            DateTime.Now,
            null,
            null));

        Assert.Contains("ATTENDANCE_QR_NOT_FOUND", ex.Message);
    }

    [Fact]
    public async Task PrepareAsync_AllowsFaceRetryFlow_WhenAttendanceIsRetryable()
    {
        await using var context = CreateContext(nameof(PrepareAsync_AllowsFaceRetryFlow_WhenAttendanceIsRetryable));
        var now = DateTime.Now;
        var eventEntity = new Event
        {
            EventID = 1,
            EventName = "Test",
            CreatedBy = 1,
            EventTypeID = 1,
            Status = (byte)EventStatus.Ongoing,
            EnableFaceVerification = true,
            Latitude = 10.77m,
            Longitude = 106.70m,
            AllowRadius = 100,
            StartTime = now.AddHours(-1),
            EndTime = now.AddHours(1)
        };
        var qr = new EventQRCode
        {
            QRID = 2,
            EventID = 1,
            QRToken = "token-1",
            IsActive = true,
            ValidFrom = now.AddMinutes(-5),
            ValidUntil = now.AddMinutes(5),
            CurrentScans = 0,
            Event = eventEntity
        };
        var registration = new EventRegistration
        {
            RegistrationID = 3,
            EventID = 1,
            UserID = 9,
            Status = (byte)RegistrationStatus.Registered
        };
        var attendance = new UniYouth.Api.Domain.Entities.Attendance
        {
            AttendanceID = 4,
            EventID = 1,
            UserID = 9,
            IsValid = false,
            FaceVerificationStatus = "Mismatch",
            FaceRetryCount = 0,
            Distance = 10,
            CheckInTime = now.AddMinutes(-1)
        };
        context.Events.Add(eventEntity);
        context.EventQRCodes.Add(qr);
        context.EventRegistrations.Add(registration);
        context.Attendances.Add(attendance);
        await context.SaveChangesAsync();

        var service = CreateService(context);
        var result = await service.PrepareAsync(
            new CheckInRequestDto { QRToken = "token-1", Latitude = 10.77m, Longitude = 106.70m },
            9,
            now,
            null,
            null);

        Assert.True(result.IsFaceRetryFlow);
        Assert.Equal(attendance.AttendanceID, result.ExistingAttendance?.AttendanceID);
    }

    private static AttendanceCheckInPrecheckService CreateService(UniYouthDbContext context)
    {
        var notificationService = new Mock<INotificationService>();
        var retryPolicy = new AttendanceRetryPolicyService(new FaceVerificationOptions
        {
            Attendance = new AttendanceOptions { MaxFaceRetryAttempts = 2 }
        });

        return new AttendanceCheckInPrecheckService(
            context,
            Mock.Of<ILogger>(),
            notificationService.Object,
            new AttendanceAuditService(context),
            retryPolicy);
    }

    private static UniYouthDbContext CreateContext(string name)
    {
        var options = new DbContextOptionsBuilder<UniYouthDbContext>()
            .UseInMemoryDatabase(name)
            .Options;
        return new UniYouthDbContext(options);
    }
}
