using Microsoft.Extensions.Logging;
using Moq;
using UniYouth.Api.Application.Services.AttendanceSupport;
using UniYouth.Api.Contracts.DTOs.Attendance;
using UniYouth.Api.Domain.Entities;

namespace UniYouth.Api.Tests.Attendance;

public class AttendanceGpsValidationServiceTests
{
    [Fact]
    public void Validate_ReturnsInvalid_WhenDistanceExceedsAllowRadius()
    {
        var logger = new Mock<ILogger>();
        var service = new AttendanceGpsValidationService(logger.Object);
        var eventEntity = new Event
        {
            EventID = 100,
            Latitude = 10.7700m,
            Longitude = 106.7000m,
            AllowRadius = 30
        };
        var request = new CheckInRequestDto
        {
            Latitude = 10.7710m,
            Longitude = 106.7010m
        };

        var result = service.Validate(eventEntity, request, 5);

        Assert.False(result.IsValid);
        Assert.True(result.IsGpsInvalid);
        Assert.Contains("ATTENDANCE_GPS_OUT_OF_RANGE", result.InvalidReason);
        Assert.True(result.Distance > eventEntity.AllowRadius);
    }
}
