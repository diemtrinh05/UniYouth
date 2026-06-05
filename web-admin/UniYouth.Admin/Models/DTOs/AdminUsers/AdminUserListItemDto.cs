namespace UniYouth.Admin.Models.DTOs.AdminUsers
{
    public class AdminUserListItemDto
    {
        public int UserId { get; set; }
        public string? Code { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public int? Status { get; set; }
        public List<string>? Roles { get; set; }
        public int? UnitId { get; set; }
        public string? UnitName { get; set; }
        public int? InstituteId { get; set; }
        public string? InstituteName { get; set; }
        public DateTime? LastLoginDate { get; set; }
        public DateTime? CreatedDate { get; set; }
    }
}


