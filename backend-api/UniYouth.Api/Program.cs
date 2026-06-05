using System.Text;
using System.Diagnostics;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.FileProviders;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using UniYouth.Api.Application.Hubs;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Application.Jobs;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Exceptions;
using UniYouth.Api.Shared.FaceVerification;
using UniYouth.Api.Shared.Idempotency;
using UniYouth.Api.Shared.PushNotifications;
using UniYouth.Api.Shared.Helpers;

var builder = WebApplication.CreateBuilder(args);

// Ensure Vietnamese text logs correctly in Windows console/CI logs.
Console.InputEncoding = Encoding.UTF8;
Console.OutputEncoding = Encoding.UTF8;

// ============================================================================
// 1. CẤU HÌNH CÁC DỊCH VỤ (SERVICES)
// ============================================================================

// Đăng ký DbContext sử dụng SQL Server
var uniYouthConnectionString = builder.Configuration.GetConnectionString("UniYouth");
if (string.IsNullOrWhiteSpace(uniYouthConnectionString))
{
    throw new InvalidOperationException(
        "ConnectionStrings:UniYouth is not configured. Set it via user-secrets or the ConnectionStrings__UniYouth environment variable.");
}

builder.Services.AddDbContext<UniYouthDbContext>(options =>
    options.UseSqlServer(
        uniYouthConnectionString,
        sqlOptions => sqlOptions.EnableRetryOnFailure()
    ));

// ============================================================================
// 2. CẤU HÌNH XÁC THỰC JWT (JWT AUTHENTICATION)
// ============================================================================
var jwtSettings = builder.Configuration.GetSection("Jwt");
var secretKey = jwtSettings["Key"] ?? throw new InvalidOperationException("JWT Key is not configured");

builder.Services.AddAuthentication(options =>
{
    options.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    options.DefaultScheme = JwtBearerDefaults.AuthenticationScheme;
})
.AddJwtBearer(options =>
{
    options.SaveToken = true;
    // Chỉ nên để false trong môi trường phát triển (development)
    options.RequireHttpsMetadata = false; // Set to true in production
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuer = true,              // Kiểm tra Issuer
        ValidateAudience = true,            // Kiểm tra Audience
        ValidateLifetime = true,           // Kiểm tra thời hạn token
        ValidateIssuerSigningKey = true,   // Kiểm tra thời hạn token
        ValidIssuer = jwtSettings["Issuer"],
        ValidAudience = jwtSettings["Audience"],
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
        ClockSkew = TimeSpan.Zero  // Loại bỏ thời gian cho phép sai lệch mặc định 5 phút
    };

    // Các sự kiện xử lý trong quá trình xác thực JWT (tùy chọn)
    options.Events = new JwtBearerEvents
    {
        OnMessageReceived = context =>
        {
            var accessToken = context.Request.Query["access_token"];
            var requestPath = context.HttpContext.Request.Path;

            if (!string.IsNullOrWhiteSpace(accessToken)
                && (requestPath.StartsWithSegments("/hubs/notifications")
                    || requestPath.StartsWithSegments("/hubs/support-chat")))
            {
                context.Token = accessToken;
            }

            return Task.CompletedTask;
        },
        OnAuthenticationFailed = context =>
        {
            var logger = context.HttpContext.RequestServices
                .GetRequiredService<ILogger<Program>>();
            logger.LogWarning("Authentication failed: {Message}", context.Exception.Message);
            return Task.CompletedTask;
        },
        OnTokenValidated = context =>
        {
            var logger = context.HttpContext.RequestServices
                .GetRequiredService<ILogger<Program>>();
            var userId = context.Principal?.FindFirst("userId")?.Value;
            logger.LogInformation("Token validated for user: {UserId}", userId);
            return Task.CompletedTask;
        }
    };
});

