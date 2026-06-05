using UniYouth.Api.Contracts.DTOs.Attendance;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Shared.FaceVerification;

namespace UniYouth.Api.Application.Services.AttendanceSupport;

public sealed class AttendanceBiometricService
{
    private readonly IFaceProfileSelectionService _faceProfileSelectionService;
    private readonly IFaceVerificationClient _faceVerificationClient;
    private readonly ILivenessVerificationClient _livenessVerificationClient;
    private readonly ILogger _logger;
    private readonly FaceVerificationOptions _options;

    public AttendanceBiometricService(
        IFaceProfileSelectionService faceProfileSelectionService,
        IFaceVerificationClient faceVerificationClient,
        ILivenessVerificationClient livenessVerificationClient,
        ILogger logger,
        FaceVerificationOptions options)
    {
        _faceProfileSelectionService = faceProfileSelectionService;
        _faceVerificationClient = faceVerificationClient;
        _livenessVerificationClient = livenessVerificationClient;
        _logger = logger;
        _options = options;
    }

    public async Task<FaceVerificationOutcome> ResolveFaceVerificationAsync(Event eventEntity, int userId, CheckInRequestDto request)
    {
        if (!eventEntity.EnableFaceVerification)
        {
            return FaceVerificationOutcome.NotRequested();
        }

        if (string.IsNullOrWhiteSpace(request.FaceImageBase64))
        {
            return FaceVerificationOutcome.PayloadMissing();
        }

        if (!string.Equals(request.FaceImageMimeType, "image/jpeg", StringComparison.OrdinalIgnoreCase))
        {
            return FaceVerificationOutcome.InvalidPayload(
                _options.Service.Provider,
                _options.Service.Model,
                _options.Service.Version,
                "FACE_INVALID_PAYLOAD",
                "Unsupported face image mime type.");
        }

        try
        {
            var imageBytes = Convert.FromBase64String(request.FaceImageBase64);
            if (imageBytes.Length == 0 || imageBytes.Length > 300 * 1024)
            {
                return FaceVerificationOutcome.InvalidPayload(
                    _options.Service.Provider,
                    _options.Service.Model,
                    _options.Service.Version,
                    "FACE_INVALID_PAYLOAD",
                    "Face image size is invalid.");
            }
        }
        catch (FormatException)
        {
            return FaceVerificationOutcome.InvalidPayload(
                _options.Service.Provider,
                _options.Service.Model,
                _options.Service.Version,
                "FACE_INVALID_PAYLOAD",
                "Face image is not valid base64.");
        }

        var faceProfileSelection = await _faceProfileSelectionService.ResolveActiveProfileAsync(userId);
        if (!faceProfileSelection.HasUsableProfile)
        {
            return FaceVerificationOutcome.ProfileMissing(
                _options.Service.Provider,
                _options.Service.Model,
                _options.Service.Version);
        }

        var faceProfile = faceProfileSelection.FaceProfile!;
        var probeCandidates = BuildFaceProbeCandidates(request);
        var outcomes = new List<FaceVerificationOutcome>(probeCandidates.Count);

        foreach (var probeCandidate in probeCandidates)
        {
            var requestId = $"attendance-{eventEntity.EventID}-{userId}-{Guid.NewGuid():N}";
            var faceResponse = await _faceVerificationClient.VerifyAsync(new FaceVerificationClientRequest
            {
                RequestId = requestId,
                UserId = userId,
                EventId = eventEntity.EventID,
                FaceProfileId = faceProfile.FaceProfileID,
                Algorithm = faceProfile.Algorithm ?? _options.Service.Model ?? "ArcFace",
                Version = faceProfile.Version,
                ReferenceEmbedding = faceProfile.FaceEmbedding,
                FaceImageBase64 = probeCandidate.ImageBase64,
                FaceImageMimeType = probeCandidate.MimeType
            });

            outcomes.Add(FaceVerificationOutcome
                .FromClientResponse(faceProfile.FaceProfileID, faceResponse)
                .WithProbeSource(probeCandidate.Source));
        }

        var selectedOutcome = SelectBestFaceVerificationOutcome(outcomes);
        if (probeCandidates.Count > 1)
        {
            _logger.LogInformation(
                "Face verification selected candidate. User {UserId}, Event {EventId}, Source {Source}, Status {Status}, Confidence {Confidence}, Quality {Quality}",
                userId,
                eventEntity.EventID,
                selectedOutcome.ProbeSource ?? "primary",
                selectedOutcome.FaceVerificationStatus ?? "Unknown",
                selectedOutcome.FaceConfidence,
                selectedOutcome.QualityScore);
        }

        return selectedOutcome;
    }

