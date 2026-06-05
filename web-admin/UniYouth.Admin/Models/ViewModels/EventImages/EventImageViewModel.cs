using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.EventImages
{
    /// <summary>
    /// ViewModel để hiển thị một hình ảnh sự kiện đơn lẻ
    /// Sử dụng trong view dạng grid/danh sách
    /// </summary>
    public class EventImageViewModel
    {
        public int ImageId { get; set; }

        [Display(Name = "URL Hình ảnh")]
        public string ImageUrl { get; set; } = string.Empty;

        [Display(Name = "Loại Hình ảnh")]
        public string ImageType { get; set; } = "Gallery";

        [Display(Name = "Chú thích")]
        public string? Caption { get; set; }

        [Display(Name = "Thứ tự Hiển thị")]
        public int DisplayOrder { get; set; }

        /// <summary>
        /// Thuộc tính helper để hiển thị badge cho loại hình ảnh
        /// </summary>
        public string ImageTypeBadgeClass => ImageType switch
        {
            "Banner" => "bg-primary",
            "Thumbnail" => "bg-success",
            "Gallery" => "bg-info",
            _ => "bg-secondary"
        };
    }
}
