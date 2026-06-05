using Microsoft.EntityFrameworkCore;
using UniYouth.Api.Contracts.DTOs.Events;
using UniYouth.Api.Domain.Entities;
using UniYouth.Api.Infrastructure.Data;
using UniYouth.Api.Shared.Helpers;

namespace UniYouth.Api.Application.Services
{
    /// <summary>
    /// Interface quản lý hình ảnh sự kiện
    /// </summary>
    public interface IEventImageService
    {
        Task<UploadEventImageResponseDto> UploadImagesAsync(
            int eventId,
            IFormFileCollection files,
            string webRootPath,
            string? imageType = null,
            string? caption = null);

        Task<List<EventImagesDto>> GetEventImagesAsync(int eventId);

        Task<bool> DeleteImageAsync(int imageId, string webRootPath);
        Task<bool> UpdateImageOrderAsync(int imageId, int displayOrder);
        Task<EventImagesDto?> UpdateImageMetaAsync(int imageId, string? imageType, string? caption);

    }

    /// <summary>
    /// Service xử lý các nghiệp vụ liên quan đến ảnh sự kiện
    /// 
    /// TẠI SAO TÁCH RIÊNG UPLOAD ẢNH KHỎI TẠO SỰ KIỆN?
    /// 1. Hiệu năng: Upload file lớn không làm chậm việc tạo sự kiện
    /// 2. Linh hoạt: Có thể thêm / xóa ảnh sau khi sự kiện đã được tạo
    /// 3. Trải nghiệm người dùng: Tạo sự kiện nhanh, upload ảnh sau
    /// 4. Xử lý lỗi: Nếu upload ảnh lỗi thì dữ liệu sự kiện vẫn được lưu
    /// 5. Tối ưu mobile: App mobile có thể upload ảnh từng bước
    /// </summary>
    public class EventImageService : IEventImageService
    {
        private readonly UniYouthDbContext _context;
        private readonly ILogger<EventImageService> _logger;
        private readonly IPublicUrlBuilder _publicUrlBuilder;
        public EventImageService(
            UniYouthDbContext context,
            ILogger<EventImageService> logger,
            IPublicUrlBuilder publicUrlBuilder)
        {
            _context = context;
            _logger = logger;
            _publicUrlBuilder = publicUrlBuilder;
        }

