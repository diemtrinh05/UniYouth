using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Infrastructure.Data;

namespace UniYouth.Api.Application.Services;

public interface IAttendanceRiskScoringService
{
    Task<AttendanceRiskScoringResult> ScoreAsync(
        AttendanceRiskScoringContext context,
        CancellationToken cancellationToken = default);
}

public sealed class AttendanceRiskScoringContext
{
    public int EventId { get; init; }

    public int UserId { get; init; }

    public DateTime CheckInTime { get; init; }

    public bool IsGpsInvalid { get; init; }

    public string? FaceVerificationStatus { get; init; }

    public string? LivenessStatus { get; init; }

    public bool? LivenessPassed { get; init; }

    public string? ClientDeviceId { get; init; }

    public string? IPAddress { get; init; }
}

public sealed class AttendanceRiskScoringResult
{
    public int RiskScore { get; init; }

    public string RiskLevel { get; init; } = "Low";

    public string RiskReasonsJson { get; init; } = "[]";

    public IReadOnlyList<AttendanceRiskSignal> Signals { get; init; } = Array.Empty<AttendanceRiskSignal>();

    public static AttendanceRiskScoringResult DefaultLowRisk() => new()
    {
        RiskScore = 0,
        RiskLevel = "Low",
        RiskReasonsJson = "[]",
        Signals = Array.Empty<AttendanceRiskSignal>()
    };
}

public sealed class AttendanceRiskSignal
{
    public string Code { get; init; } = string.Empty;

    public int Score { get; init; }

    public string Description { get; init; } = string.Empty;
}

