namespace UniYouth.Admin.Models.DTOs.AdminUsers
{
    public class UpdateAdminUserRequestDto
    {
        // swagger_v2.json: required, minLength=2, maxLength=100
        public string FullName { get; set; } = string.Empty;

        // swagger_v2.json: required, format=email, maxLength=100
        public string Email { get; set; } = string.Empty;

        // optional, maxLength=20
        public string? Phone { get; set; }

        // optional: true=Nam, false=Nữ
        public bool? Gender { get; set; }

        // optional (date)
        public DateOnly? DateOfBirth { get; set; }

        // optional, maxLength=255
        public string? Address { get; set; }

        // optional
        public int? PositionId { get; set; }

        // optional (date)
        public DateOnly? JoinDate { get; set; }
    }
}
