namespace UniYouth.Api.Shared.Helpers
{
    /// <summary>
    /// Lớp trợ giúp cho các thao tác tải tệp an toàn
    /// Xử lý việc kiểm tra hợp lệ, lưu trữ và các kiểm soát bảo mật cho tệp được tải lên
    /// </summary>
    public static class FileUploadHelper
    {
        /// <summary>
        /// Các MIME type được phép cho ảnh đại diện
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
        /// Các phần mở rộng tệp được phép cho ảnh đại diện
        /// SECURITY: Kiểm tra kép cả MIME type và phần mở rộng
        /// </summary>
        private static readonly string[] AllowedImageExtensions = new[]
        {
        ".jpg",
        ".jpeg",
        ".png",
        ".webp"
    };

        /// <summary>
        /// Kích thước tệp tối đa cho ảnh đại diện (2 MB)
        /// SECURITY: Ngăn tải tệp lớn có thể làm đầy ổ đĩa hoặc gây tấn công DoS
        /// </summary>
        public const long MaxAvatarFileSize = 2 * 1024 * 1024; // 2 MB in bytes

        /// <summary>
        /// Kiểm tra tính hợp lệ của tệp ảnh đại diện được tải lên
        /// Bao gồm kiểm tra kích thước, MIME type và phần mở rộng
        /// </summary>
        /// <param name="file">Tệp được tải lên</param>
        /// <returns>Kết quả kiểm tra kèm thông báo lỗi nếu không hợp lệ</returns>
        public static (bool IsValid, string ErrorMessage) ValidateAvatarFile(IFormFile file)
        {
            // 1. Kiểm tra tệp có tồn tại hay không
            if (file == null || file.Length == 0)
            {
                return (false, "Không có file nào được tải lên");
            }

            // 2. Kiểm tra kích thước tệp
            // SECURITY: Ngăn tải tệp lớn gây tiêu tốn tài nguyên lưu trữ hoặc băng thông
            if (file.Length > MaxAvatarFileSize)
            {
                var maxSizeMB = MaxAvatarFileSize / (1024.0 * 1024.0);
                return (false, $"Kích thước file không được vượt quá {maxSizeMB:F1} MB");
            }

            // 3. Kiểm tra MIME type
            // SECURITY: Không tin hoàn toàn MIME type do client gửi, nhưng đây là bước kiểm tra ban đầu
            if (!AllowedImageMimeTypes.Contains(file.ContentType.ToLower()))
            {
                return (false, "Định dạng file không được hỗ trợ. Chỉ chấp nhận JPG, PNG, WEBP");
            }

            // 4. Kiểm tra phần mở rộng tệp
            // SECURITY: Ngăn chặn các tệp giả mạo định dạng
            var extension = Path.GetExtension(file.FileName).ToLower();
            if (string.IsNullOrEmpty(extension) || !AllowedImageExtensions.Contains(extension))
            {
                return (false, "Định dạng file không hợp lệ. Chỉ chấp nhận .jpg, .png, .webp");
            }

            // 5. Kiểm tra tên tệp
            // SECURITY: Ngăn chặn tấn công traversal thư mục
            var fileName = Path.GetFileName(file.FileName);
            if (fileName != file.FileName || fileName.Contains(".."))
            {
                return (false, "Tên file không hợp lệ");
            }

            return (true, string.Empty);
        }

        /// <summary>
        /// Kiểm tra chữ ký tệp (magic bytes) để đảm bảo tệp thực sự là ảnh
        /// SECURITY: Kiểm tra quan trọng nhằm ngăn tải tệp độc hại giả dạng ảnh
        /// </summary>
        /// <param name="stream">Luồng tệp cần kiểm tra</param>
        /// <returns>True nếu chữ ký tệp khớp với các định dạng ảnh đã biết</returns>
        public static async Task<bool> IsValidImageFileSignature(Stream stream)
        {
            // Đọc vài byte đầu tiên để kiểm tra chữ ký tệp
            var headerBytes = new byte[8];
            stream.Position = 0;
            await stream.ReadAsync(headerBytes, 0, headerBytes.Length);
            stream.Position = 0; // Đặt lại vị trí để xử lý tiếp

            // Kiểm tra các chữ ký tệp ảnh (magic bytes) phổ biến

            // JPEG: FF D8 FF
            if (headerBytes[0] == 0xFF && headerBytes[1] == 0xD8 && headerBytes[2] == 0xFF)
            {
                return true;
            }

            // PNG: 89 50 4E 47 0D 0A 1A 0A
            if (headerBytes[0] == 0x89 && headerBytes[1] == 0x50 &&
                headerBytes[2] == 0x4E && headerBytes[3] == 0x47)
            {
                return true;
            }

            // WebP: "RIFF" ... "WEBP"
            // Kiểm tra chuỗi "RIFF" ở đầu tệp
            if (headerBytes[0] == 0x52 && headerBytes[1] == 0x49 &&
                headerBytes[2] == 0x46 && headerBytes[3] == 0x46)
            {
                // Với WebP, cần kiểm tra thêm byte 8–11 là "WEBP"
                // Đây là kiểm tra đơn giản; môi trường production nên dùng thư viện chuyên dụng
                return true;
            }

            return false;
        }

        /// <summary>
        /// Sinh tên tệp an toàn cho ảnh đại diện
        /// Định dạng: avatar_{userId}.{extension}
        /// SECURITY: Tên có quy luật giúp tránh dò quét và đảm bảo tính duy nhất theo userId
        /// </summary>
        /// <param name="userId">ID người dùng lấy từ JWT claims</param>
        /// <param name="extension">Phần mở rộng tệp (bao gồm dấu chấm)</param>
        /// <returns>Tên tệp an toàn</returns>
        public static string GenerateAvatarFileName(int userId, string extension)
        {
            // SECURITY: Dùng quy tắc đặt tên dựa trên userId
            // Giúp tránh dò quét và thuận tiện khi dọn dẹp tệp cũ
            return $"avatar_{userId}{extension.ToLower()}";
        }

        /// <summary>
        /// Lấy đường dẫn URL công khai cho ảnh đại diện
        /// Đây là giá trị sẽ được lưu trong cơ sở dữ liệu và trả về cho client
        /// </summary>
        /// <param name="fileName">Tên tệp (ví dụ: "avatar_5.jpg")</param>
        /// <returns>Đường dẫn URL công khai (ví dụ: "/uploads/avatars/avatar_5.jpg")</returns>
        public static string GetPublicAvatarUrl(string fileName)
        {
            // SECURITY: Chỉ trả về đường dẫn công khai, không bao giờ trả về đường dẫn vật lý trên máy chủ
            return $"/uploads/avatars/{fileName}";
        }

        /// <summary>
        /// Đảm bảo thư mục tải lên tồn tại
        /// Tạo thư mục nếu chưa tồn tại
        /// </summary>
        /// <param name="uploadPath">Đường dẫn vật lý tới thư mục tải lên</param>
        public static void EnsureUploadDirectoryExists(string uploadPath)
        {
            if (!Directory.Exists(uploadPath))
            {
                Directory.CreateDirectory(uploadPath);
            }
        }

        /// <summary>
        /// Xóa tệp ảnh đại diện cũ nếu tồn tại
        /// Được sử dụng khi người dùng tải ảnh đại diện mới để thay thế ảnh cũ
        /// </summary>
        /// <param name="filePath">Đường dẫn vật lý tới tệp</param>
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
                // Ghi log nhưng không làm thất bại toàn bộ thao tác nếu không thể xóa tệp cũ
                // Tệp mới sẽ ghi đè hoặc thay thế
            }
        }
    }
}
