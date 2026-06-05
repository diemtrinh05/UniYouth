using Microsoft.AspNetCore.Mvc;

namespace UniYouth.Api.Shared.Idempotency
{
    [AttributeUsage(AttributeTargets.Method)]
    public sealed class IdempotencyAttribute : TypeFilterAttribute
    {
        public IdempotencyAttribute() : this(0)
        {
        }

        /// <param name="ttlSeconds">
        /// Thời gian giữ cache cho idempotency key (giây). Truyền 0 để dùng default từ options.
        /// </param>
        public IdempotencyAttribute(int ttlSeconds) : base(typeof(IdempotencyFilter))
        {
            // IMPORTANT:
            // TypeFilterAttribute sẽ gọi GetType() cho từng argument để map ctor parameter.
            // Nếu truyền null sẽ gây NullReferenceException (đã xảy ra khi ttlSeconds = 0).
            // => Chỉ set Arguments khi có override thực sự.
            if (ttlSeconds > 0)
            {
                Arguments = new object[] { ttlSeconds };
            }
        }
    }
}
