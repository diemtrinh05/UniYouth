namespace UniYouth.Admin.Models.DTOs.Events.Common
{
    public class EventTypeInfoDto
    {
        public int TypeId { get; set; }
        public string TypeName { get; set; } = string.Empty;
        public string? Description { get; set; }
    }
}
