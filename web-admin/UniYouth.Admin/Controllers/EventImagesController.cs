using System.Net.Http.Headers;
using System.Text.Json;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Admin.Filters;
using UniYouth.Admin.Models.DTOs.EventImages;
using UniYouth.Admin.Models.ViewModels.EventImages;
using UniYouth.Admin.Services.EventImages;

namespace UniYouth.Admin.Controllers
{
    /// <summary>
    /// Controller quản lý hình ảnh sự kiện
    /// Kế thừa từ BaseController để có thông tin user và các helper methods
    /// Sử dụng AdminAuthorizeFilter để kiểm tra quyền truy cập
    /// </summary>
    [ServiceFilter(typeof(AdminAuthorizeFilter))]
    public class EventImagesController : BaseController
    {
        private readonly IEventImagesApiService _eventImagesService;
        private readonly ILogger<EventImagesController> _logger;
        private readonly long _maxFileSize;
        private readonly HashSet<string> _allowedMimeTypes;
        private readonly HashSet<string> _allowedExtensions;

        // Các loại hình ảnh được phép dựa theo API specification
        private static readonly string[] AllowedImageTypes = { "Banner", "Gallery", "Thumbnail" };

        public EventImagesController(
            IEventImagesApiService eventImagesService,
            ILogger<EventImagesController> logger,
            IConfiguration configuration)
        {
            _eventImagesService = eventImagesService;
            _logger = logger;

            _maxFileSize = configuration.GetValue<long>("FileUpload:MaxFileSize");
            if (_maxFileSize <= 0)
            {
                // Fallback an toàn nếu cấu hình bị thiếu/sai
                _maxFileSize = 3 * 1024 * 1024;
                _logger.LogWarning("Thiếu/không hợp lệ cấu hình FileUpload:MaxFileSize. Dùng fallback {Max} bytes.", _maxFileSize);
            }

            var configuredMimeTypes = configuration
                .GetSection("FileUpload:AllowedMimeTypes")
                .Get<string[]>();
            _allowedMimeTypes = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (configuredMimeTypes != null)
            {
                foreach (var mt in configuredMimeTypes)
                {
                    if (!string.IsNullOrWhiteSpace(mt))
                    {
                        _allowedMimeTypes.Add(mt.Trim());
                    }
                }
            }

            // Một số client có thể gửi image/jpg thay cho image/jpeg
            if (_allowedMimeTypes.Contains("image/jpeg"))
            {
                _allowedMimeTypes.Add("image/jpg");
            }

            var configuredExtensions = configuration
                .GetSection("FileUpload:AllowedExtensions")
                .Get<string[]>();
            _allowedExtensions = new HashSet<string>(StringComparer.OrdinalIgnoreCase);
            if (configuredExtensions != null)
            {
                foreach (var ext in configuredExtensions)
                {
                    if (string.IsNullOrWhiteSpace(ext)) continue;
                    var normalized = ext.Trim();
                    if (!normalized.StartsWith('.'))
                    {
                        normalized = "." + normalized;
                    }

                    _allowedExtensions.Add(normalized);
                }
            }

            if (_allowedMimeTypes.Count == 0 || _allowedExtensions.Count == 0)
            {
                _logger.LogWarning("Thiếu cấu hình FileUpload:AllowedMimeTypes/AllowedExtensions. Validate upload có thể bị lệch so với backend.");
            }
        }