// Đăng ký Authorization (phân quyền)
builder.Services.AddAuthorization();
// ============================================================================
// 2.1 RATE LIMITING (chỉ áp dụng cho endpoint nhạy cảm)
// - /api/auth/login
// - /api/attendance/checkin
// - QR endpoints
// ============================================================================
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;

    options.OnRejected = async (context, cancellationToken) =>
    {
        context.HttpContext.Response.ContentType = "application/json";
        await context.HttpContext.Response.WriteAsJsonAsync(new
        {
            message = "Quá nhiều yêu cầu. Vui lòng thử lại sau.",
            statusCode = StatusCodes.Status429TooManyRequests
        }, cancellationToken);
    };

    // Login: giới hạn theo IP để chống brute-force
    options.AddPolicy("Login", httpContext =>
    {
        var ip = ClientIpHelper.GetClientIpAddress(httpContext) ?? "unknown";

        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: ip,
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 5,
                Window = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 0,
                AutoReplenishment = true
            });
    });

    // Forgot password: giới hạn theo IP để chống spam email / enumeration
    options.AddPolicy("ForgotPassword", httpContext =>
    {
        var ip = ClientIpHelper.GetClientIpAddress(httpContext) ?? "unknown";

        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: ip,
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 5,
                Window = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 0,
                AutoReplenishment = true
            });
    });

    // Attendance check-in: ưu tiên theo userId (đã auth), fallback theo IP
    options.AddPolicy("AttendanceCheckIn", httpContext =>
    {
        var userKey = httpContext.User.FindFirst("userId")?.Value;
        var ip = ClientIpHelper.GetClientIpAddress(httpContext);
        var key = userKey ?? ip ?? "unknown";

        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: key,
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 10,
                Window = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 0,
                AutoReplenishment = true
            });
    });

    // QR endpoints: ưu tiên theo userId (CanBo/Admin), fallback theo IP
    options.AddPolicy("Qr", httpContext =>
    {
        var userKey = httpContext.User.FindFirst("userId")?.Value;
        var ip = ClientIpHelper.GetClientIpAddress(httpContext);
        var key = userKey ?? ip ?? "unknown";

        return RateLimitPartition.GetFixedWindowLimiter(
            partitionKey: key,
            factory: _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 30,
                Window = TimeSpan.FromMinutes(1),
                QueueProcessingOrder = QueueProcessingOrder.OldestFirst,
                QueueLimit = 0,
                AutoReplenishment = true
            });
    });
});

// ============================================================================
// 3. ĐĂNG KÝ CÁC SERVICE CỦA ỨNG DỤNG
// ============================================================================
builder.Services.AddScoped<IAuthService, AuthService>();
builder.Services.AddScoped<IPasswordResetService, PasswordResetService>();
builder.Services.AddScoped<IPasswordResetOtpService, PasswordResetOtpService>();
builder.Services.AddScoped<IEmailService>(sp =>
{
    var config = sp.GetRequiredService<IConfiguration>();
    var useGmailApi = config.GetValue("Email:Gmail:Enabled", false);

    return useGmailApi
        ? ActivatorUtilities.CreateInstance<GmailApiEmailService>(sp)
        : ActivatorUtilities.CreateInstance<SmtpEmailService>(sp);
});
builder.Services.AddScoped<IUserManagementService, UserManagementService>();
builder.Services.AddScoped<IUserService, UserService>();
builder.Services.AddScoped<IUnitLookupService, UnitLookupService>();
builder.Services.AddScoped<IPositionLookupService, PositionLookupService>();
builder.Services.AddScoped<IFaceProfileEnrollmentService, FaceProfileEnrollmentService>();
builder.Services.AddScoped<IEventService, EventService>();
builder.Services.AddScoped<IEventTypeService, EventTypeService>();
builder.Services.AddScoped<IEventImageService, EventImageService>();
builder.Services.AddScoped<IPublicUrlBuilder, PublicUrlBuilder>();
builder.Services.AddScoped<IEventRegistrationService, EventRegistrationService>();
builder.Services.AddScoped<IEventQRCodeService, EventQRCodeService>();
builder.Services.AddScoped<IFaceProfileSelectionService, FaceProfileSelectionService>();
builder.Services.AddScoped<IAttendanceService, AttendanceService>();
builder.Services.AddScoped<IAttendanceRiskScoringService, AttendanceRiskScoringService>();
builder.Services.AddScoped<IActivityPointService, ActivityPointService>();
builder.Services.AddScoped<IAttendancePointsSyncService, AttendancePointsSyncService>();
builder.Services.AddScoped<IReportingService, ReportingService>();
builder.Services.AddScoped<IEventPointService, EventPointService>();
builder.Services.AddScoped<INotificationService, NotificationService>();
builder.Services.AddScoped<INotificationPreferenceService, NotificationPreferenceService>();
builder.Services.AddScoped<INotificationRealtimeDispatcher, NotificationRealtimeDispatcher>();
builder.Services.AddScoped<ISupportChatService, SupportChatService>();
builder.Services.AddScoped<ISupportChatRealtimeDispatcher, SupportChatRealtimeDispatcher>();
builder.Services.AddScoped<IDeviceTokenService, DeviceTokenService>();
builder.Services.AddScoped<IPushNotificationService, PushNotificationService>();
builder.Services.AddScoped<ILocationPresetService, LocationPresetService>();
builder.Services.AddHttpContextAccessor();
builder.Services.AddSingleton<IAttendancePointsSyncQueue, AttendancePointsSyncQueue>();
builder.Services.AddHostedService<EventBackgroundService>();
builder.Services.AddHostedService<AttendancePointsSyncBackgroundService>();
builder.Services.AddHostedService<NotificationDispatchBackgroundService>();
builder.Services.AddHostedService<PushNotificationConfigDiagnosticsService>();