    public async Task<LivenessVerificationOutcome> ResolveLivenessVerificationAsync(Event eventEntity, int userId, CheckInRequestDto request)
    {
        const int minBurstDurationMs = 400;
        const int maxBurstDurationMs = 4000;
        const int minInterFrameGapMs = 120;
        const int maxInterFrameGapMs = 2500;

        if (!eventEntity.EnableFaceVerification)
        {
            return LivenessVerificationOutcome.NotRequested();
        }

        var liveness = request.Liveness;
        if (liveness is null)
        {
            return LivenessVerificationOutcome.NotRequested();
        }

        if (!string.Equals(liveness.Mode, "passive_auto_burst", StringComparison.Ordinal))
        {
            return LivenessVerificationOutcome.InvalidPayload("Liveness mode is invalid.");
        }

        if (liveness.FrameCount != 3)
        {
            return LivenessVerificationOutcome.InvalidPayload("Liveness frame count must be exactly 3.");
        }

        if (!string.Equals(liveness.MimeType, "image/jpeg", StringComparison.OrdinalIgnoreCase))
        {
            return LivenessVerificationOutcome.InvalidPayload("Unsupported liveness mime type.");
        }

        var frames = liveness.Frames;
        if (frames is null || frames.Count != 3)
        {
            return LivenessVerificationOutcome.InvalidPayload("Liveness frames must contain exactly 3 items.");
        }

        var orderedFrames = frames.OrderBy(frame => frame.FrameIndex).ToList();
        if (!orderedFrames.Select((frame, index) => frame.FrameIndex == index).All(static isExpected => isExpected))
        {
            return LivenessVerificationOutcome.InvalidPayload("Liveness frame index is invalid.");
        }

        var previousCapturedAtMs = -1;
        var totalPayloadBytes = 0;
        var firstCapturedAtMs = -1;

        foreach (var frame in orderedFrames)
        {
            if (string.IsNullOrWhiteSpace(frame.ImageBase64))
            {
                return LivenessVerificationOutcome.InvalidPayload("Liveness frame image payload is missing.");
            }

            if (frame.CapturedAtMs < 0 || frame.CapturedAtMs < previousCapturedAtMs)
            {
                return LivenessVerificationOutcome.InvalidPayload("Liveness capturedAtMs is invalid.");
            }

            if (previousCapturedAtMs >= 0)
            {
                var interFrameGapMs = frame.CapturedAtMs - previousCapturedAtMs;
                if (interFrameGapMs < minInterFrameGapMs || interFrameGapMs > maxInterFrameGapMs)
                {
                    return LivenessVerificationOutcome.InvalidPayload("Liveness frame timing is invalid.");
                }
            }

            try
            {
                var imageBytes = Convert.FromBase64String(frame.ImageBase64);
                if (imageBytes.Length == 0 || imageBytes.Length > 150 * 1024)
                {
                    return LivenessVerificationOutcome.InvalidPayload("Liveness frame size is invalid.");
                }

                totalPayloadBytes += imageBytes.Length;
            }
            catch (FormatException)
            {
                return LivenessVerificationOutcome.InvalidPayload("Liveness frame is not valid base64.");
            }

            if (firstCapturedAtMs < 0)
            {
                firstCapturedAtMs = frame.CapturedAtMs;
            }

            previousCapturedAtMs = frame.CapturedAtMs;
        }

        if (totalPayloadBytes > 450 * 1024)
        {
            return LivenessVerificationOutcome.InvalidPayload("Liveness payload exceeds burst guardrail.");
        }

        var burstDurationMs = orderedFrames[^1].CapturedAtMs - firstCapturedAtMs;
        if (burstDurationMs < minBurstDurationMs || burstDurationMs > maxBurstDurationMs)
        {
            return LivenessVerificationOutcome.InvalidPayload("Liveness burst duration is invalid.");
        }

        var requestId = $"attendance-liveness-{eventEntity.EventID}-{userId}-{Guid.NewGuid():N}";
        var livenessResponse = await _livenessVerificationClient.CheckAsync(new LivenessVerificationClientRequest
        {
            RequestId = requestId,
            UserId = userId,
            EventId = eventEntity.EventID,
            Mode = liveness.Mode!,
            FrameCount = liveness.FrameCount.Value,
            MimeType = liveness.MimeType ?? "image/jpeg",
            Frames = orderedFrames.Select(frame => new LivenessVerificationClientFrame
            {
                FrameIndex = frame.FrameIndex,
                ImageBase64 = frame.ImageBase64,
                CapturedAtMs = frame.CapturedAtMs
            }).ToList()
        });

        return LivenessVerificationOutcome.FromClientResponse(livenessResponse);
    }

