using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using UniYouth.Api.Application.Services;
using UniYouth.Api.Contracts.DTOs.Common;
using UniYouth.Api.Contracts.DTOs.Events;

namespace UniYouth.Api.Controllers
{
    /// <summary>
    /// Controller quản lý hình ảnh của sự kiện
    /// Thực hiện upload, lấy danh sách và xoá ảnh sự kiện
    /// </summary>
    [ApiController]
    [Route("api/events")]
    [Produces("application/json")]
    public class EventImagesController : ControllerBase
    {
        private readonly IEventImageService _eventImageService;
        private readonly ILogger<EventImagesController> _logger;
        private readonly IWebHostEnvironment _environment;

        public EventImagesController(
            IEventImageService eventImageService,
            ILogger<EventImagesController> logger,
            IWebHostEnvironment environment)
        {
            _eventImageService = eventImageService;
            _logger = logger;
            _environment = environment;
        }

        /// <summary>
        /// Upload một hoặc nhiều ảnh cho sự kiện
        /// Chỉ Cán bộ và Admin được phép upload
        /// </summary>
        /// <param name="eventId">ID của sự kiện</param>
        /// <param name="files">Danh sách file ảnh cần upload</param>
        /// <param name="imageType">Loại ảnh (Banner, Gallery, Thumbnail) - không bắt buộc</param>
        /// <param name="caption">Chú thích chung cho các ảnh - không bắt buộc</param>
        /// <returns>Danh sách ảnh upload thành công</returns>
        /// <response code="201">Upload ảnh thành công</response>
        /// <response code="400">File không hợp lệ</response>
        /// <response code="401">Chưa đăng nhập</response>
        /// <response code="403">Không có quyền (không phải Cán bộ hoặc Admin)</response>
        /// <response code="404">Không tìm thấy sự kiện</response>
        /// <remarks>
        /// Ví dụ request (multipart/form-data):
        /// 
        ///     POST /api/events/5/images
        ///     Authorization: Bearer {token}
        ///     
        ///     files: [file ảnh 1]
        ///     files: [file ảnh 2]
        ///     imageType: Gallery
        ///     caption: ảnh sự kiện tháng 12/2024
        /// 
        /// Yêu cầu file:
        /// - Định dạng: JPEG, PNG, WebP
        /// - Dung lượng tối đa mới file: 3 MB
        /// - Có thể upload nhiều file cùng lúc
        /// - Tên field file phải là "files"
        /// 
        /// LÝ DO TÁCH UPLOAD ẢNH KHỞI TẠO SỰ KIỆN:
        /// - Hiệu năng tốt hơn
        /// - Linh hoạt thêm / xoá ảnh
        /// - Trải nghiệm người dùng tốt hơn
        /// - Nếu upload lại thì dữ liệu sự kiện vẫn an toàn
        /// - Phù hợp cho mobile app
        /// </remarks>
        [HttpPost("{eventId}/images")]
        [Authorize(Roles = "CanBo,Admin")] // Only CanBo and Admin
        [Consumes("multipart/form-data")]
        [ProducesResponseType(typeof(ApiResponseDto<UploadEventImageResponseDto>), StatusCodes.Status201Created)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> UploadImages(
            int eventId,
            [FromForm] IFormFileCollection files,
            [FromForm] string? imageType = null,
            [FromForm] string? caption = null)
        {
            // Validate that files were provided
            if (files == null || files.Count == 0)
            {
                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Vui lòng chọn ít nhất một file ảnh"
                });
            }

            _logger.LogInformation(
                "Yêu cầu upload ảnh cho EventId: {EventId}, Số lượng: {Count}",
                eventId, files.Count);

            // Delegate to service layer
            var result = await _eventImageService.UploadImagesAsync(
                eventId,
                files,
                _environment.WebRootPath,
                imageType,
                caption);

