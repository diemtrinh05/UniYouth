using System.Net;
using System.Text.Json;

namespace UniYouth.Admin.Services.Common
{
    public static class ApiErrorReader
    {
        public sealed class ApiErrorInfo
        {
            public string Message { get; set; } = string.Empty;
            public string DisplayMessage { get; set; } = string.Empty;
            public Dictionary<string, string[]?>? Errors { get; set; }
        }

        private static readonly JsonSerializerOptions DefaultJsonOptions = new()
        {
            PropertyNameCaseInsensitive = true
        };

        public static async Task<ApiErrorInfo> ReadErrorAsync(
            HttpResponseMessage response,
            string defaultMessage)
        {
            if (string.Equals(
                    response.Content?.Headers?.ContentType?.MediaType,
                    "application/problem+json",
                    StringComparison.OrdinalIgnoreCase))
            {
                var problemDetails = await TryReadProblemDetailsAsync(response);
                if (problemDetails != null)
                {
                    return problemDetails;
                }
            }

            var apiEnvelope = await TryReadApiEnvelopeAsync(response);
            if (apiEnvelope != null)
            {
                return apiEnvelope;
            }

            var fallbackProblem = await TryReadProblemDetailsAsync(response);
            if (fallbackProblem != null)
            {
                return fallbackProblem;
            }

            if (response.StatusCode == HttpStatusCode.TooManyRequests)
            {
                var tooManyRequestsMessage = BuildTooManyRequestsMessage(response);
                return new ApiErrorInfo
                {
                    Message = tooManyRequestsMessage,
                    DisplayMessage = tooManyRequestsMessage
                };
            }

            return new ApiErrorInfo
            {
                Message = defaultMessage,
                DisplayMessage = defaultMessage
            };
        }

        public static async Task<string> ReadErrorMessageAsync(
            HttpResponseMessage response,
            string defaultMessage)
        {
            var errorInfo = await ReadErrorAsync(response, defaultMessage);
            return errorInfo.DisplayMessage;
        }

        public static string BuildErrorMessage(
            string message,
            Dictionary<string, string[]?>? errors)
        {
            if (errors == null || errors.Count == 0)
            {
                return message;
            }

            var allErrors = new List<string>();
            foreach (var kvp in errors)
            {
                if (kvp.Value == null)
                {
                    continue;
                }

                foreach (var err in kvp.Value)
                {
                    if (!string.IsNullOrWhiteSpace(err))
                    {
                        allErrors.Add(err.Trim());
                    }
                }
            }

            if (allErrors.Count == 0)
            {
                return message;
            }

            return $"{message} ({string.Join(" | ", allErrors.Distinct())})";
        }

        private static string BuildTooManyRequestsMessage(HttpResponseMessage response)
        {
            // Retry-After can be delta-seconds or HTTP date.
            var retryAfter = response.Headers.RetryAfter;
            if (retryAfter?.Delta != null)
            {
                var seconds = (int)Math.Ceiling(retryAfter.Delta.Value.TotalSeconds);
                return $"Bạn đang gửi quá nhiều yêu cầu. Vui lòng thử lại sau {seconds} giây.";
            }

            if (retryAfter?.Date != null)
            {
                var seconds = (int)Math.Ceiling((retryAfter.Date.Value - DateTimeOffset.UtcNow).TotalSeconds);
                if (seconds > 0)
                {
                    return $"Bạn đang gửi quá nhiều yêu cầu. Vui lòng thử lại sau {seconds} giây.";
                }
            }

            return "Bạn đang gửi quá nhiều yêu cầu. Vui lòng thử lại sau.";
        }

        private static async Task<ApiErrorInfo?> TryReadApiEnvelopeAsync(HttpResponseMessage response)
        {
            if (response.Content == null)
            {
                return null;
            }

            var json = await response.Content.ReadAsStringAsync();
            if (string.IsNullOrWhiteSpace(json))
            {
                return null;
            }

            try
            {
                var envelope = JsonSerializer.Deserialize<ApiResponseDto>(json, DefaultJsonOptions);
                if (envelope == null)
                {
                    return null;
                }

                var baseMessage = envelope.Message;
                if (string.IsNullOrWhiteSpace(baseMessage))
                {
                    // If no message but errors exist, still show a generic header.
                    baseMessage = envelope.Errors != null && envelope.Errors.Count > 0
                        ? "Dữ liệu không hợp lệ."
                        : null;
                }

                if (string.IsNullOrWhiteSpace(baseMessage))
                {
                    return null;
                }

                return new ApiErrorInfo
                {
                    Message = baseMessage!,
                    DisplayMessage = BuildErrorMessage(baseMessage!, envelope.Errors),
                    Errors = envelope.Errors
                };
            }
            catch (JsonException)
            {
                return null;
            }
        }

        private static async Task<ApiErrorInfo?> TryReadProblemDetailsAsync(HttpResponseMessage response)
        {
            if (response.Content == null)
            {
                return null;
            }

            var json = await response.Content.ReadAsStringAsync();
            if (string.IsNullOrWhiteSpace(json))
            {
                return null;
            }

            try
            {
                using var doc = JsonDocument.Parse(json);
                var root = doc.RootElement;
                if (root.ValueKind != JsonValueKind.Object)
                {
                    return null;
                }

                string? title = null;
                string? detail = null;
                Dictionary<string, string[]?>? errors = null;

                if (root.TryGetProperty("title", out var titleEl) && titleEl.ValueKind == JsonValueKind.String)
                {
                    title = titleEl.GetString();
                }

                if (root.TryGetProperty("detail", out var detailEl) && detailEl.ValueKind == JsonValueKind.String)
                {
                    detail = detailEl.GetString();
                }

                if (root.TryGetProperty("errors", out var errorsEl) && errorsEl.ValueKind == JsonValueKind.Object)
                {
                    errors = new Dictionary<string, string[]?>(StringComparer.OrdinalIgnoreCase);
                    foreach (var prop in errorsEl.EnumerateObject())
                    {
                        if (prop.Value.ValueKind != JsonValueKind.Array)
                        {
                            continue;
                        }

                        var list = new List<string>();
                        foreach (var item in prop.Value.EnumerateArray())
                        {
                            if (item.ValueKind == JsonValueKind.String)
                            {
                                var s = item.GetString();
                                if (!string.IsNullOrWhiteSpace(s))
                                {
                                    list.Add(s.Trim());
                                }
                            }
                        }

                        errors[prop.Name] = list.Count == 0 ? null : list.ToArray();
                    }
                }

                var message = !string.IsNullOrWhiteSpace(detail)
                    ? detail
                    : title;

                if (string.IsNullOrWhiteSpace(message))
                {
                    return null;
                }

                return new ApiErrorInfo
                {
                    Message = message!,
                    DisplayMessage = BuildErrorMessage(message!, errors),
                    Errors = errors
                };
            }
            catch (JsonException)
            {
                return null;
            }
        }
    }
}
