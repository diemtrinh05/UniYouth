namespace UniYouth.Api.Shared.Helpers
{
    public static class PasswordStrengthValidator
    {
        public static (bool IsValid, string ErrorMessage) Validate(string password)
        {
            if (string.IsNullOrWhiteSpace(password))
            {
                return (false, "Mật khẩu là bắt buộc");
            }

            if (password.Length < 8)
            {
                return (false, "Mật khẩu phải có ít nhất 8 ký tự");
            }

            if (!password.Any(char.IsUpper))
            {
                return (false, "Mật khẩu phải chứa ít nhất một chữ cái viết hoa");
            }

            if (!password.Any(char.IsLower))
            {
                return (false, "Mật khẩu phải chứa ít nhất một chữ cái viết thường");
            }

            if (!password.Any(char.IsDigit))
            {
                return (false, "Mật khẩu phải chứa ít nhất một chữ số");
            }

            var specialCharacters = "!@#$%^&*()_+-=[]{}|;:,.<>?";
            if (!password.Any(c => specialCharacters.Contains(c)))
            {
                return (false, "Mật khẩu phải chứa ít nhất một ký tự đặc biệt (!@#$%^&*...)");
            }

            return (true, string.Empty);
        }
    }
}
