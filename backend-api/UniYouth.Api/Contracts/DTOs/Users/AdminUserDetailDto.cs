namespace UniYouth.Api.Contracts.DTOs.Users
{
    public class AdminUserDetailDto
    {
        public int UserId { get; set; }
        public string Code { get; set; } = string.Empty;
        public string FullName { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string? Phone { get; set; }
        public string? AvatarUrl { get; set; }
        public bool? Gender { get; set; }
        public DateOnly? DateOfBirth { get; set; }
        public string? Address { get; set; }
        public byte? Status { get; set; }
        public List<string> Roles { get; set; } = new();

        public int? UnitId { get; set; }
        public string? UnitName { get; set; }
        public int? InstituteId { get; set; }
        public string? InstituteName { get; set; }
        public DateOnly? JoinDate { get; set; }
        public int? PositionId { get; set; }
        public string? Position { get; set; }

        public DateTime? LastLoginDate { get; set; }
        public DateTime? CreatedDate { get; set; }
        public DateTime? UpdatedDate { get; set; }
    }
}