    public static List<FaceProbeCandidate> BuildFaceProbeCandidates(CheckInRequestDto request)
    {
        var candidates = new List<FaceProbeCandidate>();
        var seenPayloads = new HashSet<string>(StringComparer.Ordinal);

        if (!string.IsNullOrWhiteSpace(request.FaceImageBase64))
        {
            var normalized = request.FaceImageBase64.Trim();
            if (seenPayloads.Add(normalized))
            {
                candidates.Add(new FaceProbeCandidate("primary", normalized, request.FaceImageMimeType ?? "image/jpeg"));
            }
        }

        if (request.Liveness?.Frames is { Count: > 0 } frames)
        {
            var mimeType = request.Liveness.MimeType ?? "image/jpeg";
            foreach (var frame in frames.OrderBy(frame => frame.FrameIndex))
            {
                if (string.IsNullOrWhiteSpace(frame.ImageBase64))
                {
                    continue;
                }

                var normalized = frame.ImageBase64.Trim();
                if (!seenPayloads.Add(normalized))
                {
                    continue;
                }

                candidates.Add(new FaceProbeCandidate($"liveness-{frame.FrameIndex}", normalized, mimeType));
            }
        }

        return candidates;
    }

    public static FaceVerificationOutcome SelectBestFaceVerificationOutcome(IReadOnlyCollection<FaceVerificationOutcome> outcomes)
    {
        return outcomes
            .OrderByDescending(GetFaceOutcomeRank)
            .ThenByDescending(outcome => outcome.QualityScore ?? double.MinValue)
            .ThenByDescending(outcome => outcome.FaceConfidence ?? double.MinValue)
            .ThenBy(outcome => outcome.ProcessingTimeMs ?? int.MaxValue)
            .FirstOrDefault()
            ?? FaceVerificationOutcome.PayloadMissing();
    }

    private static int GetFaceOutcomeRank(FaceVerificationOutcome outcome)
    {
        return outcome.FaceVerificationStatus switch
        {
            "Matched" => 7,
            "Review" => 6,
            "Mismatch" => 5,
            "BlurryImage" => 4,
            "NoFaceDetected" => 3,
            "MultipleFacesDetected" => 2,
            "InvalidPayload" => 1,
            "TechnicalError" => 0,
            _ => -1
        };
    }
}

public sealed record FaceProbeCandidate(string Source, string ImageBase64, string MimeType);

