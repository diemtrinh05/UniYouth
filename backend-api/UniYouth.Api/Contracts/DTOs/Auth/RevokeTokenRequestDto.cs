using System.ComponentModel.DataAnnotations;

namespace UniYouth.Api.Contracts.DTOs.Auth;

public class RevokeTokenRequestDto
{
    [Required]
    [MinLength(20)]
    public string RefreshToken { get; set; } = string.Empty;
}
