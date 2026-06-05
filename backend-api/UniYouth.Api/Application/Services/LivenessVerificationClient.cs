using System.Net.Http.Json;
using Microsoft.Extensions.Options;
using UniYouth.Api.Shared.FaceVerification;

namespace UniYouth.Api.Application.Services;

public interface ILivenessVerificationClient
{
    Task<LivenessVerificationClientResponse> CheckAsync(
        LivenessVerificationClientRequest request,
        CancellationToken cancellationToken = default);
}

public sealed class LivenessVerificationClientRequest
{
    public string RequestId { get; init; } = Guid.NewGuid().ToString("N");

    public int UserId { get; init; }

    public int EventId { get; init; }

    public string Mode { get; init; } = "passive_auto_burst";

    public int FrameCount { get; init; } = 3;

    public string MimeType { get; init; } = "image/jpeg";

    public IReadOnlyList<LivenessVerificationClientFrame> Frames { get; init; } = Array.Empty<LivenessVerificationClientFrame>();
}

public sealed class LivenessVerificationClientFrame
{
    public int FrameIndex { get; init; }

    public string ImageBase64 { get; init; } = string.Empty;

    public int CapturedAtMs { get; init; }
}

public sealed class LivenessVerificationClientResponse
{
    public const string StatusTechnicalError = "TechnicalError";

    public const string ErrorServiceUnavailable = "SERVICE_UNAVAILABLE";

    public const string ErrorTimeout = "TIMEOUT";

    public string Status { get; init; } = StatusTechnicalError;

    public bool? Passed { get; init; }

    public double? NormalizedScore { get; init; }

    public double? RawScore { get; init; }

    public int ProcessingTimeMs { get; init; }

    public string? Reason { get; init; }

    public string? ErrorCode { get; init; }

    public string? ErrorMessage { get; init; }
}

internal sealed class LivenessVerificationClient : ILivenessVerificationClient
{
    private readonly HttpClient _httpClient;
    private readonly FaceVerificationOptions _options;
    private readonly ILogger<LivenessVerificationClient> _logger;