public sealed class FaceVerificationOutcome
{
    public bool? FaceVerified { get; init; }
    public double? FaceConfidence { get; init; }
    public string? FaceVerificationStatus { get; init; }
    public string? FaceVerificationMessage { get; init; }
    public string? Provider { get; init; }
    public string? Model { get; init; }
    public string? Version { get; init; }
    public int? FaceProfileId { get; init; }
    public double? RawScore { get; init; }
    public double? QualityScore { get; init; }
    public double? Threshold { get; init; }
    public int? ProcessingTimeMs { get; init; }
    public string? ProbeSource { get; init; }
    public string? ErrorCode { get; init; }
    public string? ErrorMessage { get; init; }
    public bool ShouldCreateFaceLog { get; init; }
    public bool? IsMatchedForLog { get; init; }

    public static FaceVerificationOutcome NotRequested() => new() { FaceVerificationStatus = "NotRequested", ShouldCreateFaceLog = false };

    public static FaceVerificationOutcome PayloadMissing() => new()
    {
        FaceVerificationStatus = "PayloadMissing",
        FaceVerificationMessage = "Ảnh khuôn mặt chưa được gửi lên.",
        ErrorCode = "FACE_PAYLOAD_MISSING",
        ErrorMessage = "Face image payload was not provided.",
        ShouldCreateFaceLog = true
    };

    public static FaceVerificationOutcome InvalidPayload(string? provider, string? model, string? version, string errorCode, string errorMessage) => new()
    {
        FaceVerificationStatus = "InvalidPayload",
        FaceVerificationMessage = "Ảnh khuôn mặt gửi lên không hợp lệ.",
        Provider = provider,
        Model = model,
        Version = version,
        ErrorCode = errorCode,
        ErrorMessage = errorMessage,
        ShouldCreateFaceLog = true
    };

    public static FaceVerificationOutcome ProfileMissing(string? provider, string? model, string? version) => new()
    {
        FaceVerificationStatus = "ProfileMissing",
        FaceVerificationMessage = "Tài khoản chưa có hồ sơ khuôn mặt.",
        Provider = provider,
        Model = model,
        Version = version,
        ErrorCode = "FACE_PROFILE_MISSING",
        ErrorMessage = "No active usable FaceProfile found.",
        ShouldCreateFaceLog = true
    };

