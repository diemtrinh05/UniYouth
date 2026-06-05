namespace UniYouth.Api.Shared.Helpers
{
    /// <summary>
    /// Lớp helper hỗ trợ xử lý file ảnh sự kiện
    /// Thực hiện kiểm tra, đặt tên và lưu trữ ảnh
    /// </summary>
    public static class EventImageHelper
    {
        /// <summary>
        /// Danh sách MIME type được phép cho ảnh sự kiện
        /// SECURITY: Chỉ cho phép các định dạng ảnh an toàn
        /// </summary>
        private static readonly string[] AllowedImageMimeTypes = new[]
        {
        "image/jpeg",
        "image/jpg",
        "image/png",
        "image/webp"
    };

        /// <summary>
        /// Danh sách phần mở rộng file được phép
        /// SECURITY: Kiểm tra song song cả MIME type và extension
        /// </summary>
        private static readonly string[] AllowedImageExtensions = new[]
        {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    };

        /// <summary>
        /// Kích thước file tối đa cho ảnh sự kiện (3 MB)
        /// SECURITY: Ngăn upload file dung lượng lớn
        /// </summary>
        public const long MaxEventImageSize = 3 * 1024 * 1024; // 3 MB

        /// <summary>
        /// Các loại ảnh hợp lệ
        /// </summary>
        private static readonly string[] ValidImageTypes = new[]
        {
        "Banner",
        "Gallery",
        "Thumbnail"
    };

        /// <summary>
        /// Kiểm tra tính hợp lệ của file ảnh upload
        /// </summary>
        public static (bool IsValid, string ErrorMessage) ValidateEventImage(IFormFile file)
        {
            if (file == null || file.Length == 0)
            {
                return (false, "File không hợp lệ");
            }

            // Kiểm tra dung lượng file
            if (file.Length > MaxEventImageSize)
            {
                var maxSizeMB = MaxEventImageSize / (1024.0 * 1024.0);
                return (false, $"Kích thước file không được vượt quá {maxSizeMB:F1} MB");
            }

            // Kiểm tra MIME type
            if (!AllowedImageMimeTypes.Contains(file.ContentType.ToLower()))
            {
                return (false, "Định dạng file không được hỗ trợ. Chỉ chấp nhận JPG, PNG, WEBP");
            }

            // Kiểm tra phần mở rộng
            var extension = Path.GetExtension(file.FileName).ToLower();
            if (string.IsNullOrEmpty(extension) || !AllowedImageExtensions.Contains(extension))
            {
                return (false, "Định dạng file không hợp lệ");
            }

            // Kiểm tra tên file (chống directory traversal)
            var fileName = Path.GetFileName(file.FileName);
            if (fileName != file.FileName || fileName.Contains(".."))
            {
                return (false, "Tên file không hợp lệ");
            }

            return (true, string.Empty);
        }

        /// <summary>
        /// Kiểm tra chữ ký file để đảm bảo đúng là ảnh
        /// SECURITY: Bước quan trọng để ngăn upload file độc hại
        /// </summary>
        public static async Task<bool> IsValidImageFileSignature(Stream stream)
        {
            var headerBytes = new byte[8];
            stream.Position = 0;
            await stream.ReadAsync(headerBytes, 0, headerBytes.Length);
            stream.Position = 0;

            // JPEG: FF D8 FF
            if (headerBytes[0] == 0xFF && headerBytes[1] == 0xD8 && headerBytes[2] == 0xFF)
                return true;

            // PNG: 89 50 4E 47
            if (headerBytes[0] == 0x89 && headerBytes[1] == 0x50 &&
                headerBytes[2] == 0x4E && headerBytes[3] == 0x47)
                return true;

            // WebP: RIFF
            if (headerBytes[0] == 0x52 && headerBytes[1] == 0x49 &&
                headerBytes[2] == 0x46 && headerBytes[3] == 0x46)
                return true;

            return false;
        }

        /// <summary>
        /// Sinh tên file ảnh duy nhất cho sự kiện
        /// Định dạng: event_{eventId}_{guid}.{extension}
        /// SECURITY: Dùng GUID để tránh trùng tên và dò file
        /// </summary>
        public static string GenerateEventImageFileName(int eventId, string extension)
        {
            var guid = Guid.NewGuid().ToString("N"); // Chuỗi hex 32 ký tự
            return $"event_{eventId}_{guid}{extension.ToLower()}";
        }

        /// <summary>
        /// Lấy đường dẫn thư mục lưu ảnh sự kiện
        /// Format: wwwroot/uploads/events/{eventId}/
        /// </summary>
        public static string GetEventImageDirectory(string webRootPath, int eventId)
        {
            return Path.Combine(webRootPath, "uploads", "events", eventId.ToString());
        }

        /// <summary>
        /// Lấy URL public của ảnh sự kiện
        /// Đường dẫn này sẽ lưu trong DB và trả cho client
        /// </summary>
        public static string GetPublicImageUrl(int eventId, string fileName)
        {
            // SECURITY: Chỉ trả về đường dẫn public, không trả đường dẫn vật lý
            return $"/uploads/events/{eventId}/{fileName}";
        }

        /// <summary>
        /// Đảm bảo thư mục upload tồn tại
        /// </summary>
        public static void EnsureDirectoryExists(string directoryPath)
        {
            if (!Directory.Exists(directoryPath))
            {
                Directory.CreateDirectory(directoryPath);
            }
        }

        /// <summary>
        /// Kiểm tra loại ảnh có hợp lệ không
        /// </summary>
        public static bool IsValidImageType(string? imageType)
        {
            if (string.IsNullOrEmpty(imageType))
                return true; // Optional field

            return ValidImageTypes.Contains(imageType, StringComparer.OrdinalIgnoreCase);
        }

        /// <summary>
        /// Xóa file vật lý nếu tồn tại
        /// </summary>
        public static void DeleteFileIfExists(string filePath)
        {
            try
            {
                if (File.Exists(filePath))
                {
                    File.Delete(filePath);
                }
            }
            catch (Exception)
            {
                // Không throw lỗi nếu xóa file thất bại
            }
        }
    }
}