        /// <summary>
        /// Upload một hoặc nhiều ảnh cho sự kiện
        /// Thực hiện validate file, lưu file vật lý và tạo bản ghi trong CSDL
        /// </summary>
        public async Task<UploadEventImageResponseDto> UploadImagesAsync(
            int eventId,
            IFormFileCollection files,
            string webRootPath,
            string? imageType = null,
            string? caption = null)
        {
            try
            {
                _logger.LogInformation("Đang upload {Count} ảnh cho EventId: {EventId}",
                    files.Count, eventId);

                // 1. Kiểm tra sự kiện có tồn tại không
                var eventExists = await _context.Set<Event>()
                    .AnyAsync(e => e.EventID == eventId);

                if (!eventExists)
                {
                    throw new InvalidOperationException("Sự kiện không tồn tại");
                }

                // 2. Kiểm tra loại ảnh (nếu có truyền lên)
                if (!EventImageHelper.IsValidImageType(imageType))
                {
                    throw new InvalidOperationException(
                        "Loại ảnh không hợp lệ. Chỉ chấp nhận: Banner, Gallery, Thumbnail");
                }

                // 3. Lấy DisplayOrder lớn nhất hiện tại của sự kiện
                var maxDisplayOrder = await _context.Set<EventImage>()
                    .Where(ei => ei.EventID == eventId)
                    .MaxAsync(ei => (int?)ei.DisplayOrder) ?? 0;

                var uploadedImages = new List<EventImagesDto>();
                var currentDisplayOrder = maxDisplayOrder;

                // 4. Xử lý từng file
                foreach (var file in files)
                {
                    try
                    {
                        // Validate file
                        var (isValid, errorMessage) = EventImageHelper.ValidateEventImage(file);
                        if (!isValid)
                        {
                            _logger.LogWarning("File validation failed: {Error} - {FileName}",
                                errorMessage, file.FileName);
                            continue; // Skip invalid files, continue with others
                        }

                        // SECURITY: Kiểm tra chữ ký file để đảm bảo đúng là ảnh
                        using (var stream = file.OpenReadStream())
                        {
                            var isValidImage = await EventImageHelper.IsValidImageFileSignature(stream);
                            if (!isValidImage)
                            {
                                _logger.LogWarning("Chữ ký file không hợp lệ: {FileName}", file.FileName);
                                continue;
                            }
                        }

                        // Sinh tên file duy nhất
                        var extension = Path.GetExtension(file.FileName).ToLower();
                        var fileName = EventImageHelper.GenerateEventImageFileName(eventId, extension);

                        // Chuẩn bị thư mục lưu trữ
                        var uploadDirectory = EventImageHelper.GetEventImageDirectory(webRootPath, eventId);
                        EventImageHelper.EnsureDirectoryExists(uploadDirectory);

                        var filePath = Path.Combine(uploadDirectory, fileName);

                        // Lưu file xuống ổ đĩa
                        using (var stream = new FileStream(filePath, FileMode.Create))
                        {
                            await file.CopyToAsync(stream);
                        }

                        _logger.LogInformation("Đã lưu file: {FilePath}", filePath);

                        // Tạo URL public
                        var relativeUrl = EventImageHelper.GetPublicImageUrl(eventId, fileName);

                        //var publicUrl = $"{request.Scheme}://{request.Host}{relativeUrl}";

                        // Tạo bản ghi CSDL
                        currentDisplayOrder++;
                        var eventImage = new EventImage
                        {
                            EventID = eventId,
                            ImageUrl = relativeUrl,
                            ImageType = imageType,
                            Caption = caption,
                            DisplayOrder = currentDisplayOrder,
                            CreatedDate = DateTime.Now
                        };

                        _context.Set<EventImage>().Add(eventImage);
                        await _context.SaveChangesAsync();
                        // Thêm vào response
                        uploadedImages.Add(new EventImagesDto
                        {
                            ImageId = eventImage.ImageID,
                            EventId = eventImage.EventID,
                            ImageUrl = BuildFullUrl(eventImage.ImageUrl),
                            ImageType = eventImage.ImageType,
                            Caption = eventImage.Caption,
                            DisplayOrder = eventImage.DisplayOrder,
                            CreatedDate = eventImage.CreatedDate
                        });

                        _logger.LogInformation("Upload ảnh thành công: ImageId {ImageId}",
                            eventImage.ImageID);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Lỗi khi upload file: {FileName}", file.FileName);
                        // Không dừng toàn bộ quá trình, tiếp tục file khác
                    }
                }

                return new UploadEventImageResponseDto
                {
                    UploadedCount = uploadedImages.Count,
                    Images = uploadedImages,
                    Message = $"Đã tải lên thành công {uploadedImages.Count} ảnh"
                };
            }
            catch (InvalidOperationException)
            {
                // Ném lại lỗi nghiệp vụ
                throw;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi upload ảnh cho EventId: {EventId}", eventId);
                throw;
            }
        }

        /// <summary>
        /// Lấy danh sách ảnh của một sự kiện
        /// Trả về theo thứ tự DisplayOrder
        /// </summary>
        public async Task<List<EventImagesDto>> GetEventImagesAsync(int eventId)
        {
            try
            {
                _logger.LogInformation("Lấy danh sách ảnh cho EventId: {EventId}", eventId);
                var rawImages = await _context.Set<EventImage>()
                    .AsNoTracking()
                    .Where(ei => ei.EventID == eventId)
                    .OrderBy(ei => ei.DisplayOrder)
                    .Select(ei => new
                    {
                        ImageId = ei.ImageID,
                        EventId = ei.EventID,
                        ImageUrl = ei.ImageUrl,
                        ImageType = ei.ImageType,
                        Caption = ei.Caption,
                        DisplayOrder = ei.DisplayOrder,
                        CreatedDate = ei.CreatedDate
                    })
                    .ToListAsync();

                var images = rawImages.Select(ei => new EventImagesDto
                {
                    ImageId = ei.ImageId,
                    EventId = ei.EventId,
                    ImageUrl = BuildFullUrl(ei.ImageUrl),
                    ImageType = ei.ImageType,
                    Caption = ei.Caption,
                    DisplayOrder = ei.DisplayOrder,
                    CreatedDate = ei.CreatedDate
                }).ToList();

                return images;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi lấy danh sách ảnh cho EventId: {EventId}", eventId);
                throw;
            }
        }

