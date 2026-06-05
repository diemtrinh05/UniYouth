using System.ComponentModel.DataAnnotations;
using UniYouth.Admin.Models.DTOs.EventTypes;

namespace UniYouth.Admin.Models.ViewModels.EventTypes
{
    public class EventTypesIndexViewModel
    {
        public List<EventTypeDto> Items { get; set; } = new();

        public CreateEventTypeForm Create { get; set; } = new();
    }

    public class CreateEventTypeForm
    {
        [Required]
        [MinLength(1)]
        [MaxLength(200)]
        [Display(Name = "Tên loại")]
        public string TypeName { get; set; } = string.Empty;

        [MaxLength(255)]
        [Display(Name = "Mô tả")]
        public string? Description { get; set; }
    }

    public class UpdateEventTypeForm
    {
        [Required]
        public int TypeId { get; set; }

        [Required]
        [MinLength(1)]
        [MaxLength(200)]
        [Display(Name = "Tên loại")]
        public string TypeName { get; set; } = string.Empty;

        [MaxLength(255)]
        [Display(Name = "Mô tả")]
        public string? Description { get; set; }
    }
}