        /// <summary>
        /// Hiển thị danh sách hình ảnh của sự kiện
        /// GET: /EventImages/Index/{eventId}
        /// </summary>
        [HttpGet]
        public async Task<IActionResult> Index(int eventId)
        {
            try
            {
                // Kiểm tra eventId hợp lệ
                if (eventId <= 0)
                {
                    SetErrorMessage("ID sự kiện không hợp lệ.");
                    return RedirectToAction("Index", "Events");
                }

                // Lấy thông tin sự kiện
                var eventResult = await _eventImagesService.GetEventDetailAsync(eventId);
                if (!eventResult.Success || eventResult.Data == null)
                {
                    SetErrorMessage(eventResult.ErrorMessage ?? "Không tìm thấy sự kiện.");
                    return RedirectToAction("Index", "Events");
                }

                // Lấy danh sách hình ảnh
                var imagesResult = await _eventImagesService.GetEventImagesAsync(eventId);

                // Tạo ViewModel
                var viewModel = new EventImagesPageViewModel
                {
                    EventId = eventId,
                    EventName = eventResult.Data.EventName ?? "Sự kiện không xác định",
                    Images = imagesResult.Success && imagesResult.Data != null
                        ? imagesResult.Data.Select(MapToViewModel).OrderBy(i => i.DisplayOrder).ToList()
                        : new List<EventImageViewModel>(),
                    AvailableImageTypes = AllowedImageTypes
                };

                // Log thông tin
                _logger.LogInformation(
                    "User {UserId} đang xem hình ảnh của sự kiện {EventId}",
                    CurrentUserId,
                    eventId);

                return View(viewModel);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi tải trang quản lý hình ảnh cho sự kiện {EventId}", eventId);
                SetErrorMessage("Đã xảy ra lỗi khi tải trang. Vui lòng thử lại.");
                return RedirectToAction("Index", "Events");
            }
        }

