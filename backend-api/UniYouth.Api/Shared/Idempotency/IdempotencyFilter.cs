using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;
using Microsoft.Extensions.Caching.Memory;
using Microsoft.Extensions.Primitives;
using UniYouth.Api.Shared.Extensions;

namespace UniYouth.Api.Shared.Idempotency
{
    internal sealed class IdempotencyFilter : IAsyncActionFilter
    {
        private readonly IMemoryCache _cache;
        private readonly IdempotencyLockProvider _lockProvider;
        private readonly IdempotencyOptions _options;
        private readonly ILogger<IdempotencyFilter> _logger;
        private readonly int? _ttlSecondsOverride;

        public IdempotencyFilter(
            IMemoryCache cache,
            IdempotencyLockProvider lockProvider,
            IdempotencyOptions options,
            ILogger<IdempotencyFilter> logger,
            int? ttlSecondsOverride = null)
        {
            _cache = cache;
            _lockProvider = lockProvider;
            _options = options;
            _logger = logger;
            _ttlSecondsOverride = ttlSecondsOverride;
        }

        public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
        {
            var http = context.HttpContext;

            if (!http.Request.Headers.TryGetValue(_options.HeaderName, out StringValues keyValues))
            {
                await next();
                return;
            }

            var rawKey = keyValues.ToString().Trim();
            if (string.IsNullOrWhiteSpace(rawKey))
            {
                await next();
                return;
            }

            int userId;
            try
            {
                userId = http.User.GetUserId();
            }
            catch
            {
                await next();
                return;
            }

            var cacheKey = $"idem:{userId}:{http.Request.Method}:{http.Request.Path}:{rawKey}";
            var ttl = TimeSpan.FromSeconds(_ttlSecondsOverride ?? _options.DefaultTtlSeconds);

            using var _ = await _lockProvider.AcquireAsync(cacheKey, http.RequestAborted);

            if (_cache.TryGetValue(cacheKey, out var cachedObj) && cachedObj is IdempotencyRecord cached)
            {
                http.Response.Headers["Idempotency-Replayed"] = "true";

                context.Result = new ObjectResult(cached.Body)
                {
                    StatusCode = cached.StatusCode
                };
                return;
            }

            var executed = await next();

            if (executed.Exception is not null && !executed.ExceptionHandled)
            {
                return;
            }

            var record = executed.Result switch
            {
                ObjectResult obj => new IdempotencyRecord(obj.StatusCode ?? StatusCodes.Status200OK, obj.Value),
                JsonResult json => new IdempotencyRecord(StatusCodes.Status200OK, json.Value),
                StatusCodeResult sc => new IdempotencyRecord(sc.StatusCode, null),
                _ => null
            };

            if (record is null)
            {
                return;
            }

            http.Response.Headers["Idempotency-Replayed"] = "false";
            _cache.Set(cacheKey, record, ttl);

            _logger.LogDebug(
                "Stored idempotency response. UserId={UserId}, Path={Path}, TtlSeconds={TtlSeconds}",
                userId,
                http.Request.Path,
                (int)ttl.TotalSeconds);
        }
    }
}