// Idempotency (chống double tap cho một số endpoint)
builder.Services.AddMemoryCache();
builder.Services.AddSingleton<IdempotencyOptions>();
builder.Services.AddSingleton<IdempotencyLockProvider>();

// Push Notifications (FCM/APNS) - cấu hình theo appsettings/env (mặc định disabled)
builder.Services.Configure<PushNotificationOptions>(
    builder.Configuration.GetSection(PushNotificationOptions.SectionName));
builder.Services.Configure<FaceVerificationOptions>(
    builder.Configuration.GetSection(FaceVerificationOptions.SectionName));
builder.Services.AddHttpClient("push.fcm");
builder.Services.AddHttpClient("push.apns");
builder.Services.AddHttpClient<IFaceVerificationClient, FaceVerificationClient>((sp, client) =>
{
    var options = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<FaceVerificationOptions>>().Value;
    var baseUrl = options.Service.BaseUrl;

    if (Uri.TryCreate(baseUrl, UriKind.Absolute, out var uri))
    {
        client.BaseAddress = uri;
    }

    client.Timeout = TimeSpan.FromSeconds(Math.Max(1, options.Service.TimeoutSeconds));
});
builder.Services.AddHttpClient<IFaceProfileEnrollmentClient, FaceProfileEnrollmentClient>((sp, client) =>
{
    var options = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<FaceVerificationOptions>>().Value;
    var baseUrl = options.Service.BaseUrl;

    if (Uri.TryCreate(baseUrl, UriKind.Absolute, out var uri))
    {
        client.BaseAddress = uri;
    }

    client.Timeout = TimeSpan.FromSeconds(Math.Max(10, options.Service.TimeoutSeconds));
});
builder.Services.AddHttpClient<ILivenessVerificationClient, LivenessVerificationClient>((sp, client) =>
{
    var options = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<FaceVerificationOptions>>().Value;
    var baseUrl = options.Service.BaseUrl;

    if (Uri.TryCreate(baseUrl, UriKind.Absolute, out var uri))
    {
        client.BaseAddress = uri;
    }

    client.Timeout = TimeSpan.FromSeconds(Math.Max(1, options.Service.TimeoutSeconds));
});
builder.Services.AddSignalR();

// ============================================================================
// 4. CẤU HÌNH CONTROLLER & HÀNH VI API
// ============================================================================

// Global exception handling + ProblemDetails (RFC 7807)
builder.Services.AddProblemDetails(options =>
{
    options.CustomizeProblemDetails = context =>
    {
        context.ProblemDetails.Extensions["traceId"] =
            Activity.Current?.Id ?? context.HttpContext.TraceIdentifier;
    };
});
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

builder.Services.AddControllers()
    .ConfigureApiBehaviorOptions(options =>
    {
        // Sử dụng cơ chế validate ModelState mặc định của ASP.NET Core
        options.SuppressModelStateInvalidFilter = false;
    });

// ============================================================================
// 5. CẤU HÌNH SWAGGER (OPENAPI) HỖ TRỢ JWT 
// ============================================================================
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "UniYouth API",
        Version = "v1",
        Description = "University Youth Union Management System API with JWT Authentication",
        Contact = new OpenApiContact
        {
            Name = "UniYouth Team",
            Email = "support@uniyouth.edu.vn"
        }
    });

    // Cấu hình xác thực JWT cho Swagger
    options.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "Bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Description = "Enter 'Bearer' followed by a space and your JWT token.\n\n" +
                      "Example: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
    });

    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });

    // Nạp file XML comment (nếu có) để hiển thị mô tả API trên Swagger
    var xmlFile = $"{System.Reflection.Assembly.GetExecutingAssembly().GetName().Name}.xml";
    var xmlPath = Path.Combine(AppContext.BaseDirectory, xmlFile);
    if (File.Exists(xmlPath))
    {
        options.IncludeXmlComments(xmlPath);
    }
});

