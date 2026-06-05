namespace UniYouth.Admin.Models.DTOs.Users
{
    public class UserProfileDto
    {
        public int UserId { get; set; }
        public string? Code { get; set; }
        public string? FullName { get; set; }
        public string? Email { get; set; }
        public string? Phone { get; set; }
        public string? AvatarUrl { get; set; }
        public bool? Gender { get; set; }
        public DateTime? DateOfBirth { get; set; }
        public string? Address { get; set; }
        public string? Role { get; set; }

        public string? UnitName { get; set; }
        public int? UnitId { get; set; }
        public int? PositionId { get; set; }

        public DateTime? JoinDate { get; set; }
        public string? Position { get; set; }

        public string? InstituteName { get; set; }
        public int? InstituteId { get; set; }
        public int? Status { get; set; }
        public DateTime? LastLoginDate { get; set; }
        public DateTime? CreatedDate { get; set; }
    }
}