        /// <summary>
        /// Upload hình ảnh mới cho sự kiện
        /// POST: /EventImages/Upload
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Upload(int eventId, UploadEventImageViewModel model)
        {
            try
            {
                // Validate đầu vào cơ bản
                if (eventId <= 0)
                {
                    SetErrorMessage("ID sự kiện không hợp lệ.");
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                if (model.Files == null || !model.Files.Any())
                {
                    SetErrorMessage("Vui lòng chọn ít nhất một hình ảnh để tải lên.");
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                if (string.IsNullOrEmpty(model.ImageType) ||
                    !AllowedImageTypes.Contains(model.ImageType))
                {
                    SetErrorMessage("Loại hình ảnh không hợp lệ.");
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                // Validate từng file
                var validationErrors = ValidateFiles(model.Files);
                if (validationErrors.Any())
                {
                    SetErrorMessage(string.Join("<br/>", validationErrors));
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                // Gọi service để upload
                var result = await _eventImagesService.UploadImagesAsync(
                    eventId,
                    model.Files,
                    model.ImageType,
                    model.Caption);

                if (result.Success && result.Data != null)
                {
                    SetSuccessMessage($"Đã tải lên thành công {result.Data.UploadedCount} hình ảnh.");

                    _logger.LogInformation(
                        "User {UserId} đã upload {Count} hình ảnh cho sự kiện {EventId}",
                        CurrentUserId,
                        result.Data.UploadedCount,
                        eventId);
                }
                else
                {
                    SetErrorMessage(result.ErrorMessage ?? "Không thể tải lên hình ảnh. Vui lòng thử lại.");
                }

                return RedirectToAction(nameof(Index), new { eventId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi upload hình ảnh cho sự kiện {EventId}", eventId);
                SetErrorMessage("Đã xảy ra lỗi khi tải lên hình ảnh. Vui lòng thử lại.");
                return RedirectToAction(nameof(Index), new { eventId });
            }
        }

        /// <summary>
        /// Xóa hình ảnh
        /// POST: /EventImages/Delete
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> Delete(int eventId, int imageId)
        {
            try
            {
                // Validate
                if (eventId <= 0 || imageId <= 0)
                {
                    SetErrorMessage("Thông tin không hợp lệ.");
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                // Gọi service để xóa
                var result = await _eventImagesService.DeleteImageAsync(imageId);

                if (result.Success)
                {
                    SetSuccessMessage("Đã xóa hình ảnh thành công.");

                    _logger.LogInformation(
                        "User {UserId} đã xóa hình ảnh {ImageId} của sự kiện {EventId}",
                        CurrentUserId,
                        imageId,
                        eventId);
                }
                else
                {
                    SetErrorMessage(result.ErrorMessage ?? "Không thể xóa hình ảnh.");
                }

                return RedirectToAction(nameof(Index), new { eventId });
            }
            catch (Exception ex)
            {
                _logger.LogError(
                    ex,
                    "Lỗi khi xóa hình ảnh {ImageId} của sự kiện {EventId}",
                    imageId,
                    eventId);
                SetErrorMessage("Đã xảy ra lỗi khi xóa hình ảnh. Vui lòng thử lại.");
                return RedirectToAction(nameof(Index), new { eventId });
            }
        }

        /// <summary>
        /// Cập nhật thứ tự hiển thị của hình ảnh
        /// POST: /EventImages/UpdateOrder
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateOrder(int eventId, UpdateImageOrderViewModel model)
        {
            try
            {
                if (eventId <= 0 || model.ImageId <= 0)
                {
                    SetErrorMessage("Dữ liệu không hợp lệ.");
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                var result = await _eventImagesService.UpdateImageOrderAsync(
                    model.ImageId,
                    model.DisplayOrder);

                if (result.Success)
                {
                    SetSuccessMessage("Đã cập nhật thứ tự hiển thị.");
                }
                else
                {
                    SetErrorMessage(result.ErrorMessage ?? "Không thể cập nhật thứ tự hiển thị.");
                }

                return RedirectToAction(nameof(Index), new { eventId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex,
                    "Lỗi khi cập nhật thứ tự hình ảnh {ImageId}",
                    model.ImageId);

                SetErrorMessage("Đã xảy ra lỗi khi cập nhật thứ tự hiển thị.");
                return RedirectToAction(nameof(Index), new { eventId });
            }
        }

        /// <summary>
        /// Cập nhật metadata hình ảnh (ImageType, Caption)
        /// POST: /EventImages/UpdateMetadata
        /// </summary>
        [HttpPost]
        [ValidateAntiForgeryToken]
        public async Task<IActionResult> UpdateMetadata(int eventId, UpdateEventImageMetadataViewModel model)
        {
            try
            {
                if (eventId <= 0 || model.ImageId <= 0)
                {
                    SetErrorMessage("Dữ liệu không hợp lệ.");
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                if (!ModelState.IsValid)
                {
                    SetErrorMessage("Vui lòng kiểm tra lại dữ liệu nhập.");
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                if (!AllowedImageTypes.Contains(model.ImageType))
                {
                    SetErrorMessage("Loại hình ảnh không hợp lệ.");
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                var request = new UpdateEventImageRequestDto
                {
                    ImageType = model.ImageType,
                    Caption = model.Caption
                };

                // Update display order trước
                var orderResult = await _eventImagesService.UpdateImageOrderAsync(
                    model.ImageId,
                    model.DisplayOrder);
                if (!orderResult.Success)
                {
                    SetErrorMessage(orderResult.ErrorMessage ?? "Không thể cập nhật thứ tự hiển thị.");
                    return RedirectToAction(nameof(Index), new { eventId });
                }

                // Update metadata
                var metaResult = await _eventImagesService.UpdateImageMetadataAsync(model.ImageId, request);

                if (metaResult.Success)
                {
                    SetSuccessMessage("Đã cập nhật thông tin hình ảnh.");
                }
                else
                {
                    SetErrorMessage(metaResult.ErrorMessage ?? "Không thể cập nhật thông tin hình ảnh.");
                }

                return RedirectToAction(nameof(Index), new { eventId });
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật metadata hình ảnh {ImageId}", model.ImageId);
                SetErrorMessage("Đã xảy ra lỗi khi cập nhật thông tin hình ảnh.");
                return RedirectToAction(nameof(Index), new { eventId });
            }
        }


        #region Helper Methods

        /// <summary>
        /// Validate danh sách files
        /// </summary>
        private List<string> ValidateFiles(IFormFile[] files)
        {
            var errors = new List<string>();

            foreach (var file in files)
            {
                // Kiểm tra file rỗng
                if (file.Length == 0)
                {
                    errors.Add($"File '{file.FileName}' rỗng.");
                    continue;
                }

                // Kiểm tra kích thước
                if (file.Length > _maxFileSize)
                {
                    var sizeMB = _maxFileSize / (1024.0 * 1024.0);
                    errors.Add($"File '{file.FileName}' vượt quá kích thước tối đa {sizeMB:F0}MB.");
                    continue;
                }

                // Kiểm tra MIME type
                var contentType = (file.ContentType ?? string.Empty).Trim();
                if (string.IsNullOrWhiteSpace(contentType) || (_allowedMimeTypes.Count > 0 && !_allowedMimeTypes.Contains(contentType)))
                {
                    errors.Add($"File '{file.FileName}' có định dạng không hợp lệ. Chỉ chấp nhận: {string.Join(", ", _allowedMimeTypes.OrderBy(x => x))}.");
                    continue;
                }

                // Kiểm tra extension (best-effort; backend vẫn là nguồn quyết định)
                var ext = Path.GetExtension(file.FileName ?? string.Empty);
                if (string.IsNullOrWhiteSpace(ext) || (_allowedExtensions.Count > 0 && !_allowedExtensions.Contains(ext)))
                {
                    errors.Add($"File '{file.FileName}' có phần mở rộng không hợp lệ. Chỉ chấp nhận: {string.Join(", ", _allowedExtensions.OrderBy(x => x))}.");
                    continue;
                }

                // Kiểm tra magic bytes (best-effort; backend vẫn là nguồn quyết định)
                if (!HasValidMagicBytes(file, contentType))
                {
                    errors.Add($"File '{file.FileName}' không khớp định dạng thực tế (magic bytes). Vui lòng chọn đúng file ảnh.");
                }
            }

            return errors;
        }

        private static bool HasValidMagicBytes(IFormFile file, string contentType)
        {
            try
            {
                // Read enough bytes for all supported signatures (WEBP needs 12 bytes).
                Span<byte> header = stackalloc byte[12];
                var read = 0;
                using (var stream = file.OpenReadStream())
                {
                    while (read < header.Length)
                    {
                        var n = stream.Read(header.Slice(read));
                        if (n <= 0) break;
                        read += n;
                    }
                }

                if (read < 3)
                {
                    return false;
                }

                // JPEG: FF D8 FF
                if (string.Equals(contentType, "image/jpeg", StringComparison.OrdinalIgnoreCase) ||
                    string.Equals(contentType, "image/jpg", StringComparison.OrdinalIgnoreCase))
                {
                    return header[0] == 0xFF && header[1] == 0xD8 && header[2] == 0xFF;
                }

                // PNG: 89 50 4E 47 0D 0A 1A 0A
                if (string.Equals(contentType, "image/png", StringComparison.OrdinalIgnoreCase))
                {
                    if (read < 8) return false;
                    return header[0] == 0x89 && header[1] == 0x50 && header[2] == 0x4E && header[3] == 0x47 &&
                           header[4] == 0x0D && header[5] == 0x0A && header[6] == 0x1A && header[7] == 0x0A;
                }

                // GIF: "GIF87a" or "GIF89a"
                if (string.Equals(contentType, "image/gif", StringComparison.OrdinalIgnoreCase))
                {
                    if (read < 6) return false;
                    return header[0] == (byte)'G' && header[1] == (byte)'I' && header[2] == (byte)'F' &&
                           header[3] == (byte)'8' && (header[4] == (byte)'7' || header[4] == (byte)'9') &&
                           header[5] == (byte)'a';
                }

                // WEBP: "RIFF"...."WEBP"
                if (string.Equals(contentType, "image/webp", StringComparison.OrdinalIgnoreCase))
                {
                    if (read < 12) return false;
                    return header[0] == (byte)'R' && header[1] == (byte)'I' && header[2] == (byte)'F' && header[3] == (byte)'F' &&
                           header[8] == (byte)'W' && header[9] == (byte)'E' && header[10] == (byte)'B' && header[11] == (byte)'P';
                }

                // Unknown content-type (shouldn't happen due to AllowedMimeTypes check)
                return false;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Ánh xạ DTO sang ViewModel
        /// </summary>
        private static EventImageViewModel MapToViewModel(EventImagesDto dto)
        {
            return new EventImageViewModel
            {
                ImageId = dto.ImageId,
                ImageUrl = dto.ImageUrl ?? string.Empty,
                ImageType = dto.ImageType ?? "Gallery",
                Caption = dto.Caption,
                DisplayOrder = dto.DisplayOrder ?? 0
            };
        }

        #endregion
    }
}
