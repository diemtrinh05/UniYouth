namespace UniYouth.Api.Shared.Idempotency
{
    public sealed class IdempotencyOptions
    {
        public string HeaderName { get; set; } = "Idempotency-Key";

        /// <summary>
        /// Thời gian giữ cache idempotency (giây). Mục tiêu chính là chống double tap.
        /// </summary>
        public int DefaultTtlSeconds { get; set; } = 60;
    }
}

