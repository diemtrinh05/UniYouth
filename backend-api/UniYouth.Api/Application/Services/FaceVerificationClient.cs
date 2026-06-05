using System.Net.Http.Json;
using Microsoft.Extensions.Options;
using UniYouth.Api.Shared.FaceVerification;

namespace UniYouth.Api.Application.Services;

public interface IFaceVerificationClient
{
    Task<FaceVerificationClientResponse> VerifyAsync(
        FaceVerificationClientRequest request,
        CancellationToken cancellationToken = default);
}

public sealed class FaceVerificationClientRequest
{
    public string RequestId { get; init; } = Guid.NewGuid().ToString("N");

    public int UserId { get; init; }

    public int EventId { get; init; }

    public int FaceProfileId { get; init; }

    public string Algorithm { get; init; } = "ArcFace";

    public string? Version { get; init; }

    public byte[] ReferenceEmbedding { get; init; } = Array.Empty<byte>();

    public string FaceImageBase64 { get; init; } = string.Empty;

    public string FaceImageMimeType { get; init; } = "image/jpeg";
}

public sealed class FaceVerificationClientResponse
{
    public const string StatusTechnicalError = "TechnicalError";

    public const string ErrorServiceUnavailable = "SERVICE_UNAVAILABLE";

    public const string ErrorTimeout = "TIMEOUT";

    public string Provider { get; init; } = string.Empty;

    public string Model { get; init; } = string.Empty;

    public string Version { get; init; } = string.Empty;

    public string Status { get; init; } = StatusTechnicalError;

    public bool Matched { get; init; }

    public double? NormalizedConfidence { get; init; }

    public double? RawScore { get; init; }

    public double? QualityScore { get; init; }

    public double? Threshold { get; init; }

    public int ProcessingTimeMs { get; init; }

    public string? ErrorCode { get; init; }

    public string? ErrorMessage { get; init; }
}

internal sealed class FaceVerificationClient : IFaceVerificationClient
{
    private readonly HttpClient _httpClient;
    private readonly FaceVerificationOptions _options;
    private readonly ILogger<FaceVerificationClient> _logger;