// ============================================================================
// 6. CẤU HÌNH CORS (TÙY CHỌN - CÓ THỂ ĐIỀU CHỈNH THEO THỰC TẾ)
// ============================================================================
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        var configuredOrigins = builder.Configuration
            .GetSection("Cors:AllowedOrigins")
            .Get<string[]>() ?? Array.Empty<string>();

        var developmentOrigins = builder.Environment.IsDevelopment()
            ? new[]
            {
                "http://localhost:5036",
                "https://localhost:5036",
                "http://127.0.0.1:5036",
                "https://127.0.0.1:5036"
            }
            : Array.Empty<string>();

        var allowedOrigins = configuredOrigins
            .Concat(developmentOrigins)
            .Where(origin => !string.IsNullOrWhiteSpace(origin))
            .Select(origin => origin.Trim().TrimEnd('/'))
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .ToArray();

        policy.SetIsOriginAllowed(origin => IsCorsOriginAllowed(origin, allowedOrigins, builder.Environment.IsDevelopment()))
              .AllowAnyMethod()
              .AllowAnyHeader()
              .AllowCredentials()
              // Cho phép frontend đọc một số header do backend tự set (không ảnh hưởng preflight)
              .WithExposedHeaders("Idempotency-Replayed", "X-Trace-Id")
              // Giảm số lần preflight khi chạy web (Chrome/Flutter web)
              .SetPreflightMaxAge(TimeSpan.FromHours(1));
    });
});

// ============================================================================
// 7. BUILD ỨNG DỤNG
// ============================================================================
var app = builder.Build();

// ============================================================================
// 8. CẤU HÌNH MIDDLEWARE PIPELINE
// ============================================================================

// Bật Swagger trong môi trường Development
if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI(options =>
    {
        options.SwaggerEndpoint("/swagger/v1/swagger.json", "UniYouth API v1");
        options.RoutePrefix = string.Empty; // Set Swagger UI at app root (như trước đây)
    });

    // Cho phép mở /index.html và redirect về root (Swagger UI).
    app.MapGet("/index.html", () => Results.Redirect("/"))
        .ExcludeFromDescription();
}

// Global exception handler (ProblemDetails)
app.UseExceptionHandler();

// Chuyển hướng HTTP sang HTTPS
// NOTE: Preflight (OPTIONS) trên Chrome có thể fail nếu bị redirect HTTP->HTTPS.
// Để dev (đặc biệt Flutter Web) chạy ổn định, chỉ bật redirect ở non-Development.
if (!app.Environment.IsDevelopment())
{
    app.UseHttpsRedirection();
}

// Bật phục vụ tệp tĩnh + cache avatar
app.UseStaticFiles(new StaticFileOptions
{
    OnPrepareResponse = ctx =>
    {
        // Chỉ cache avatar
        if (ctx.File.Name.StartsWith("avatar_", StringComparison.OrdinalIgnoreCase))
        {
            ctx.Context.Response.Headers.Append(
                "Cache-Control",
                "public,max-age=86400" // 1 ngày
            );
        }
    }
});
// Static files cho thư mục uploads
app.UseStaticFiles(new StaticFileOptions
{
    FileProvider = new PhysicalFileProvider(
        Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads")
    ),
    RequestPath = "/uploads"
});
// Bật CORS
app.UseCors("AllowAll");

// IMPORTANT: Authentication phải đứng trước Authorization
app.UseAuthentication();
app.UseRateLimiter();
app.UseAuthorization();

// Ánh xạ các Controller
app.MapControllers();
app.MapHub<NotificationHub>("/hubs/notifications");
app.MapHub<SupportChatHub>("/hubs/support-chat");

// ============================================================================
// 9. RUN APPLICATION
// ============================================================================
app.Run();

static bool IsCorsOriginAllowed(string? origin, string[] allowedOrigins, bool isDevelopment)
{
    if (string.IsNullOrWhiteSpace(origin))
    {
        return false;
    }

    var normalizedOrigin = origin.Trim().TrimEnd('/');
    if (allowedOrigins.Contains(normalizedOrigin, StringComparer.OrdinalIgnoreCase))
    {
        return true;
    }

    if (!isDevelopment || !Uri.TryCreate(normalizedOrigin, UriKind.Absolute, out var uri))
    {
        return false;
    }

    return uri.Host.Equals("localhost", StringComparison.OrdinalIgnoreCase)
        || uri.Host.Equals("127.0.0.1", StringComparison.OrdinalIgnoreCase)
        || uri.Host.Equals("::1", StringComparison.OrdinalIgnoreCase);
}
