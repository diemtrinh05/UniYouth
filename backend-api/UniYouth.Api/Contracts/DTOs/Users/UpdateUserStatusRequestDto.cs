using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Users
{
    public class UpdateUserStatusRequestDto
    {
        [Range(0, 1, ErrorMessage = "Status chỉ hợp lệ 0 hoặc 1")]
        public int Status { get; set; }
    }
}

