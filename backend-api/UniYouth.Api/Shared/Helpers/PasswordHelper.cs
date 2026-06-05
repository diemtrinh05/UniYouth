using BC = BCrypt.Net.BCrypt;
namespace UniYouth.Api.Shared.Helpers
{
    /// <summary>
    /// Lớp trợ giúp dùng để băm và kiểm tra mật khẩu bằng thuật toán BCrypt
    /// </summary>
    public static class PasswordHelper
    {
        /// <summary>
        /// Băm mật khẩu dạng văn bản thuần (plain text) bằng BCrypt
        /// </summary>
        /// <param name="password">Mật khẩu dạng văn bản thuần</param>
        /// <returns>Mật khẩu đã được băm</returns>
        /// <example>
        /// var hashedPassword = PasswordHelper.HashPassword("password123");
        /// Console.WriteLine(hashedPassword);
        /// // Kết quả ví dụ: $2a$11$lY3PSHe8JUtMx3DpuzBZI.xj2tN7j5/pp2fdlOolIvVNvMrYH9Nem
        /// </example>
        public static string HashPassword(string password)
        {
            return BC.HashPassword(password);
        }

        /// <summary>
        /// Kiểm tra mật khẩu dạng văn bản thuần với mật khẩu đã được băm bằng BCrypt
        /// </summary>
        /// <param name="password">Mật khẩu người dùng nhập</param>
        /// <param name="hash">Mật khẩu đã được băm lưu trong cơ sở dữ liệu</param>
        /// <returns>
        /// true nếu mật khẩu đúng,
        /// false nếu mật khẩu không khớp
        /// </returns>
        /// <example>
        /// var isValid = PasswordHelper.VerifyPassword("password123", hashedPassword);
        /// if (isValid)
        /// {
        ///     Console.WriteLine("Mật khẩu chính xác!");
        /// }
        /// </example>
        public static bool VerifyPassword(string password, string hash)
        {
            return BC.Verify(password, hash);
        }

        /// <summary>
        /// Sinh ra nhiều mật khẩu đã băm để phục vụ cho mục đích phát triển và kiểm thử
        /// </summary>
        /// <param name="passwords">Danh sách các mật khẩu cần băm</param>
        /// <returns>
        /// Dictionary ánh xạ giữa mật khẩu gốc và mật khẩu đã được băm
        /// </returns>
        public static Dictionary<string, string> GenerateTestPasswordHashes(params string[] passwords)
        {
            var result = new Dictionary<string, string>();
            foreach (var password in passwords)
            {
                result[password] = HashPassword(password);
            }
            return result;
        }
    }
}
