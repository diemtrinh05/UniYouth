using System.Diagnostics;
using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Common;

namespace UniYouth.Api.Shared.Exceptions
{
    public sealed class GlobalExceptionHandler : IExceptionHandler
    {
        private readonly ILogger<GlobalExceptionHandler> _logger;
        private readonly IHostEnvironment _environment;

        public GlobalExceptionHandler(
            ILogger<GlobalExceptionHandler> logger,
            IHostEnvironment environment)
        {
            _logger = logger;
            _environment = environment;
        }

        public async ValueTask<bool> TryHandleAsync(
            HttpContext httpContext,
            Exception exception,
            CancellationToken cancellationToken)
        {
            var acceptHeader = httpContext.Request.Headers.Accept.ToString();
            var wantsProblemDetails =
                acceptHeader.Contains("application/problem+json", StringComparison.OrdinalIgnoreCase);

            var (statusCode, title) = exception switch
            {
                ConflictException => (StatusCodes.Status409Conflict, "Conflict"),
                KeyNotFoundException => (StatusCodes.Status404NotFound, "Not Found"),
                UnauthorizedAccessException => (StatusCodes.Status403Forbidden, "Forbidden"),
                ArgumentException => (StatusCodes.Status400BadRequest, "Bad Request"),
                InvalidOperationException => (StatusCodes.Status400BadRequest, "Bad Request"),
                DbUpdateException => (StatusCodes.Status409Conflict, "Conflict"),
                _ => (StatusCodes.Status500InternalServerError, "Internal Server Error")
            };

            if (statusCode >= 500)
            {
                _logger.LogError(exception, "Unhandled exception. TraceId={TraceId}", httpContext.TraceIdentifier);
            }
            else
            {
                _logger.LogWarning(exception, "Handled exception ({StatusCode}). TraceId={TraceId}", statusCode, httpContext.TraceIdentifier);
            }

            var traceId = Activity.Current?.Id ?? httpContext.TraceIdentifier;

            if (!wantsProblemDetails)
            {
                var message = _environment.IsDevelopment()
                    ? exception.Message
                    : statusCode >= 500
                        ? "Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau."
                        : exception.Message;

                httpContext.Response.StatusCode = statusCode;
                httpContext.Response.ContentType = "application/json";
                httpContext.Response.Headers["X-Trace-Id"] = traceId;

                await httpContext.Response.WriteAsJsonAsync(
                    new ApiResponseDto<object>
                    {
                        Success = false,
                        Message = message,
                        Data = _environment.IsDevelopment()
                            ? new { traceId, detail = exception.ToString() }
                            : new { traceId }
                    },
                    cancellationToken);

                return true;
            }

            var problemDetails = new ProblemDetails
            {
                Status = statusCode,
                Title = title,
                Instance = httpContext.Request.Path
            };

            if (_environment.IsDevelopment())
            {
                problemDetails.Detail = exception.ToString();
            }
            else
            {
                problemDetails.Detail = statusCode >= 500
                    ? "Đã xảy ra lỗi hệ thống. Vui lòng thử lại sau."
                    : exception.Message;
            }

            problemDetails.Extensions["traceId"] = traceId;

            httpContext.Response.StatusCode = statusCode;
            httpContext.Response.ContentType = "application/problem+json";
            await httpContext.Response.WriteAsJsonAsync(problemDetails, cancellationToken);

            return true;
        }
    }
}

