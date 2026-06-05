namespace UniYouth.Api.Shared.Exceptions
{
    public sealed class ConflictException : Exception
    {
        public ConflictException(string message) : base(message)
        {
        }
    }
}
