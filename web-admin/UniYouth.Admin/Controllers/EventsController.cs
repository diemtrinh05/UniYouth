using Microsoft.AspNetCore.Mvc;
using UniYouth.Admin.Models.DTOs;
using UniYouth.Admin.Models.DTOs.EventTypes;
using UniYouth.Admin.Models.DTOs.Events.Requests;
using UniYouth.Admin.Models.DTOs.Events.Responses;
using UniYouth.Admin.Models.ViewModels;
using UniYouth.Admin.Models.ViewModels.Events;
using UniYouth.Admin.Services;
using UniYouth.Admin.Services.Events;
using UniYouth.Admin.Services.EventPoints;
using UniYouth.Admin.Services.EventTypes;
using UniYouth.Admin.Services.LocationPresets;

namespace UniYouth.Admin.Controllers
{
    /// <summary>
    /// Controller quản lý Events (CRUD)
    /// 
    /// RESPONSIBILITIES:
    /// - Gọi Backend APIs qua ApiClientService
    /// - Map giữa DTOs (từ API) và ViewModels (cho View)
    /// - Xử lý validation errors
    /// - Redirect sau khi thao tác thành công
    /// 
    /// KHÔNG CHỨA:
    /// - Business logic (đã có ở API)
    /// - Direct database access
    /// - Complex calculations
    /// </summary>
    public class EventsController : BaseController
    {
        private const int DefaultInstituteId = 1;
        private const string DefaultInstituteName = "Viện Công Nghệ Số";

        private readonly IEventApiService _eventApi;
        private readonly IEventTypesApiService _eventTypesApi;
        private readonly ILocationPresetsApiService _locationPresetsApi;
        private readonly IEventPointsApiService _eventPointsApi;
        private readonly ILogger<EventsController> _logger;

        public EventsController(
            IEventApiService eventApi,
            IEventTypesApiService eventTypesApi,
            ILocationPresetsApiService locationPresetsApi,
            IEventPointsApiService eventPointsApi,
            ILogger<EventsController> logger)
        {
            _eventApi = eventApi;
            _eventTypesApi = eventTypesApi;
            _locationPresetsApi = locationPresetsApi;
            _eventPointsApi = eventPointsApi;
            _logger = logger;
        }