    public static FaceVerificationOutcome FromClientResponse(int faceProfileId, FaceVerificationClientResponse response)
    {
        return response.Status switch
        {
            "Matched" => new FaceVerificationOutcome
            {
                FaceVerified = true,
                FaceConfidence = response.NormalizedConfidence,
                FaceVerificationStatus = "Matched",
                FaceVerificationMessage = "Điểm danh thành công. Khuôn mặt đã được xác minh.",
                Provider = response.Provider,
                Model = response.Model,
                Version = response.Version,
                FaceProfileId = faceProfileId,
                RawScore = response.RawScore,
                QualityScore = response.QualityScore,
                Threshold = response.Threshold,
                ProcessingTimeMs = response.ProcessingTimeMs,
                ErrorCode = response.ErrorCode,
                ErrorMessage = response.ErrorMessage,
                ShouldCreateFaceLog = true,
                IsMatchedForLog = true
            },
            "Review" => new FaceVerificationOutcome
            {
                FaceVerified = false,
                FaceConfidence = response.NormalizedConfidence,
                FaceVerificationStatus = "Review",
                FaceVerificationMessage = "Khuôn mặt chưa đủ mạnh để xác nhận chắc chắn.",
                Provider = response.Provider,
                Model = response.Model,
                Version = response.Version,
                FaceProfileId = faceProfileId,
                RawScore = response.RawScore,
                QualityScore = response.QualityScore,
                Threshold = response.Threshold,
                ProcessingTimeMs = response.ProcessingTimeMs,
                ErrorCode = response.ErrorCode,
                ErrorMessage = response.ErrorMessage,
                ShouldCreateFaceLog = true,
                IsMatchedForLog = false
            },
            "Mismatch" => new FaceVerificationOutcome
            {
                FaceVerified = false,
                FaceConfidence = response.NormalizedConfidence,
                FaceVerificationStatus = "Mismatch",
                FaceVerificationMessage = "Khuôn mặt không khớp hồ sơ đã đăng ký.",
                Provider = response.Provider,
                Model = response.Model,
                Version = response.Version,
                FaceProfileId = faceProfileId,
                RawScore = response.RawScore,
                QualityScore = response.QualityScore,
                Threshold = response.Threshold,
                ProcessingTimeMs = response.ProcessingTimeMs,
                ErrorCode = response.ErrorCode,
                ErrorMessage = response.ErrorMessage,
                ShouldCreateFaceLog = true,
                IsMatchedForLog = false
            },
            "NoFaceDetected" => CreateInputIssue(faceProfileId, response, "NoFaceDetected", "Không phát hiện khuôn mặt hợp lệ trong ảnh."),
            "MultipleFacesDetected" => CreateInputIssue(faceProfileId, response, "MultipleFacesDetected", "Ảnh chứa nhiều khuôn mặt, không thể xác minh."),
            "BlurryImage" => CreateInputIssue(faceProfileId, response, "BlurryImage", "Ảnh khuôn mặt bị mờ, không đủ chất lượng để xác minh."),
            "InvalidPayload" => CreateInputIssue(faceProfileId, response, "InvalidPayload", "Ảnh khuôn mặt gửi lên không hợp lệ."),
            _ => new FaceVerificationOutcome
            {
                FaceVerificationStatus = "TechnicalError",
                FaceVerificationMessage = response.ErrorCode is FaceVerificationClientResponse.ErrorTimeout or "FACE_TIMEOUT"
                    ? "Xác minh khuôn mặt tạm thời bị chậm hoặc hết thời gian chờ."
                    : "Dịch vụ xác minh khuôn mặt tạm thời không khả dụng.",
                Provider = response.Provider,
                Model = response.Model,
                Version = response.Version,
                FaceProfileId = faceProfileId,
                RawScore = response.RawScore,
                QualityScore = response.QualityScore,
                Threshold = response.Threshold,
                ProcessingTimeMs = response.ProcessingTimeMs,
                ErrorCode = response.ErrorCode,
                ErrorMessage = response.ErrorMessage,
                ShouldCreateFaceLog = true
            }
        };
    }

    public FaceVerificationOutcome WithProbeSource(string probeSource)
    {
        return new FaceVerificationOutcome
        {
            FaceVerified = FaceVerified,
            FaceConfidence = FaceConfidence,
            FaceVerificationStatus = FaceVerificationStatus,
            FaceVerificationMessage = FaceVerificationMessage,
            Provider = Provider,
            Model = Model,
            Version = Version,
            FaceProfileId = FaceProfileId,
            RawScore = RawScore,
            QualityScore = QualityScore,
            Threshold = Threshold,
            ProcessingTimeMs = ProcessingTimeMs,
            ProbeSource = probeSource,
            ErrorCode = ErrorCode,
            ErrorMessage = ErrorMessage,
            ShouldCreateFaceLog = ShouldCreateFaceLog,
            IsMatchedForLog = IsMatchedForLog
        };
    }

    private static FaceVerificationOutcome CreateInputIssue(int faceProfileId, FaceVerificationClientResponse response, string status, string message)
    {
        return new FaceVerificationOutcome
        {
            FaceVerificationStatus = status,
            FaceVerificationMessage = message,
            Provider = response.Provider,
            Model = response.Model,
            Version = response.Version,
            FaceProfileId = faceProfileId,
            RawScore = response.RawScore,
            QualityScore = response.QualityScore,
            Threshold = response.Threshold,
            ProcessingTimeMs = response.ProcessingTimeMs,
            ErrorCode = response.ErrorCode,
            ErrorMessage = response.ErrorMessage,
            ShouldCreateFaceLog = true
        };
    }
}

