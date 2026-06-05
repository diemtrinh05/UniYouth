namespace UniYouth.Admin.Models.DTOs.Users
{
    /// <summary>
    /// Thông tin user từ API
    /// </summary>
    public class UserInfoDto
    {
        public int UserId { get; set; }
        public string Email { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Code { get; set; } = string.Empty;
        public string? AvatarUrl { get; set; }
        public List<string> Roles { get; set; } = new();
        public UnitInfoDto? Unit { get; set; }
    }
}

