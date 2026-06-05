namespace UniYouth.Api.Shared.Idempotency
{
    internal sealed record IdempotencyRecord(int StatusCode, object? Body);
}

