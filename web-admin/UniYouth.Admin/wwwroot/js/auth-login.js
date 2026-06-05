(function ($) {
    if (!$) return;

    $(document).ready(function () {
        var validationSummary = $('.validation-summary-errors, .validation-summary-valid');
        if (validationSummary.find('ul li').length > 0) {
            validationSummary.closest('.alert').show();
        }

        if (typeof window.bootstrap !== 'undefined') {
            document.querySelectorAll('.alert:not(.alert-permanent)').forEach(function (alert) {
                window.setTimeout(function () {
                    window.bootstrap.Alert.getOrCreateInstance(alert).close();
                }, 5000);
            });
        }

        $('#togglePassword').on('click', function () {
            var passwordInput = $('#passwordInput');
            var toggleIcon = $('#toggleIcon');

            if (passwordInput.attr('type') === 'password') {
                passwordInput.attr('type', 'text');
                toggleIcon.removeClass('bi-eye').addClass('bi-eye-slash');
            } else {
                passwordInput.attr('type', 'password');
                toggleIcon.removeClass('bi-eye-slash').addClass('bi-eye');
            }
        });

        var firstError = $('.input-validation-error:first');
        if (firstError.length) {
            firstError.focus();
        }

        var isSubmitting = false;

        $('#loginForm').on('submit', function () {
            if (isSubmitting) return false;
            if (!$(this).valid()) return false;

            isSubmitting = true;
            $('#submitBtn')
                .prop('disabled', true)
                .html('<span class="spinner"></span>Đang xác thực...');
        });

        if ($('.text-danger:visible').length > 0) {
            $('.login-card').css('animation', 'shake 0.5s');
        }
    });
})(window.jQuery);
