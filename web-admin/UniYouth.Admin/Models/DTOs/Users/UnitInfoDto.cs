namespace UniYouth.Admin.Models.DTOs.Users
{
    /// <summary>
    /// Thông tin đơn vị của user
    /// </summary>
    public class UnitInfoDto
    {
        public int UnitId { get; set; }
        public string UnitName { get; set; } = string.Empty;
        public string? UnitType { get; set; }
        public string? Position { get; set; }
    }
}
