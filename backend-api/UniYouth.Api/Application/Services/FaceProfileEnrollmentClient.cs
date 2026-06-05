using System.Net.Http.Json;
using Microsoft.Extensions.Options;
using UniYouth.Api.Shared.FaceVerification;

namespace UniYouth.Api.Application.Services;

public interface IFaceProfileEnrollmentClient
{
    Task<FaceProfileEnrollmentClientResponse> EnrollAsync(
        FaceProfileEnrollmentClientRequest request,
        CancellationToken cancellationToken = default);
}

public sealed class FaceProfileEnrollmentClientRequest
{
    public string RequestId { get; init; } = Guid.NewGuid().ToString("N");

    public int UserId { get; init; }

    public string FaceImageBase64 { get; init; } = string.Empty;

    public string FaceImageMimeType { get; init; } = "image/jpeg";
}

public sealed class FaceProfileEnrollmentClientResponse
{
    public const string StatusReady = "Ready";
    public const string StatusTechnicalError = "TechnicalError";

    public const string ErrorServiceUnavailable = "SERVICE_UNAVAILABLE";
    public const string ErrorTimeout = "TIMEOUT";

    public string Provider { get; init; } = string.Empty;

    public string Model { get; init; } = string.Empty;

    public string Version { get; init; } = string.Empty;

    public string Status { get; init; } = StatusTechnicalError;

    public string? EmbeddingBase64 { get; init; }

    public double? QualityScore { get; init; }

    public int ProcessingTimeMs { get; init; }

    public string? ErrorCode { get; init; }

    public string? ErrorMessage { get; init; }
}

internal sealed class FaceProfileEnrollmentClient : IFaceProfileEnrollmentClient
{
    private readonly HttpClient _httpClient;
    private readonly FaceVerificationOptions _options;
    private readonly ILogger<FaceProfileEnrollmentClient> _logger;

    public FaceProfileEnrollmentClient(
        HttpClient httpClient,
        IOptions<FaceVerificationOptions> options,
        ILogger<FaceProfileEnrollmentClient> logger)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<FaceProfileEnrollmentClientResponse> EnrollAsync(
        FaceProfileEnrollmentClientRequest request,
        CancellationToken cancellationToken = default)
    {
        if (_httpClient.BaseAddress is null)
        {
            _logger.LogWarning(
                "Face enrollment skipped because service base URL is not configured. User {UserId}",
                request.UserId);

            return CreateTechnicalError(
                errorCode: FaceProfileEnrollmentClientResponse.ErrorServiceUnavailable,
                errorMessage: "Face enrollment service is not configured.");
        }

        var payload = new FaceEnrollHttpRequestDto
        {
            RequestId = request.RequestId,
            UserId = request.UserId,
            Probe = new FaceEnrollProbeDto
            {
                ImageBase64 = request.FaceImageBase64,
                MimeType = request.FaceImageMimeType
            }
        };

        try
        {
            _logger.LogInformation(
                "Calling face enrollment service. RequestId {RequestId}, User {UserId}",
                request.RequestId,
                request.UserId);

            using var response = await _httpClient.PostAsJsonAsync(
                "internal/face/enroll",
                payload,
                cancellationToken);

            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Face enrollment service returned HTTP {StatusCode}. RequestId {RequestId}, User {UserId}",
                    (int)response.StatusCode,
                    request.RequestId,
                    request.UserId);

                return CreateTechnicalError(
                    errorCode: FaceProfileEnrollmentClientResponse.ErrorServiceUnavailable,
                    errorMessage: $"Face enrollment service returned HTTP {(int)response.StatusCode}.");
            }

            var content = await response.Content.ReadFromJsonAsync<FaceEnrollHttpResponseDto>(cancellationToken: cancellationToken);
            if (content is null)
            {
                return CreateTechnicalError(
                    errorCode: FaceProfileEnrollmentClientResponse.ErrorServiceUnavailable,
                    errorMessage: "Face enrollment service returned empty response.");
            }

            return new FaceProfileEnrollmentClientResponse
            {
                Provider = content.Provider ?? _options.Service.Provider ?? string.Empty,
                Model = content.Model ?? _options.Service.Model ?? string.Empty,
                Version = content.Version ?? _options.Service.Version ?? string.Empty,
                Status = content.Status ?? FaceProfileEnrollmentClientResponse.StatusTechnicalError,
                EmbeddingBase64 = content.EmbeddingBase64,
                QualityScore = content.QualityScore,
                ProcessingTimeMs = content.ProcessingTimeMs,
                ErrorCode = content.ErrorCode,
                ErrorMessage = content.ErrorMessage
            };
        }
        catch (TaskCanceledException ex) when (!cancellationToken.IsCancellationRequested)
        {
            _logger.LogWarning(
                ex,
                "Face enrollment service timed out. RequestId {RequestId}, User {UserId}",
                request.RequestId,
                request.UserId);

            return CreateTechnicalError(
                errorCode: FaceProfileEnrollmentClientResponse.ErrorTimeout,
                errorMessage: "Face enrollment service timed out.");
        }
        catch (HttpRequestException ex)
        {
            _logger.LogWarning(
                ex,
                "Face enrollment service is unavailable. RequestId {RequestId}, User {UserId}",
                request.RequestId,
                request.UserId);

            return CreateTechnicalError(
                errorCode: FaceProfileEnrollmentClientResponse.ErrorServiceUnavailable,
                errorMessage: "Face enrollment service is unavailable.");
        }
        catch (Exception ex)
        {
            _logger.LogError(
                ex,
                "Face enrollment service failed unexpectedly. RequestId {RequestId}, User {UserId}",
                request.RequestId,
                request.UserId);

            return CreateTechnicalError(
                errorCode: "FACE_ENROLL_TECHNICAL_ERROR",
                errorMessage: "Face enrollment failed unexpectedly.");
        }
    }

    private FaceProfileEnrollmentClientResponse CreateTechnicalError(string errorCode, string errorMessage)
    {
        return new FaceProfileEnrollmentClientResponse
        {
            Provider = _options.Service.Provider ?? string.Empty,
            Model = _options.Service.Model ?? string.Empty,
            Version = _options.Service.Version ?? string.Empty,
            Status = FaceProfileEnrollmentClientResponse.StatusTechnicalError,
            EmbeddingBase64 = null,
            QualityScore = null,
            ProcessingTimeMs = 0,
            ErrorCode = errorCode,
            ErrorMessage = errorMessage
        };
    }

    private sealed class FaceEnrollHttpRequestDto
    {
        public string RequestId { get; set; } = string.Empty;

        public int UserId { get; set; }

        public FaceEnrollProbeDto Probe { get; set; } = new();
    }

    private sealed class FaceEnrollProbeDto
    {
        public string ImageBase64 { get; set; } = string.Empty;

        public string MimeType { get; set; } = string.Empty;
    }

    private sealed class FaceEnrollHttpResponseDto
    {
        public string? Provider { get; set; }

        public string? Model { get; set; }

        public string? Version { get; set; }

        public string? Status { get; set; }

        public string? EmbeddingBase64 { get; set; }

        public double? QualityScore { get; set; }

        public int ProcessingTimeMs { get; set; }

        public string? ErrorCode { get; set; }

        public string? ErrorMessage { get; set; }
    }
}