public sealed class LivenessVerificationOutcome
{
    public string? LivenessStatus { get; init; }
    public bool? LivenessPassed { get; init; }
    public double? LivenessScore { get; init; }
    public string? LivenessReason { get; init; }

    public static LivenessVerificationOutcome NotRequested() => new() { LivenessStatus = "NotRequested" };

    public static LivenessVerificationOutcome InvalidPayload(string errorMessage) => new()
    {
        LivenessStatus = "InvalidPayload",
        LivenessPassed = null,
        LivenessScore = null,
        LivenessReason = ResolveReason(null, errorMessage, "Điểm danh đã được ghi nhận. Dữ liệu liveness gửi lên không hợp lệ.")
    };

    public static LivenessVerificationOutcome FromClientResponse(LivenessVerificationClientResponse response)
    {
        return response.Status switch
        {
            "Passed" => new LivenessVerificationOutcome
            {
                LivenessStatus = "Passed",
                LivenessPassed = true,
                LivenessScore = response.NormalizedScore,
                LivenessReason = ResolveReason(response.Reason, response.ErrorMessage, "Điểm danh đã được ghi nhận. Liveness đã xác nhận khuôn mặt là người thật.")
            },
            "Failed" => new LivenessVerificationOutcome
            {
                LivenessStatus = "Failed",
                LivenessPassed = false,
                LivenessScore = response.NormalizedScore,
                LivenessReason = ResolveReason(response.Reason, response.ErrorMessage, "Điểm danh đã được ghi nhận. Tín hiệu liveness không đạt.")
            },
            "Review" => CreateSoftIssue(response, "Điểm danh đã được ghi nhận. Liveness chưa đủ mạnh để kết luận chắc chắn."),
            "NoFaceDetected" => CreateSoftIssue(response, "Điểm danh đã được ghi nhận. Không phát hiện được khuôn mặt hợp lệ trong burst liveness."),
            "MultipleFacesDetected" => CreateSoftIssue(response, "Điểm danh đã được ghi nhận. Burst liveness chứa nhiều khuôn mặt."),
            "BlurryImage" => CreateSoftIssue(response, "Điểm danh đã được ghi nhận. Burst liveness chưa đủ rõ để đánh giá."),
            "InvalidPayload" => CreateSoftIssue(response, "Điểm danh đã được ghi nhận. Dữ liệu liveness gửi lên không hợp lệ."),
            _ => new LivenessVerificationOutcome
            {
                LivenessStatus = "TechnicalError",
                LivenessPassed = null,
                LivenessScore = response.NormalizedScore,
                LivenessReason = ResolveReason(
                    response.Reason,
                    response.ErrorMessage,
                    response.ErrorCode is LivenessVerificationClientResponse.ErrorTimeout or "LIVENESS_TIMEOUT"
                        ? "Điểm danh đã được ghi nhận. Dịch vụ liveness tạm thời bị chậm hoặc hết thời gian chờ."
                        : "Điểm danh đã được ghi nhận. Dịch vụ liveness tạm thời không khả dụng.")
            }
        };
    }

    private static LivenessVerificationOutcome CreateSoftIssue(LivenessVerificationClientResponse response, string fallbackReason)
    {
        return new LivenessVerificationOutcome
        {
            LivenessStatus = response.Status,
            LivenessPassed = null,
            LivenessScore = response.NormalizedScore,
            LivenessReason = ResolveReason(response.Reason, response.ErrorMessage, fallbackReason)
        };
    }

    private static string ResolveReason(string? reason, string? errorMessage, string fallbackReason)
    {
        var localizedReason = TryLocalizeReason(reason);
        if (!string.IsNullOrWhiteSpace(localizedReason))
        {
            return localizedReason;
        }

        var localizedError = TryLocalizeReason(errorMessage);
        if (!string.IsNullOrWhiteSpace(localizedError))
        {
            return localizedError;
        }

        return fallbackReason;
    }