        /// <summary>
        /// Xóa ảnh sự kiện
        /// Xóa cả bản ghi CSDL và file vật lý
        /// IMPORTANT: Phải xóa cả hai để tránh file rác
        /// </summary>
        public async Task<bool> DeleteImageAsync(int imageId, string webRootPath)
        {
            try
            {
                _logger.LogInformation("Đang xóa ảnh: ImageId {ImageId}", imageId);

                // Tìm ảnh trong CSDL
                var image = await _context.Set<EventImage>()
                    .FirstOrDefaultAsync(ei => ei.ImageID == imageId);

                if (image == null)
                {
                    _logger.LogWarning("Không tìm thấy ảnh: ImageId {ImageId}", imageId);
                    return false;
                }

                // Tách tên file từ URL
                // URL format: /uploads/events/{eventId}/{filename}
                var fileName = Path.GetFileName(image.ImageUrl);
                var uploadDirectory = EventImageHelper.GetEventImageDirectory(
                    webRootPath,
                    image.EventID);
                var filePath = Path.Combine(uploadDirectory, fileName);

                // Xóa file vật lý trước
                EventImageHelper.DeleteFileIfExists(filePath);
                _logger.LogInformation("Đã xóa file vật lý: {FilePath}", filePath);

                // Xóa bản ghi trong CSDL
                _context.Set<EventImage>().Remove(image);
                await _context.SaveChangesAsync();

                _logger.LogInformation("Xóa ảnh thành công: ImageId {ImageId}", imageId);

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi xóa ảnh: ImageId {ImageId}", imageId);
                throw;
            }
        }

        /// <summary>
        /// Cập nhật thứ tự hiển thị (DisplayOrder) của ảnh sự kiện
        /// </summary>
        public async Task<bool> UpdateImageOrderAsync(int imageId, int displayOrder)
        {
            try
            {
                _logger.LogInformation(
                    "Cập nhật DisplayOrder cho ImageId: {ImageId} -> {DisplayOrder}",
                    imageId, displayOrder);

                var image = await _context.Set<EventImage>()
                    .FirstOrDefaultAsync(i => i.ImageID == imageId);

                if (image == null)
                {
                    _logger.LogWarning("Không tìm thấy ảnh với ImageId: {ImageId}", imageId);
                    return false;
                }

                image.DisplayOrder = displayOrder;
                //image.UpdatedDate = DateTime.UtcNow;

                await _context.SaveChangesAsync();

                _logger.LogInformation(
                    "Cập nhật DisplayOrder thành công cho ImageId: {ImageId}",
                    imageId);

                return true;
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật DisplayOrder cho ImageId: {ImageId}", imageId);
                throw;
            }
        }

        /// <summary>
        /// Cập nhật metadata của ảnh sự kiện (không thay file)
        /// - ImageType (Banner/Gallery/Thumbnail)
        /// - Caption
        /// </summary>
        public async Task<EventImagesDto?> UpdateImageMetaAsync(int imageId, string? imageType, string? caption)
        {
            try
            {
                if (!EventImageHelper.IsValidImageType(imageType))
                {
                    throw new InvalidOperationException("Loại ảnh không hợp lệ. Chỉ chấp nhận: Banner, Gallery, Thumbnail");
                }

                var image = await _context.Set<EventImage>()
                    .FirstOrDefaultAsync(i => i.ImageID == imageId);

                if (image == null)
                {
                    _logger.LogWarning("Không tìm thấy ảnh để cập nhật metadata: ImageId {ImageId}", imageId);
                    return null;
                }

                image.ImageType = string.IsNullOrWhiteSpace(imageType) ? null : imageType.Trim();
                image.Caption = string.IsNullOrWhiteSpace(caption) ? null : caption.Trim();

                await _context.SaveChangesAsync();

                return new EventImagesDto
                {
                    ImageId = image.ImageID,
                    EventId = image.EventID,
                    ImageUrl = BuildFullUrl(image.ImageUrl),
                    ImageType = image.ImageType,
                    Caption = image.Caption,
                    DisplayOrder = image.DisplayOrder,
                    CreatedDate = image.CreatedDate
                };
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Lỗi khi cập nhật metadata ảnh: ImageId {ImageId}", imageId);
                throw;
            }
        }

        private string BuildFullUrl(string? relativeUrl)
        {
            return _publicUrlBuilder.BuildAbsoluteUrl(relativeUrl) ?? string.Empty;
        }

    }
}