        /// <summary>
        /// GET: /Events
        /// Hiển thị danh sách events với pagination
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Index(
            int pageNumber = 1,
            int pageSize = 10,
            string? searchTerm = null,
            string? status = null,
            string? eventType = null,
            DateTime? dateFrom = null,
            DateTime? dateTo = null,
            int? instituteId = null,
            string? sortBy = null,
            string? sortDir = null)
        {
            _logger.LogInformation(
                "User {UserName} accessing Events list, page {PageNumber}",
                CurrentUserFullName,
                pageNumber);

            try
            {
                // Scope enforcement:
                // - Admin: may view across institutes (no default institute filter).
                // - CanBo: do not allow passing instituteId to override scope; backend enforces by token claims.
                if (!IsAdmin)
                {
                    instituteId = null;
                }

                // Persist filter state for UI (View reads ViewBag.*)
                ViewBag.SearchTerm = string.IsNullOrWhiteSpace(searchTerm) ? null : searchTerm.Trim();
                ViewBag.Status = string.IsNullOrWhiteSpace(status) ? null : status.Trim();
                ViewBag.EventType = string.IsNullOrWhiteSpace(eventType) ? null : eventType.Trim();
                ViewBag.DateFrom = dateFrom.HasValue ? dateFrom.Value.ToString("yyyy-MM-dd") : null;
                ViewBag.DateTo = dateTo.HasValue ? dateTo.Value.ToString("yyyy-MM-dd") : null;
                ViewBag.InstituteId = instituteId;
                ViewBag.SortBy = string.IsNullOrWhiteSpace(sortBy) ? null : sortBy.Trim();
                ViewBag.SortDir = string.IsNullOrWhiteSpace(sortDir) ? null : sortDir.Trim();

                // Load event types for the Index filter dropdown (use real TypeId/TypeName from backend).
                var eventTypesResult = await _eventTypesApi.GetEventTypesAsync();
                ViewBag.EventTypes = eventTypesResult.Success && eventTypesResult.Data != null
                    ? eventTypesResult.Data
                    : new List<EventTypeDto>();

                pageSize = pageSize <= 0 ? 10 : pageSize;
                pageNumber = pageNumber <= 0 ? 1 : pageNumber;

                // Swagger supports `status` (int) on GET /api/Events/admin
                var apiStatus = MapUiStatusToApiStatus(ViewBag.Status as string);

                var apiQ = ViewBag.SearchTerm as string;
                int? apiEventTypeId = int.TryParse(ViewBag.EventType as string, out var et) ? et : null;
                var apiStartFrom = dateFrom?.Date;
                var apiStartTo = dateTo?.Date.AddDays(1).AddTicks(-1);

                // Fetch all events once (accurate filter + stats) then paginate client-side
                var allEvents = await FetchAllEventsAsync(
                    status: apiStatus,
                    q: apiQ,
                    eventTypeId: apiEventTypeId,
                    instituteId: instituteId,
                    startFrom: apiStartFrom,
                    startTo: apiStartTo,
                    sortBy: ViewBag.SortBy as string,
                    sortDir: ViewBag.SortDir as string);
                if (allEvents == null)
                {
                    SetErrorMessage("Không thể tải danh sách sự kiện. Vui lòng thử lại sau.");
                    return View(new EventListViewModel());
                }

                var filtered = ApplyUiFilters(
                    allEvents,
                    ViewBag.SearchTerm as string,
                    ViewBag.Status as string,
                    ViewBag.EventType as string,
                    dateFrom,
                    dateTo);

                var now = DateTime.Now;
                var totalCount = filtered.Count;
                var totalPages = (int)Math.Ceiling(totalCount / (double)pageSize);
                if (totalPages <= 0) totalPages = 1;
                if (pageNumber > totalPages) pageNumber = totalPages;

                // Keep API ordering; do not re-sort client-side.
                var pageItems = filtered
                    .Skip((pageNumber - 1) * pageSize)
                    .Take(pageSize)
                    .ToList();

                var viewModel = new EventListViewModel
                {
                    Events = pageItems.Select(MapToListItemViewModel).ToList(),
                    TotalCount = totalCount,
                    PageNumber = pageNumber,
                    PageSize = pageSize,
                    TotalPages = totalPages,
                    HasPreviousPage = pageNumber > 1,
                    HasNextPage = pageNumber < totalPages,
                    UpcomingCount = filtered.Count(e => IsUpcoming(e, now)),
                    OngoingCount = filtered.Count(IsOngoing),
                    ClosedCount = filtered.Count(IsCompleted),
                    CancelledCount = filtered.Count(e => IsCancelled(e)),
                    TotalParticipants = filtered.Sum(e => e.CurrentParticipants ?? 0)
                };

                return View(viewModel);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading events list");
                SetErrorMessage("Đã có lỗi xảy ra. Vui lòng thử lại sau.");
                return View(new EventListViewModel());
            }
        }

