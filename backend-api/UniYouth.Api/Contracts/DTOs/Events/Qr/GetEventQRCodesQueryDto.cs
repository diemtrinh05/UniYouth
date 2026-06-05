namespace UniYouth.Api.Contracts.DTOs.Events.Qr
{
    public sealed class GetEventQRCodesQueryDto
    {
        public int PageNumber { get; set; } = 1;
        public int PageSize { get; set; } = 20;

        public bool? IsActive { get; set; }

        /// <summary>
        /// true  : QR đang trong khoảng thời gian hiệu lực (ValidFrom <= now <= ValidUntil)
        /// false : QR ngoài khoảng thời gian hiệu lực
        /// null  : không lọc
        /// </summary>
        public bool? ValidNow { get; set; }
    }
}