    public FaceVerificationClient(
        HttpClient httpClient,
        IOptions<FaceVerificationOptions> options,
        ILogger<FaceVerificationClient> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<FaceVerificationClientResponse> VerifyAsync(
        FaceVerificationClientRequest request,
        CancellationToken cancellationToken = default)
    {
        if (_httpClient.BaseAddress is null)
        {
            _logger.LogWarning(
                "Face verification skipped because service base URL is not configured. User {UserId}, Event {EventId}, FaceProfile {FaceProfileId}",
                request.UserId,
                request.EventId,
                request.FaceProfileId);

            return CreateTechnicalError(
                errorCode: FaceVerificationClientResponse.ErrorServiceUnavailable,
                errorMessage: "Face verification service is not configured.");
        }

        var payload = new FaceVerifyHttpRequestDto
        {
            RequestId = request.RequestId,
            UserId = request.UserId,
            AttendanceContext = new FaceVerifyAttendanceContextDto
            {
                EventId = request.EventId,
                EnableFaceVerification = true
            },
            Reference = new FaceVerifyReferenceDto
            {
                FaceProfileId = request.FaceProfileId,
                Algorithm = request.Algorithm,
                Version = request.Version,
                EmbeddingBase64 = Convert.ToBase64String(request.ReferenceEmbedding)
            },
            Probe = new FaceVerifyProbeDto
            {
                ImageBase64 = request.FaceImageBase64,
                MimeType = request.FaceImageMimeType
            }
        };

        try
        {
            _logger.LogInformation(
                "Calling face verification service. RequestId {RequestId}, User {UserId}, Event {EventId}, FaceProfile {FaceProfileId}",
                request.RequestId,
                request.UserId,
                request.EventId,
                request.FaceProfileId);

            using var response = await _httpClient.PostAsJsonAsync(
                "internal/face/verify",
                payload,
                cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Face verification service returned HTTP {StatusCode}. RequestId {RequestId}, User {UserId}, Event {EventId}",
                    (int)response.StatusCode,
                    request.RequestId,
                    request.UserId,
                    request.EventId);

                return CreateTechnicalError(
                    errorCode: FaceVerificationClientResponse.ErrorServiceUnavailable,
                    errorMessage: $"Face verification service returned HTTP {(int)response.StatusCode}.");
            }

            var content = await response.Content.ReadFromJsonAsync<FaceVerifyHttpResponseDto>(cancellationToken: cancellationToken);
            if (content is null)
            {
                _logger.LogWarning(
                    "Face verification service returned empty body. RequestId {RequestId}, User {UserId}, Event {EventId}",
                    request.RequestId,
                    request.UserId,
                    request.EventId);

                return CreateTechnicalError(
                    errorCode: FaceVerificationClientResponse.ErrorServiceUnavailable,
                    errorMessage: "Face verification service returned empty response.");
            }

            return new FaceVerificationClientResponse
            {
                Provider = content.Provider ?? _options.Service.Provider ?? string.Empty,
                Model = content.Model ?? _options.Service.Model ?? string.Empty,
                Version = content.Version ?? _options.Service.Version ?? string.Empty,
                Status = content.Status ?? FaceVerificationClientResponse.StatusTechnicalError,
                Matched = content.Matched,
                NormalizedConfidence = content.NormalizedConfidence,
                RawScore = content.RawScore,
                QualityScore = content.QualityScore,
                Threshold = content.Threshold,
                ProcessingTimeMs = content.ProcessingTimeMs,
                ErrorCode = content.ErrorCode,
                ErrorMessage = content.ErrorMessage
            };
        }
        catch (TaskCanceledException ex) when (!cancellationToken.IsCancellationRequested)
        {
            _logger.LogWarning(
                ex,
                "Face verification service timed out. RequestId {RequestId}, User {UserId}, Event {EventId}",
                request.RequestId,
                request.UserId,
                request.EventId);

            return CreateTechnicalError(
                errorCode: FaceVerificationClientResponse.ErrorTimeout,
                errorMessage: "Face verification service timed out.");
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning(
                ex,
                "Face verification service is unavailable. RequestId {RequestId}, User {UserId}, Event {EventId}",
                request.RequestId,
                request.UserId,
                request.EventId);

            return CreateTechnicalError(
                errorCode: FaceVerificationClientResponse.ErrorServiceUnavailable,
                errorMessage: "Face verification service is unavailable.");
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Face verification service failed unexpectedly. RequestId {RequestId}, User {UserId}, Event {EventId}",
                request.RequestId,
                request.UserId,
                request.EventId);

            return CreateTechnicalError(
                errorCode: "FACE_TECHNICAL_ERROR",
                errorMessage: "Face verification failed unexpectedly.");
        }
    }

    private FaceVerificationClientResponse CreateTechnicalError(string errorCode, string errorMessage)
    {
        return new FaceVerificationClientResponse
        {
            Provider = _options.Service.Provider ?? string.Empty,
            Model = _options.Service.Model ?? string.Empty,
            Version = _options.Service.Version ?? string.Empty,
            Status = FaceVerificationClientResponse.StatusTechnicalError,
            Matched = false,
            NormalizedConfidence = null,
            RawScore = null,
            QualityScore = null,
            Threshold = _options.Thresholds.Match,
            ProcessingTimeMs = 0,
            ErrorCode = errorCode,
            ErrorMessage = errorMessage
        };
    }

    private sealed class FaceVerifyHttpRequestDto
    {
        public string RequestId { get; set; } = string.Empty;

        public int UserId { get; set; }

        public FaceVerifyAttendanceContextDto AttendanceContext { get; set; } = new();

        public FaceVerifyReferenceDto Reference { get; set; } = new();

        public FaceVerifyProbeDto Probe { get; set; } = new();
    }

    private sealed class FaceVerifyAttendanceContextDto
    {
        public int EventId { get; set; }

        public bool EnableFaceVerification { get; set; }
    }

    private sealed class FaceVerifyReferenceDto
    {
        public int FaceProfileId { get; set; }

        public string Algorithm { get; set; } = string.Empty;

        public string? Version { get; set; }

        public string EmbeddingBase64 { get; set; } = string.Empty;
    }

    private sealed class FaceVerifyProbeDto
    {
        public string ImageBase64 { get; set; } = string.Empty;

        public string MimeType { get; set; } = string.Empty;
    }

    private sealed class FaceVerifyHttpResponseDto
    {
        public string? Provider { get; set; }

        public string? Model { get; set; }

        public string? Version { get; set; }

        public string? Status { get; set; }

        public bool Matched { get; set; }

        public double? NormalizedConfidence { get; set; }

        public double? RawScore { get; set; }

        public double? QualityScore { get; set; }

        public double? Threshold { get; set; }

        public int ProcessingTimeMs { get; set; }

        public string? ErrorCode { get; set; }

        public string? ErrorMessage { get; set; }
    }
}