        /// <summary>
        /// GET: /Events/Details/{id}
        /// Hiển thị chi tiết một event (read-only)
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Details(int id)
        {
            _logger.LogInformation("User {UserName} viewing event {EventId}", CurrentUserFullName, id);

            try
            {
                var eventDto = await _eventApi.GetEventByIdAsync(id);

                if (eventDto == null)
                {
                    SetErrorMessage($"Không tìm thấy sự kiện với ID {id}");
                    return RedirectToAction(nameof(Index));
                }

                // Map DTO sang ViewModel
                var viewModel = new EventDetailViewModel
                {
                    EventId = eventDto.EventId,
                    EventName = eventDto.EventName,
                    Description = eventDto.Description,
                    StartTime = eventDto.StartTime,
                    EndTime = eventDto.EndTime,
                    LocationName = eventDto.LocationName,
                    Latitude = eventDto.Latitude,
                    Longitude = eventDto.Longitude,
                    AllowRadius = eventDto.AllowRadius,
                    MaxParticipants = eventDto.MaxParticipants,
                    CurrentParticipants = eventDto.CurrentParticipants,
                    Status = MapEventStatus(eventDto.Status),
                    StatusName = eventDto.StatusName,
                    EventTypeName = eventDto.EventType?.TypeName,
                    InstituteName = eventDto.Institute?.InstituteName ?? DefaultInstituteName,
                    RegistrationDeadline = eventDto.RegistrationDeadline,
                    CreatedByName = eventDto.CreatedByName,
                    CreatedDate = eventDto.CreatedDate,
                    ImageUrls = eventDto.Images?.Select(i => i.ImageUrl ?? "").Where(u => !string.IsNullOrEmpty(u)).ToList() ?? new(),
                    EnableFaceVerification = eventDto.EnableFaceVerification
                };

                // EventPoints config check (swagger_v3.json: GET /api/events/{eventId}/points)
                var pointsResult = await _eventPointsApi.GetEventPointsAsync(id);
                if (pointsResult.Success && pointsResult.Data != null)
                {
                    viewModel.EventPointsCount = pointsResult.Data.Count;
                    viewModel.HasEventPointsConfigured = pointsResult.Data.Count > 0;
                }

                return View(viewModel);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading event {EventId}", id);
                SetErrorMessage("Không thể tải thông tin sự kiện.");
                return RedirectToAction(nameof(Index));
            }
        }

        /// <summary>
        /// GET: /Events/Create
        /// Hiển thị form tạo event mới
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Create()
        {
            _logger.LogInformation("User {UserName} accessing Create Event form", CurrentUserFullName);

            var viewModel = new CreateEventViewModel
            {
                StartTime = DateTime.Now.AddDays(1),
                EndTime = DateTime.Now.AddDays(1).AddHours(2),
                AllowRadius = 100,
                InstituteId = CurrentUserInstituteId ?? DefaultInstituteId,
                Status = 0, // Draft
                EnableFaceVerification = false
            };

            await PopulateEventTypesAsync(viewModel);
            await PopulateLocationPresetsAsync(viewModel);
            return View(viewModel);
        }