            if (result.UploadedCount == 0)
            {
                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Không có ảnh nào được tải lên thành công. Vui lòng kiểm tra định dạng và kích thước file."
                });
            }

            return CreatedAtAction(
                nameof(GetEventImages),
                new { eventId },
                new ApiResponseDto<UploadEventImageResponseDto>
                {
                    Success = true,
                    Message = "Upload ảnh thành công",
                    Data = result
                });
        }

        /// <summary>
        /// Lấy danh sách ảnh của sự kiện
        /// Trả về theo thứ tự DisplayOrder
        /// </summary>
        /// <param name="eventId">Event ID</param>
        /// <returns>Danh sách hình ảnh sự kiện</returns>
        /// <response code="200">Trả về danh sách hình ảnh</response>
        /// <response code="401">Người dùng chưa được xác thực</response>
        /// <remarks>
        /// Sample request:
        /// 
        ///     GET /api/events/5/images
        ///     Authorization: Bearer {token}
        /// 
        /// Trả về hình ảnh theo thứ tự hiển thị.
        /// Hình ảnh có thể được hiển thị trong thư viện, biểu ngữ hoặc hình thu nhỏ dựa trên ImageType.
        /// </remarks>
        [HttpGet("{eventId}/images")]
        [Authorize] // All authenticated users can view images
        [ProducesResponseType(typeof(ApiResponseDto<List<EventImagesDto>>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        public async Task<IActionResult> GetEventImages(int eventId)
        {
            _logger.LogInformation("Lại lấy ảnh cho EventId: {EventId}", eventId);

            var images = await _eventImageService.GetEventImagesAsync(eventId);

            return Ok(new ApiResponseDto<List<EventImagesDto>>
            {
                Success = true,
                Message = "Lấy danh sách ảnh thành công",
                Data = images
            });
        }

        /// <summary>
        /// Xoá ảnh sự kiện
        /// Chỉ Cán bộ và Admin được phép thực hiện
        /// Loại bỏ cả bản ghi cơ sở dữ liệu và tệp tin vật lý
        /// </summary>
        /// <param name="imageId">Image ID to delete</param>
        /// <returns>Thông báo xác nhận</returns>
        /// <response code="200">Image dă xóa thành công</response>
        /// <response code="401">Người dùng không được xác thực</response>
        /// <response code="403">Người dùng không có quyền (không phải CanBo hoặc Admin)</response>
        /// <response code="404">Không tìm thấy hình ảnh</response>
        /// <remarks>
        /// Sample request:
        /// 
        ///     DELETE /api/events/images/123
        ///     Authorization: Bearer {token}
        /// 
        /// IMPORTANT SECURITY NOTES:
        /// - Xóa cả bản ghi cơ sở dữ liệu VÀ tệp vật lý
        /// - Tệp vật lý bị xóa vĩnh viễn khỏi máy chủ
        /// - Thao tác không thể hoàn tác
        /// - Chỉ CanBo và Admin mới có thể xóa hình ảnh
        /// </remarks>
        [HttpDelete("images/{imageId}")]
        [Authorize(Roles = "CanBo,Admin")] // Only CanBo and Admin
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status401Unauthorized)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status403Forbidden)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> DeleteImage(int imageId)
        {
            _logger.LogInformation("Xóa hình ảnh được yêu cầu: ImageId {ImageId}", imageId);

            var deleted = await _eventImageService.DeleteImageAsync(
                imageId,
                _environment.WebRootPath);

            if (!deleted)
            {
                return NotFound(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Không tìm thấy ảnh để xóa"
                });
            }

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Đã xóa ảnh thành công"
            });
        }

        /// <summary>
        /// Cập nhật thứ tự hiển thị của ảnh sự kiện
        /// Chỉ Cán bộ và Admin được phép thực hiện
        /// </summary>
        /// <param name="imageId">ID của ảnh</param>
        /// <param name="request">Thứ tự hiển thị mới</param>
        /// <returns>Kết quả cập nhật</returns>
        [HttpPut("images/{imageId}/order")]
        [Authorize(Roles = "CanBo,Admin")]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> UpdateImageOrder(
            int imageId,
            [FromBody] UpdateEventImageOrderDto request)
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = errors
                });
            }

            var updated = await _eventImageService
                .UpdateImageOrderAsync(imageId, request.DisplayOrder);

            if (!updated)
            {
                return NotFound(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Không tìm thấy ảnh để cập nhật"
                });
            }

            return Ok(new ApiResponseDto<object>
            {
                Success = true,
                Message = "Cập nhật thứ tự hiển thị ảnh thành công"
            });
        }

        /// <summary>
        /// Cập nhật thông tin (metadata) của ảnh sự kiện (không thay file)
        /// - ImageType
        /// - Caption
        /// </summary>
        [HttpPut("images/{imageId:int}")]
        [Authorize(Roles = "CanBo,Admin")]
        [ProducesResponseType(typeof(ApiResponseDto<EventImagesDto>), StatusCodes.Status200OK)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status400BadRequest)]
        [ProducesResponseType(typeof(ApiResponseDto<object>), StatusCodes.Status404NotFound)]
        public async Task<IActionResult> UpdateImageMeta(
            int imageId,
            [FromBody] UpdateEventImageRequestDto request)
        {
            if (!ModelState.IsValid)
            {
                var errors = ModelState
                    .Where(kvp => kvp.Value?.Errors.Count > 0)
                    .ToDictionary(
                        kvp => kvp.Key,
                        kvp => kvp.Value!.Errors.Select(e => e.ErrorMessage).ToArray());

                return BadRequest(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Dữ liệu không hợp lệ",
                    Errors = errors
                });
            }

            var updated = await _eventImageService.UpdateImageMetaAsync(
                imageId,
                request.ImageType,
                request.Caption);

            if (updated == null)
            {
                return NotFound(new ApiResponseDto<object>
                {
                    Success = false,
                    Message = "Không tìm thấy ảnh để cập nhật"
                });
            }

            return Ok(new ApiResponseDto<EventImagesDto>
            {
                Success = true,
                Message = "Cập nhật thông tin ảnh thành công",
                Data = updated
            });
        }

    }
}

