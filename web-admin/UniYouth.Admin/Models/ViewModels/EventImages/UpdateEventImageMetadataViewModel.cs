using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.EventImages
{
    public class UpdateEventImageMetadataViewModel
    {
        [Required]
        public int ImageId { get; set; }

        [Required(ErrorMessage = "Vui lòng nhập thứ tự hiển thị.")]
        [Range(1, 1000, ErrorMessage = "Thứ tự hiển thị phải từ 1 đến 1000")]
        public int DisplayOrder { get; set; }

        [Required(ErrorMessage = "Vui lòng chọn loại hình ảnh.")]
        [StringLength(50, ErrorMessage = "Loại hình ảnh không được vượt quá 50 ký tự.")]
        public string ImageType { get; set; } = "Gallery";

        [StringLength(255, ErrorMessage = "Chú thích không được vượt quá 255 ký tự.")]
        public string? Caption { get; set; }
    }
}
