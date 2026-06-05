namespace UniYouth.Admin.Services.Common
{
    /// <summary>
    /// Generic result wrapper cho API calls
    /// </summary>
    public class ApiResult<T>
    {
        public bool Success { get; set; }
        public T? Data { get; set; }
        public object? Summary { get; set; }
        public string? Message { get; set; }
        public string? ErrorMessage { get; set; }
        public Dictionary<string, string[]?>? Errors { get; set; }

        public static ApiResult<T> SuccessResult(
            T data,
            string message = "",
            Dictionary<string, string[]?>? errors = null)
        {
            return new ApiResult<T>
            {
                Success = true,
                Message = message,
                ErrorMessage = message,
                Data = data,
                Errors = errors
            };
        }

        public static ApiResult<T> FailureResult(
            string message,
            Dictionary<string, string[]?>? errors = null,
            string? displayMessage = null)
        {
            return new ApiResult<T>
            {
                Success = false,
                Message = message,
                ErrorMessage = displayMessage ?? message,
                Data = default,
                Errors = errors
            };
        }
    }
}
