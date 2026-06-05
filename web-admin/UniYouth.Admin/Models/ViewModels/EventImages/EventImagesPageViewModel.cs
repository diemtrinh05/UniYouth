using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.EventImages
{
    /// <summary>
    /// ViewModel chính cho trang Index chứa tất cả hình ảnh và metadata
    /// </summary>
    public class EventImagesPageViewModel
    {
        public int EventId { get; set; }

        [Display(Name = "Tên Sự kiện")]
        public string EventName { get; set; } = string.Empty;

        [Display(Name = "Hình ảnh Sự kiện")]
        public List<EventImageViewModel> Images { get; set; } = new();

        /// <summary>
        /// Các loại hình ảnh có sẵn cho dropdown (từ API spec)
        /// </summary>
        public string[] AvailableImageTypes { get; set; } = Array.Empty<string>();

        /// <summary>
        /// Các thuộc tính helper cho hiển thị UI
        /// </summary>
        public int TotalImages => Images.Count;
        public bool HasImages => Images.Any();
        public int BannerCount => Images.Count(i => i.ImageType == "Banner");
        public int GalleryCount => Images.Count(i => i.ImageType == "Gallery");
        public int ThumbnailCount => Images.Count(i => i.ImageType == "Thumbnail");
    }
}