        /// <summary>
        /// POST: /Events/Create
        /// Xử lý tạo event mới
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Create(CreateEventViewModel model)
        {
            // Scope enforcement: CanBo must stay within institute scope from token claims.
            if (!IsAdmin)
            {
                model.InstituteId = CurrentUserInstituteId ?? DefaultInstituteId;
            }

            model.InstituteId ??= DefaultInstituteId;

            if (!ModelState.IsValid)
            {
                await PopulateEventTypesAsync(model);
                await PopulateLocationPresetsAsync(model);
                return View(model);
            }

            // Không cho phép tạo event ở trạng thái Closed/Cancelled.
            // Theo backend rules, "đã kết thúc/đã hủy" phải đi qua API riêng (close/cancel) sau khi event đã tồn tại.
            if (model.Status is 3 or 4)
            {
                ModelState.AddModelError(
                    nameof(model.Status),
                    "Không thể tạo sự kiện với trạng thái 'Đã kết thúc' hoặc 'Đã hủy'. Vui lòng tạo ở trạng thái Nháp hoặc Mở đăng ký.");

                await PopulateEventTypesAsync(model);
                await PopulateLocationPresetsAsync(model);
                return View(model);
            }

            // Validate server-side (chỉ chạy khi đã parse input thành công)
            if (!ValidateEventTimes(model.StartTime!.Value, model.EndTime!.Value, model.RegistrationDeadline))
            {
                await PopulateEventTypesAsync(model);
                await PopulateLocationPresetsAsync(model);
                return View(model);
            }

            try
            {
                _logger.LogInformation(
                    "User {UserName} creating event: {EventName}",
                    CurrentUserFullName,
                    model.EventName);

                // Map ViewModel sang Request DTO
                var requestDto = new CreateEventRequestDto
                {
                    EventName = model.EventName,
                    Description = model.Description,
                    StartTime = model.StartTime!.Value,
                    EndTime = model.EndTime!.Value,
                    LocationName = model.LocationName,
                    Latitude = model.Latitude,
                    Longitude = model.Longitude,
                    AllowRadius = model.AllowRadius,
                    MaxParticipants = model.MaxParticipants,
                    EventTypeId = model.EventTypeId!.Value,
                    InstituteId = model.InstituteId,
                    RegistrationDeadline = model.RegistrationDeadline,
                    Status = model.Status,
                    EnableFaceVerification = model.EnableFaceVerification
                };

                // Gọi API
                var result = await _eventApi.CreateEventAsync(requestDto);

                if (result.Success && result.Data != null)
                {
                    _logger.LogInformation("Event created successfully: {EventId}", result.Data.EventId);
                    SetSuccessMessage($"Tạo sự kiện '{model.EventName}' thành công!");
                    return RedirectToAction(nameof(Details), new { id = result.Data.EventId });
                }
                else
                {
                    ModelState.AddModelError("", result.ErrorMessage ?? "Không thể tạo sự kiện");
                    await PopulateEventTypesAsync(model);
                    await PopulateLocationPresetsAsync(model);
                    return View(model);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating event");
                ModelState.AddModelError("", "Đã có lỗi xảy ra. Vui lòng thử lại sau.");
                await PopulateEventTypesAsync(model);
                await PopulateLocationPresetsAsync(model);
                return View(model);
            }
        }

        /// <summary>
        /// GET: /Events/Edit/{id}
        /// Hiển thị form chỉnh sửa event
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Edit(int id)
        {
            _logger.LogInformation("User {UserName} editing event {EventId}", CurrentUserFullName, id);

            try
            {
                var eventDto = await _eventApi.GetEventByIdAsync(id);

                if (eventDto == null)
                {
                    SetErrorMessage($"Không tìm thấy sự kiện với ID {id}");
                    return RedirectToAction(nameof(Index));
                }

                // Map DTO sang ViewModel
                var viewModel = new EditEventViewModel
                {
                    EventId = eventDto.EventId,
                    EventName = eventDto.EventName,
                    Description = eventDto.Description,
                    StartTime = eventDto.StartTime,
                    EndTime = eventDto.EndTime,
                    LocationName = eventDto.LocationName,
                    Latitude = eventDto.Latitude,
                    Longitude = eventDto.Longitude,
                    AllowRadius = eventDto.AllowRadius ?? 100,
                    MaxParticipants = eventDto.MaxParticipants,
                    EventTypeId = eventDto.EventType?.TypeId,
                    InstituteId = eventDto.Institute?.InstituteId ?? DefaultInstituteId,
                    RegistrationDeadline = eventDto.RegistrationDeadline,
                    Status = eventDto.Status,
                    EnableFaceVerification = eventDto.EnableFaceVerification
                };

                await PopulateEventTypesAsync(viewModel);
                await PopulateLocationPresetsAsync(viewModel);
                return View(viewModel);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error loading event for edit {EventId}", id);
                SetErrorMessage("Không thể tải thông tin sự kiện.");
                return RedirectToAction(nameof(Index));
            }
        }

        /// <summary>
        /// POST: /Events/Edit/{id}
        /// Xử lý cập nhật event
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Edit(int id, EditEventViewModel model)
        {
            if (id != model.EventId)
            {
                return NotFound();
            }

            // Scope enforcement: CanBo must stay within institute scope from token claims.
            if (!IsAdmin)
            {
                model.InstituteId = CurrentUserInstituteId ?? DefaultInstituteId;
            }

            model.InstituteId ??= DefaultInstituteId;

            // Không cho phép chuyển sang "Cancelled" bằng cập nhật status trong Edit.
            // Theo backend, cần dùng API hủy sự kiện (PUT /api/Events/{id}/cancel).
            if (model.Status == 4)
            {
                ModelState.AddModelError(nameof(model.Status),
                    "Vui lòng dùng chức năng Hủy sự kiện để chuyển sang trạng thái 'Đã hủy'.");
            }

            // Không cho phép chuyển sang "Closed" bằng cập nhật status trong Edit.
            // Theo backend, cần dùng API kết thúc sự kiện (PUT /api/Events/{id}/close).
            if (model.Status == 3)
            {
                ModelState.AddModelError(nameof(model.Status),
                    "Vui lòng dùng chức năng Kết thúc sự kiện để chuyển sang trạng thái 'Đã kết thúc'.");
            }

            if (!ModelState.IsValid)
            {
                await PopulateEventTypesAsync(model);
                await PopulateLocationPresetsAsync(model);
                return View(model);
            }

            // Validate (chỉ chạy khi đã parse input thành công)
            if (!ValidateEventTimes(model.StartTime!.Value, model.EndTime!.Value, model.RegistrationDeadline))
            {
                await PopulateEventTypesAsync(model);
                await PopulateLocationPresetsAsync(model);
                return View(model);
            }

            try
            {
                _logger.LogInformation(
                    "User {UserName} updating event {EventId}",
                    CurrentUserFullName,
                    id);

                // Map ViewModel sang Request DTO
                var requestDto = new UpdateEventRequestDto
                {
                    EventName = model.EventName,
                    Description = model.Description,
                    StartTime = model.StartTime!.Value,
                    EndTime = model.EndTime!.Value,
                    LocationName = model.LocationName,
                    Latitude = model.Latitude,
                    Longitude = model.Longitude,
                    AllowRadius = model.AllowRadius,
                    MaxParticipants = model.MaxParticipants,
                    EventTypeId = model.EventTypeId!.Value,
                    InstituteId = model.InstituteId,
                    RegistrationDeadline = model.RegistrationDeadline,
                    Status = model.Status,
                    EnableFaceVerification = model.EnableFaceVerification
                };

                // Gọi API
                var result = await _eventApi.UpdateEventAsync(id, requestDto);

                if (result.Success)
                {
                    _logger.LogInformation("Event updated successfully: {EventId}", id);
                    SetSuccessMessage($"Cập nhật sự kiện '{model.EventName}' thành công!");
                    return RedirectToAction(nameof(Details), new { id });
                }
                else
                {
                    ModelState.AddModelError("", result.ErrorMessage ?? "Không thể cập nhật sự kiện");
                    await PopulateEventTypesAsync(model);
                    await PopulateLocationPresetsAsync(model);
                    return View(model);
                }
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error updating event {EventId}", id);
                ModelState.AddModelError("", "Đã có lỗi xảy ra. Vui lòng thử lại sau.");
                await PopulateEventTypesAsync(model);
                await PopulateLocationPresetsAsync(model);
                return View(model);
            }
        }

        /// <summary>
        /// POST: /Events/Cancel/{id}
        /// Hủy sự kiện (theo swagger: PUT /api/Events/{id}/cancel)
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Cancel(int id, string? reason, string? returnUrl = null)
        {
            try
            {
                var request = new CancelEventRequestDto
                {
                    Reason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim()
                };

                var result = await _eventApi.CancelEventAsync(id, request);

                if (result.Success)
                {
                    SetSuccessMessage(string.IsNullOrWhiteSpace(result.ErrorMessage)
                        ? "Đã hủy sự kiện thành công."
                        : result.ErrorMessage!);

                    if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
                    {
                        return Redirect(returnUrl);
                    }

                    return RedirectToAction(nameof(Details), new { id });
                }

                SetErrorMessage(result.ErrorMessage ?? "Không thể hủy sự kiện.");

                if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
                {
                    return Redirect(returnUrl);
                }

                return RedirectToAction(nameof(Details), new { id });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error cancelling event {EventId}", id);
                SetErrorMessage("Đã xảy ra lỗi khi hủy sự kiện.");

                if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
                {
                    return Redirect(returnUrl);
                }

                return RedirectToAction(nameof(Details), new { id });
            }
        }

        /// <summary>
        /// POST: /Events/Close/{id}
        /// Kết thúc sự kiện (theo swagger: PUT /api/Events/{id}/close)
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Close(int id, string? returnUrl = null)
        {
            try
            {
                var result = await _eventApi.CloseEventAsync(id);

                if (result.Success)
                {
                    SetSuccessMessage(string.IsNullOrWhiteSpace(result.ErrorMessage)
                        ? "Đã kết thúc sự kiện thành công."
                        : result.ErrorMessage!);

                    if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
                    {
                        return Redirect(returnUrl);
                    }

                    return RedirectToAction(nameof(Details), new { id });
                }

                SetErrorMessage(result.ErrorMessage ?? "Không thể kết thúc sự kiện.");

                if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
                {
                    return Redirect(returnUrl);
                }

                return RedirectToAction(nameof(Details), new { id });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error closing event {EventId}", id);
                SetErrorMessage("Đã xảy ra lỗi khi kết thúc sự kiện.");

                if (!string.IsNullOrWhiteSpace(returnUrl) && Url.IsLocalUrl(returnUrl))
                {
                    return Redirect(returnUrl);
                }

                return RedirectToAction(nameof(Details), new { id });
            }
        }

        #region Private Helpers

        private async Task PopulateEventTypesAsync(CreateEventViewModel model)
        {
            var result = await _eventTypesApi.GetEventTypesAsync();
            model.EventTypes = result.Success && result.Data != null ? result.Data : new();
        }

        private async Task PopulateEventTypesAsync(EditEventViewModel model)
        {
            var result = await _eventTypesApi.GetEventTypesAsync();
            model.EventTypes = result.Success && result.Data != null ? result.Data : new();
        }

        private async Task PopulateLocationPresetsAsync(CreateEventViewModel model)
        {
            try
            {
                var result = await _locationPresetsApi.GetLocationPresetsAsync(
                    pageNumber: 1,
                    pageSize: 200,
                    q: null,
                    instituteId: IsAdmin ? model.InstituteId : null,
                    includeInactive: false);

                if (result.Success && result.Data?.Items != null)
                {
                    model.LocationPresets = result.Data.Items;
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Không thể tải location presets cho CreateEventViewModel");
            }
        }

        private async Task PopulateLocationPresetsAsync(EditEventViewModel model)
        {
            try
            {
                var result = await _locationPresetsApi.GetLocationPresetsAsync(
                    pageNumber: 1,
                    pageSize: 200,
                    q: null,
                    instituteId: IsAdmin ? model.InstituteId : null,
                    includeInactive: false);

                if (result.Success && result.Data?.Items != null)
                {
                    model.LocationPresets = result.Data.Items;
                }
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "Không thể tải location presets cho EditEventViewModel");
            }
        }

        private async Task<List<EventListItemDto>?> FetchAllEventsAsync(
            int? status,
            string? q,
            int? eventTypeId,
            int? instituteId,
            DateTime? startFrom,
            DateTime? startTo,
            string? sortBy,
            string? sortDir)
        {
            const int fetchPageSize = 200;
            const int maxPages = 100;
            const int maxItems = 20000;

            var all = new List<EventListItemDto>();
            int pageNumber = 1;

            while (pageNumber <= maxPages && all.Count < maxItems)
            {
                var resp = await _eventApi.GetEventsAsync(
                    pageNumber: pageNumber,
                    pageSize: fetchPageSize,
                    q: q,
                    eventTypeId: eventTypeId,
                    instituteId: instituteId,
                    startDate: startFrom,
                    endDate: startTo,
                    sortBy: sortBy,
                    sortDir: sortDir,
                    status: status);

                if (resp == null)
                {
                    return null;
                }

                if (resp.Items != null && resp.Items.Count > 0)
                {
                    all.AddRange(resp.Items);
                }

                if (!resp.HasNextPage || pageNumber >= resp.TotalPages)
                {
                    break;
                }

                pageNumber++;
            }

            if (pageNumber > maxPages || all.Count >= maxItems)
            {
                _logger.LogWarning(
                    "Events list truncated while fetching all events. PagesFetched={PagesFetched}, Items={Items}",
                    pageNumber,
                    all.Count);
            }

            return all;
        }

        private static List<EventListItemDto> ApplyUiFilters(
            List<EventListItemDto> source,
            string? searchTerm,
            string? status,
            string? eventType,
            DateTime? dateFrom,
            DateTime? dateTo)
        {
            IEnumerable<EventListItemDto> q = source;

            if (!string.IsNullOrWhiteSpace(searchTerm))
            {
                q = q.Where(e =>
                    (!string.IsNullOrWhiteSpace(e.EventName) && e.EventName.Contains(searchTerm, StringComparison.OrdinalIgnoreCase)) ||
                    (!string.IsNullOrWhiteSpace(e.LocationName) && e.LocationName.Contains(searchTerm, StringComparison.OrdinalIgnoreCase)) ||
                    (!string.IsNullOrWhiteSpace(e.Description) && e.Description.Contains(searchTerm, StringComparison.OrdinalIgnoreCase)));
            }

            // NOTE: Event type filter is handled by backend via GET /api/Events/admin?eventTypeId=...
            // Avoid client-side mapping by hardcoded labels which can drift from backend data.

            if (dateFrom.HasValue)
            {
                var from = dateFrom.Value.Date;
                q = q.Where(e => e.StartTime.Date >= from);
            }

            if (dateTo.HasValue)
            {
                var to = dateTo.Value.Date;
                q = q.Where(e => e.StartTime.Date <= to);
            }

            if (!string.IsNullOrWhiteSpace(status))
            {
                var now = DateTime.Now;
                q = status switch
                {
                    "upcoming" => q.Where(e => IsUpcoming(e, now)),
                    "ongoing" => q.Where(IsOngoing),
                    "completed" => q.Where(IsCompleted),
                    "cancelled" => q.Where(e => IsCancelled(e)),
                    _ => q
                };
            }

            return q.ToList();
        }

        private static int? MapUiStatusToApiStatus(string? status)
        {
            return status switch
            {
                // "Sắp diễn ra" đang được tính theo thời gian (StartTime > now),
                // không tương đương 1 status cố định của API => không filter ở API để tránh mất dữ liệu.
                "upcoming" => null,
                "ongoing" => 2,
                "completed" => 3,
                "cancelled" => 4,
                _ => null
            };
        }

        private static bool IsCancelled(EventListItemDto e) => e.Status == 4;

        private static bool IsCompleted(EventListItemDto e) => e.Status == 3;

        private static bool IsOngoing(EventListItemDto e) => e.Status == 2;

        private static bool IsUpcoming(EventListItemDto e, DateTime now) =>
            e.StartTime > now && (e.Status == 0 || e.Status == 1);

        private EventListItemViewModel MapToListItemViewModel(EventListItemDto e)
        {
            return new EventListItemViewModel
            {
                EventId = e.EventId,
                EventName = e.EventName,
                Description = e.Description,
                StartTime = e.StartTime,
                EndTime = e.EndTime,
                LocationName = e.LocationName,
                MaxParticipants = e.MaxParticipants,
                CurrentParticipants = e.CurrentParticipants,
                Status = MapEventStatus(e.Status),
                StatusName = e.StatusName,
                EventTypeName = e.EventTypeName,
                InstituteName = e.InstituteName ?? DefaultInstituteName,
                ThumbnailUrl = e.ThumbnailUrl,
                EnableFaceVerification = e.EnableFaceVerification
            };
        }

        /// <summary>
        /// Validate thời gian của event
        /// </summary>
        private bool ValidateEventTimes(DateTime startTime, DateTime endTime, DateTime? registrationDeadline)
        {
            bool isValid = true;

            if (endTime <= startTime)
            {
                ModelState.AddModelError("EndTime", "Thời gian kết thúc phải sau thời gian bắt đầu");
                isValid = false;
            }

            if (registrationDeadline.HasValue && registrationDeadline.Value >= startTime)
            {
                ModelState.AddModelError("RegistrationDeadline", "Hạn đăng ký phải trước thời gian bắt đầu sự kiện");
                isValid = false;
            }

            return isValid;
        }

        /// <summary>
        /// Map event status number sang string
        /// </summary>
        private string MapEventStatus(int status)
        {
            return status switch
            {
                0 => "Draft",
                1 => "Open",
                2 => "Ongoing",
                3 => "Closed",
                4 => "Cancelled",
                _ => "Unknown"
            };
        }

        #endregion
    }
}
