using UniYouth.Api.Contracts.DTOs.Attendance;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Shared.Helpers;

namespace UniYouth.Api.Application.Services.AttendanceSupport;

public sealed class AttendanceGpsValidationService
{
    private readonly ILogger _logger;

    public AttendanceGpsValidationService(ILogger logger)
    {
        _logger = logger;
    }

    public AttendanceGpsValidationResult Validate(Event eventEntity, CheckInRequestDto request, int userId)
    {
        if (!eventEntity.Latitude.HasValue || !eventEntity.Longitude.HasValue)
        {
            _logger.LogInformation("Event {EventId} không yêu cầu GPS validation", eventEntity.EventID);
            return new AttendanceGpsValidationResult(true, false, null, 0d);
        }

        var distance = GpsDistanceHelper.CalculateDistance(
            request.Latitude,
            request.Longitude,
            eventEntity.Latitude.Value,
            eventEntity.Longitude.Value);

        if (distance <= eventEntity.AllowRadius)
        {
            return new AttendanceGpsValidationResult(true, false, null, distance);
        }

        _logger.LogWarning(
            "Điểm danh không hợp lệ (GPS): Distance {Distance}m > Allowed {Allowed}m. Event {EventId}, User {UserId}",
            distance,
            eventEntity.AllowRadius,
            eventEntity.EventID,
            userId);

        return new AttendanceGpsValidationResult(
            false,
            true,
            AttendanceRetryPolicyService.BuildErrorMessage(
                AttendanceErrorCodes.GpsOutOfRange,
                $"Vị trí quá xa ({distance:F0}m). Phạm vi cho phép: {eventEntity.AllowRadius}m"),
            distance);
    }
}

public sealed record AttendanceGpsValidationResult(
    bool IsValid,
    bool IsGpsInvalid,
    string? InvalidReason,
    double Distance);