public sealed class AttendanceRiskScoringService : IAttendanceRiskScoringService
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase
    };

    private readonly UniYouthDbContext _context;

    public AttendanceRiskScoringService(UniYouthDbContext context)
    {
        _context = context;
    }

    public async Task<AttendanceRiskScoringResult> ScoreAsync(
        AttendanceRiskScoringContext context,
        CancellationToken cancellationToken = default)
    {
        var signals = new List<AttendanceRiskSignal>();

        AddFaceSignal(signals, context.FaceVerificationStatus);
        AddLivenessSignal(signals, context.LivenessStatus, context.LivenessPassed);

        if (context.IsGpsInvalid)
        {
            signals.Add(new AttendanceRiskSignal
            {
                Code = "GPS_INVALID",
                Score = 30,
                Description = "Vị trí check-in vượt quá bán kính cho phép."
            });
        }

        var clientDeviceId = Normalize(context.ClientDeviceId);
        if (!string.IsNullOrEmpty(clientDeviceId))
        {
            var sharedDeviceUsers = await _context.Attendances
                .AsNoTracking()
                .Where(a =>
                    a.ClientDeviceId == clientDeviceId &&
                    a.UserID != context.UserId &&
                    a.CheckInTime.HasValue &&
                    a.CheckInTime.Value >= context.CheckInTime.AddDays(-30) &&
                    a.CheckInTime.Value <= context.CheckInTime)
                .Select(a => a.UserID)
                .Distinct()
                .CountAsync(cancellationToken);

            if (sharedDeviceUsers >= 2)
            {
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "SHARED_CLIENT_DEVICE_ID",
                    Score = 40,
                    Description = "ClientDeviceId xuất hiện ở ít nhất 2 user khác trong 30 ngày gần nhất."
                });
            }
        }

        var ipAddress = Normalize(context.IPAddress);
        if (!string.IsNullOrEmpty(ipAddress))
        {
            var sharedIpUsers = await _context.Attendances
                .AsNoTracking()
                .Where(a =>
                    a.EventID == context.EventId &&
                    a.IPAddress == ipAddress &&
                    a.UserID != context.UserId &&
                    a.CheckInTime.HasValue &&
                    a.CheckInTime.Value >= context.CheckInTime.AddMinutes(-10) &&
                    a.CheckInTime.Value <= context.CheckInTime)
                .Select(a => a.UserID)
                .Distinct()
                .CountAsync(cancellationToken);

            if (sharedIpUsers >= 3)
            {
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "SHARED_IP_BURST",
                    Score = 20,
                    Description = "Cùng IP đã được ít nhất 3 user khác dùng để check-in cùng event trong 10 phút gần nhất."
                });
            }
        }

        var riskScore = signals.Sum(signal => signal.Score);
        var riskLevel = MapRiskLevel(riskScore);

        return new AttendanceRiskScoringResult
        {
            RiskScore = riskScore,
            RiskLevel = riskLevel,
            RiskReasonsJson = JsonSerializer.Serialize(signals, JsonOptions),
            Signals = signals
        };
    }

    private static void AddFaceSignal(ICollection<AttendanceRiskSignal> signals, string? faceVerificationStatus)
    {
        switch (faceVerificationStatus)
        {
            case "Matched":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "FACE_MATCHED",
                    Score = 0,
                    Description = "Khuôn mặt khớp hồ sơ."
                });
                break;
            case "Review":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "FACE_REVIEW",
                    Score = 20,
                    Description = "Khuôn mặt ở vùng confidence review."
                });
                break;
            case "Mismatch":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "FACE_MISMATCH",
                    Score = 60,
                    Description = "Khuôn mặt không khớp hồ sơ."
                });
                break;
            case "NoFaceDetected":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "FACE_NO_FACE",
                    Score = 25,
                    Description = "Không phát hiện khuôn mặt usable."
                });
                break;
            case "MultipleFacesDetected":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "FACE_MULTIPLE_FACES",
                    Score = 25,
                    Description = "Ảnh chứa nhiều khuôn mặt."
                });
                break;
            case "BlurryImage":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "FACE_BLURRY",
                    Score = 25,
                    Description = "Ảnh khuôn mặt bị mờ."
                });
                break;
            case "PayloadMissing":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "FACE_PAYLOAD_MISSING",
                    Score = 25,
                    Description = "Event bật face nhưng request không gửi ảnh."
                });
                break;
            case "InvalidPayload":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "FACE_INVALID_PAYLOAD",
                    Score = 25,
                    Description = "Payload ảnh khuôn mặt không hợp lệ."
                });
                break;
            case "ProfileMissing":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "FACE_PROFILE_MISSING",
                    Score = 10,
                    Description = "Không có FaceProfile usable cho user."
                });
                break;
            case "TechnicalError":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "FACE_TECHNICAL_ERROR",
                    Score = 0,
                    Description = "Lỗi kỹ thuật của face verification."
                });
                break;
            case "NotRequested":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "NotRequested",
                    Score = 0,
                    Description = "Event không yêu cầu face verification."
                });
                break;
        }
    }

    private static void AddLivenessSignal(
        ICollection<AttendanceRiskSignal> signals,
        string? livenessStatus,
        bool? livenessPassed)
    {
        switch (livenessStatus)
        {
            case "Passed":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "LIVENESS_PASSED",
                    Score = 0,
                    Description = "Liveness xác nhận khuôn mặt là người thật."
                });
                break;
            case "Failed":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "LIVENESS_FAILED",
                    Score = 70,
                    Description = "Liveness phát hiện tín hiệu spoof rõ ràng."
                });
                break;
            case "Review":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "LIVENESS_REVIEW",
                    Score = 20,
                    Description = "Liveness chưa đủ mạnh để kết luận chắc chắn."
                });
                break;
            case "NoFaceDetected":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "LIVENESS_NO_FACE",
                    Score = 25,
                    Description = "Burst liveness không có khuôn mặt usable."
                });
                break;
            case "MultipleFacesDetected":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "LIVENESS_MULTIPLE_FACES",
                    Score = 25,
                    Description = "Burst liveness chứa nhiều khuôn mặt."
                });
                break;
            case "BlurryImage":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "LIVENESS_BLURRY",
                    Score = 25,
                    Description = "Burst liveness quá mờ để đánh giá."
                });
                break;
            case "InvalidPayload":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "LIVENESS_INVALID_PAYLOAD",
                    Score = 25,
                    Description = "Payload liveness không hợp lệ."
                });
                break;
            case "TechnicalError":
                signals.Add(new AttendanceRiskSignal
                {
                    Code = "LIVENESS_TECHNICAL_ERROR",
                    Score = 0,
                    Description = "Liveness gặp lỗi kỹ thuật, không dùng làm tín hiệu gian lận."
                });
                break;
            case "NotRequested":
                if (livenessPassed == true)
                {
                    signals.Add(new AttendanceRiskSignal
                    {
                        Code = "LIVENESS_PASSED",
                        Score = 0,
                        Description = "Liveness xác nhận khuôn mặt là người thật."
                    });
                }
                else if (livenessPassed == false)
                {
                    signals.Add(new AttendanceRiskSignal
                    {
                        Code = "LIVENESS_FAILED",
                        Score = 70,
                        Description = "Liveness phát hiện tín hiệu spoof rõ ràng."
                    });
                }
                break;
        }
    }

    private static string MapRiskLevel(int riskScore)
    {
        if (riskScore >= 90)
        {
            return "Critical";
        }

        if (riskScore >= 50)
        {
            return "High";
        }

        if (riskScore >= 20)
        {
            return "Medium";
        }

        return "Low";
    }

    private static string? Normalize(string? value)
    {
        return string.IsNullOrWhiteSpace(value) ? null : value.Trim();
    }
}
