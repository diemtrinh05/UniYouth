using System.Text.Json.Serialization;

namespace UniYouth.Admin.Models.DTOs.Events.Requests
{
    public class CancelEventRequestDto
    {
        // swagger.json: CancelEventRequestDto.reason (nullable, maxLength=255)
        [JsonPropertyName("reason")]
        public string? Reason { get; set; }
    }
}

