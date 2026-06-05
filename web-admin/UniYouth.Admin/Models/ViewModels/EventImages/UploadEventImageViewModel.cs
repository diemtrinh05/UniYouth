using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.EventImages
{
    /// <summary>
    /// ViewModel cho việc upload hình ảnh sự kiện mới
    /// Xử lý upload file multipart/form-data thông qua IFormFile
    /// </summary>
    public class UploadEventImageViewModel
    {
        /// <summary>
        /// Các file cần upload - được bind từ multipart/form-data
        /// Model binding của ASP.NET Core tự động ánh xạ file inputs vào IFormFile
        /// </summary>
        [Required(ErrorMessage = "Vui lòng chọn ít nhất một file hình ảnh.")]
        [Display(Name = "File Hình ảnh")]
        public IFormFile[]? Files { get; set; }

        /// <summary>
        /// Loại hình ảnh đang được upload (Banner, Gallery, Thumbnail)
        /// Tất cả files trong một lần upload phải cùng loại theo API specification
        /// </summary>
        [Required(ErrorMessage = "Vui lòng chọn loại hình ảnh.")]
        [Display(Name = "Loại Hình ảnh")]
        public string ImageType { get; set; } = "Gallery";

        /// <summary>
        /// Chú thích tùy chọn cho các hình ảnh
        /// </summary>
        [Display(Name = "Chú thích (Tùy chọn)")]
        [StringLength(255, ErrorMessage = "Chú thích không được vượt quá 255 ký tự.")]
        public string? Caption { get; set; }

        /// <summary>
        /// Validation helper - kiểm tra xem có file nào được chọn không
        /// </summary>
        public bool HasFiles => Files != null && Files.Any();

        /// <summary>
        /// Lấy tổng kích thước của tất cả files theo bytes
        /// </summary>
        public long TotalFileSize => Files?.Sum(f => f.Length) ?? 0;

        /// <summary>
        /// Lấy tổng kích thước theo MB để hiển thị
        /// </summary>
        public double TotalFileSizeMB => TotalFileSize / (1024.0 * 1024.0);
    }
}
