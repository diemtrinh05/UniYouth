using System.ComponentModel.DataAnnotations;
using UniYouth.Api.Shared.Enums;

namespace UniYouth.Api.Contracts.DTOs.DeviceTokens
{
    public sealed class UnregisterDeviceTokenRequestDto
    {
        [Required]
        public DevicePlatform Platform { get; set; }

        [Required]
        [MaxLength(512)]
        public string Token { get; set; } = string.Empty;
    }
}

