using System.ComponentModel.DataAnnotations;
using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Contracts.DTOs.DeviceTokens
{
    public sealed class RegisterDeviceTokenRequestDto
    {
        [Required]
        public DevicePlatform Platform { get; set; }

        [Required]
        [MaxLength(512)]
        public string Token { get; set; } = string.Empty;

        [MaxLength(100)]
        public string? DeviceId { get; set; }
    }
}