    private static string? TryLocalizeReason(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return null;
        }

        return value.Trim() switch
        {
            "Passive liveness passed." => "Điểm danh đã được ghi nhận. Liveness đã xác nhận khuôn mặt là người thật.",
            "Passive liveness requires review." => "Điểm danh đã được ghi nhận. Liveness chưa đủ mạnh để kết luận chắc chắn.",
            "Passive liveness failed." => "Điểm danh đã được ghi nhận. Tín hiệu liveness không đạt.",
            "Passive liveness failed due to insufficient burst variation." => "Điểm danh đã được ghi nhận. Burst liveness chưa có đủ biến thiên để xác nhận người thật.",
            "No face detected." => "Điểm danh đã được ghi nhận. Không phát hiện được khuôn mặt hợp lệ trong burst liveness.",
            "Multiple faces detected." => "Điểm danh đã được ghi nhận. Burst liveness chứa nhiều khuôn mặt.",
            "Face image is too blurry." => "Điểm danh đã được ghi nhận. Burst liveness chưa đủ rõ để đánh giá.",
            "Liveness face position is invalid." => "Điểm danh đã được ghi nhận. Giữ khuôn mặt ở giữa khung trong suốt burst liveness rồi thử lại.",
            "Liveness face size is invalid." => "Điểm danh đã được ghi nhận. Điều chỉnh khoảng cách khuôn mặt để khung liveness nhận diện rõ hơn.",
            "Liveness frame brightness is invalid." => "Điểm danh đã được ghi nhận. Điều kiện ánh sáng của burst liveness chưa phù hợp.",
            "Liveness mode is invalid." => "Điểm danh đã được ghi nhận. Kiểu burst liveness gửi lên không hợp lệ.",
            "Liveness frame count must be exactly 3." => "Điểm danh đã được ghi nhận. Burst liveness phải gồm đúng 3 frame.",
            "Unsupported liveness mime type." => "Điểm danh đã được ghi nhận. Định dạng burst liveness chưa được hỗ trợ.",
            "Liveness frames must contain exactly 3 items." => "Điểm danh đã được ghi nhận. Burst liveness phải gồm đúng 3 frame.",
            "Liveness frame index is invalid." => "Điểm danh đã được ghi nhận. Thứ tự frame liveness không hợp lệ.",
            "Liveness frame image payload is missing." => "Điểm danh đã được ghi nhận. Thiếu dữ liệu ảnh trong burst liveness.",
            "Liveness capturedAtMs is invalid." => "Điểm danh đã được ghi nhận. Mốc thời gian burst liveness không hợp lệ.",
            "Liveness frame timing is invalid." => "Điểm danh đã được ghi nhận. Nhịp chụp burst liveness chưa ổn định.",
            "Liveness frame size is invalid." => "Điểm danh đã được ghi nhận. Kích thước một frame liveness không hợp lệ.",
            "Liveness frame is not valid base64." => "Điểm danh đã được ghi nhận. Dữ liệu frame liveness không hợp lệ.",
            "Liveness payload exceeds burst guardrail." => "Điểm danh đã được ghi nhận. Dữ liệu burst liveness vượt giới hạn cho phép.",
            "Liveness burst duration is invalid." => "Điểm danh đã được ghi nhận. Tổng thời gian burst liveness chưa phù hợp.",
            "Liveness verification service timed out." => "Điểm danh đã được ghi nhận. Dịch vụ liveness tạm thời bị chậm hoặc hết thời gian chờ.",
            "Liveness verification service is unavailable." => "Điểm danh đã được ghi nhận. Dịch vụ liveness tạm thời không khả dụng.",
            "Liveness verification failed unexpectedly." => "Điểm danh đã được ghi nhận. Dịch vụ liveness tạm thời không khả dụng.",
            _ => null
        };
    }
}
