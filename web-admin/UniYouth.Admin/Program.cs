using System.Net.Http.Headers;
using Microsoft.AspNetCore.Authentication.Cookies;
using UniYouth.Admin.Filters;
using UniYouth.Admin.Helpers;
using UniYouth.Admin.Services.Attendance;
using UniYouth.Admin.Services.Auth;
using UniYouth.Admin.Services.AdminUsers;
using UniYouth.Admin.Services.EventImages;
using UniYouth.Admin.Services.EventPoints;
using UniYouth.Admin.Services.Events;
using UniYouth.Admin.Services.EventTypes;
using UniYouth.Admin.Services.Points;
using UniYouth.Admin.Services.QrCodes;
using UniYouth.Admin.Services.Registration;
using UniYouth.Admin.Services.Reports;
using UniYouth.Admin.Services.Stats;
using UniYouth.Admin.Services.Users;
using UniYouth.Admin.Services.LocationPresets;
using UniYouth.Admin.Services.Notifications;
using UniYouth.Admin.Services.Positions;
using UniYouth.Admin.Services.SupportChat;
using UniYouth.Admin.Services.Units;


var builder = WebApplication.CreateBuilder(args);

// ============================================
// THÊM SERVICES VÀO CONTAINER
// ============================================

// Thêm MVC Controllers với Views
builder.Services.AddControllersWithViews(options =>
{
    // ============================================
    // ĐĂNG KÝ GLOBAL AUTHORIZATION FILTER
    // ============================================
    // AdminAuthorizeFilter sẽ được áp dụng cho TẤT CẢ controllers và actions
    // Không cần thêm [Authorize] attribute vào từng controller
    // 
    // Filter này sẽ:
    // 1. Kiểm tra JWT token từ HttpOnly Cookie
    // 2. Validate token
    // 3. Kiểm tra role (chỉ cho phép Admin và CanBo)
    // 4. Lưu user info vào HttpContext
    options.Filters.Add<AdminAuthorizeFilter>();
});

// ============================================
// ĐĂNG KÝ SERVICES CHO DEPENDENCY INJECTION
// ============================================

// HttpContextAccessor - Để ApiClientService có thể đọc cookie
builder.Services.AddHttpContextAccessor();
// ================= AUTH =================
builder.Services.AddHttpClient<IAuthService, AuthService>();

// ================= ADMIN USERS API (Admin only) =================
builder.Services.AddHttpClient<IAdminUsersApiService, AdminUsersApiService>();

// ================= EVENTS API =================
builder.Services.AddHttpClient<IEventApiService, EventApiService>();

// ================= EVENT TYPES API (Admin only) =================
builder.Services.AddHttpClient<IEventTypesApiService, EventTypesApiService>();

// ================= LOCATION PRESETS API (Admin only UI) =================
builder.Services.AddHttpClient<ILocationPresetsApiService, LocationPresetsApiService>();

// ================= USER PROFILE API =================
builder.Services.AddHttpClient<IUserProfileApiService, UserProfileApiService>();
builder.Services.AddHttpClient<IUnitsApiService, UnitsApiService>();
builder.Services.AddHttpClient<IPositionsApiService, PositionsApiService>();

// ================= STATS API =================
builder.Services.AddHttpClient<IStatsApiService, StatsApiService>();

// ================= POINTS API =================
builder.Services.AddHttpClient<IPointsApiService, PointsApiService>();

// ================= NOTIFICATIONS API =================
builder.Services.AddHttpClient<INotificationApiService, NotificationApiService>();

// ================= SUPPORT CHAT API =================
builder.Services.AddHttpClient<ISupportChatApiService, SupportChatApiService>();

// Event Images
builder.Services.AddHttpClient<IEventImagesApiService, EventImagesApiService>();

// Đăng ký QrCodesService
builder.Services.AddHttpClient<IQrCodesApiService, QrCodesApiService>();

// Đăng ký AttendanceService
builder.Services.AddHttpClient<IAttendanceApiService, AttendanceApiService>();

// Đăng ký RegistrationsService
builder.Services.AddHttpClient<IRegistrationApiService, RegistrationApiService>();

// Đăng ký EventPointsApiService
builder.Services.AddHttpClient<IEventPointsApiService, EventPointsApiService>();

// Đăng ký ReportsApiService
builder.Services.AddHttpClient<IReportsApiService, ReportsApiService>();

// JwtHelper - Validate và extract claims từ JWT token
builder.Services.AddScoped<JwtHelper>();
// Đăng ký AdminAuthorizeFilter để sử dụng trong controllers
builder.Services.AddScoped<AdminAuthorizeFilter>();
// ============================================
// CẤU HÌNH SESSION (Tùy chọn)
// ============================================
// Session có thể dùng để cache một số data tạm thời
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

// ============================================
// CẤU HÌNH LOGGING
// ============================================
builder.Logging.AddConsole();
builder.Logging.AddDebug();

// AUTH MODEL (QUAN TRỌNG):
// - Web Admin lưu JWT trong HttpOnly cookie `UniYouthAuth`.
// - `AdminAuthorizeFilter` (global MVC filter) sẽ đọc cookie, validate JWT và set identity cho request.
// - Không dùng `CookieAuthentication` (ticket-based) của ASP.NET Core để tránh nhầm lẫn cơ chế `HttpContext.User`.

var app = builder.Build();

// ============================================
// CẤU HÌNH HTTP REQUEST PIPELINE
// ============================================

// Xử lý exception trong Production
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    // The default HSTS value is 30 days. You may want to change this for production scenarios, see https://aka.ms/aspnetcore-hsts.
    app.UseHsts();
}

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();
// Không dùng authentication/authorization middleware vì đã gate quyền bằng `AdminAuthorizeFilter` (MVC filter).

app.UseSession();

// ============================================
// MAP ROUTES
// ============================================
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Home}/{action=Index}/{id?}");

app.Run();
