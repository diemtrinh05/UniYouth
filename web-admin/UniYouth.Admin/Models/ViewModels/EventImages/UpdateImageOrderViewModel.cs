using System.ComponentModel.DataAnnotations;

namespace UniYouth.Admin.Models.ViewModels.EventImages
{
    public class UpdateImageOrderViewModel
    {
        [Required]
        public int ImageId { get; set; }

        [Required]
        [Range(1, 1000, ErrorMessage = "Thứ tự hiển thị phải từ 1 đến 1000")]
        public int DisplayOrder { get; set; }
    }
}