    public LivenessVerificationClient(
        HttpClient httpClient,
        IOptions<FaceVerificationOptions> options,
        ILogger<LivenessVerificationClient> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<LivenessVerificationClientResponse> CheckAsync(
        LivenessVerificationClientRequest request,
        CancellationToken cancellationToken = default)
    {
        if (_httpClient.BaseAddress is null)
        {
            _logger.LogWarning(
                "Liveness verification skipped because service base URL is not configured. User {UserId}, Event {EventId}",
                request.UserId,
                request.EventId);

            return CreateTechnicalError(
                errorCode: LivenessVerificationClientResponse.ErrorServiceUnavailable,
                errorMessage: "Liveness verification service is not configured.");
        }

        var payload = new LivenessHttpRequestDto
        {
            RequestId = request.RequestId,
            UserId = request.UserId,
            AttendanceContext = new LivenessAttendanceContextDto
            {
                EventId = request.EventId,
                EnableFaceVerification = true,
                EnableLiveness = true
            },
            Capture = new LivenessCaptureDto
            {
                Mode = request.Mode,
                FrameCount = request.FrameCount,
                MimeType = request.MimeType
            },
            Probe = new LivenessProbeDto
            {
                Frames = request.Frames
                    .Select(frame => new LivenessProbeFrameDto
                    {
                        FrameIndex = frame.FrameIndex,
                        ImageBase64 = frame.ImageBase64,
                        CapturedAtMs = frame.CapturedAtMs
                    })
                    .ToList()
            }
        };

        try
        {
            using var response = await _httpClient.PostAsJsonAsync(
                "internal/face/liveness/check",
                payload,
                cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Liveness verification service returned HTTP {StatusCode}. RequestId {RequestId}, User {UserId}, Event {EventId}",
                    (int)response.StatusCode,
                    request.RequestId,
                    request.UserId,
                    request.EventId);

                return CreateTechnicalError(
                    errorCode: LivenessVerificationClientResponse.ErrorServiceUnavailable,
                    errorMessage: $"Liveness verification service returned HTTP {(int)response.StatusCode}.");
            }

            var content = await response.Content.ReadFromJsonAsync<LivenessHttpResponseDto>(cancellationToken: cancellationToken);
            if (content is null)
            {
                return CreateTechnicalError(
                    errorCode: LivenessVerificationClientResponse.ErrorServiceUnavailable,
                    errorMessage: "Liveness verification service returned empty response.");
            }

            return new LivenessVerificationClientResponse
            {
                Status = content.Status ?? LivenessVerificationClientResponse.StatusTechnicalError,
                Passed = content.Passed,
                NormalizedScore = content.NormalizedScore,
                RawScore = content.RawScore,
                ProcessingTimeMs = content.ProcessingTimeMs,
                Reason = content.Reason,
                ErrorCode = content.ErrorCode,
                ErrorMessage = content.ErrorMessage
            };
        }
        catch (TaskCanceledException ex) when (!cancellationToken.IsCancellationRequested)
        {
            _logger.LogWarning(
                ex,
                "Liveness verification service timed out. RequestId {RequestId}, User {UserId}, Event {EventId}",
                request.RequestId,
                request.UserId,
                request.EventId);

            return CreateTechnicalError(
                errorCode: LivenessVerificationClientResponse.ErrorTimeout,
                errorMessage: "Liveness verification service timed out.");
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning(
                ex,
                "Liveness verification service is unavailable. RequestId {RequestId}, User {UserId}, Event {EventId}",
                request.RequestId,
                request.UserId,
                request.EventId);

            return CreateTechnicalError(
                errorCode: LivenessVerificationClientResponse.ErrorServiceUnavailable,
                errorMessage: "Liveness verification service is unavailable.");
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Liveness verification failed unexpectedly. RequestId {RequestId}, User {UserId}, Event {EventId}",
                request.RequestId,
                request.UserId,
                request.EventId);

            return CreateTechnicalError(
                errorCode: "LIVENESS_TECHNICAL_ERROR",
                errorMessage: "Liveness verification failed unexpectedly.");
        }
    }

    private static LivenessVerificationClientResponse CreateTechnicalError(string errorCode, string errorMessage)
    {
        return new LivenessVerificationClientResponse
        {
            Status = LivenessVerificationClientResponse.StatusTechnicalError,
            Passed = null,
            NormalizedScore = null,
            RawScore = null,
            ProcessingTimeMs = 0,
            Reason = null,
            ErrorCode = errorCode,
            ErrorMessage = errorMessage
        };
    }

    private sealed class LivenessHttpRequestDto
    {
        public string RequestId { get; set; } = string.Empty;

        public int UserId { get; set; }

        public LivenessAttendanceContextDto AttendanceContext { get; set; } = new();

        public LivenessCaptureDto Capture { get; set; } = new();

        public LivenessProbeDto Probe { get; set; } = new();
    }

    private sealed class LivenessAttendanceContextDto
    {
        public int EventId { get; set; }

        public bool EnableFaceVerification { get; set; }

        public bool EnableLiveness { get; set; }
    }

    private sealed class LivenessCaptureDto
    {
        public string Mode { get; set; } = "passive_auto_burst";

        public int FrameCount { get; set; } = 3;

        public string MimeType { get; set; } = "image/jpeg";
    }

    private sealed class LivenessProbeDto
    {
        public List<LivenessProbeFrameDto> Frames { get; set; } = new();
    }

    private sealed class LivenessProbeFrameDto
    {
        public int FrameIndex { get; set; }

        public string ImageBase64 { get; set; } = string.Empty;

        public int CapturedAtMs { get; set; }
    }

    private sealed class LivenessHttpResponseDto
    {
        public string? Status { get; set; }

        public bool? Passed { get; set; }

        public double? NormalizedScore { get; set; }

        public double? RawScore { get; set; }

        public int ProcessingTimeMs { get; set; }

        public string? Reason { get; set; }

        public string? ErrorCode { get; set; }

        public string? ErrorMessage { get; set; }
    }
}
