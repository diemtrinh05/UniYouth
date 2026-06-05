(function () {
    function isFormValid(form) {
        if (typeof window.jQuery === 'undefined') return true;

        var validator = window.jQuery(form);
        return typeof validator.valid !== 'function' || validator.valid();
    }

    function bindSubmitState(formId, buttonId, readOnlyInputIds) {
        var form = document.getElementById(formId);
        var submitButton = document.getElementById(buttonId);

        if (!form || !submitButton) return;

        var defaultLabel = submitButton.querySelector('.default-label');
        var loadingLabel = submitButton.querySelector('.loading-label');

        form.addEventListener('submit', function () {
            if (submitButton.disabled || form.dataset.submitting === 'true') return;
            if (!isFormValid(form)) return;

            form.dataset.submitting = 'true';
            submitButton.disabled = true;

            readOnlyInputIds.forEach(function (inputId) {
                var input = document.getElementById(inputId);
                if (input) input.readOnly = true;
            });

            if (defaultLabel) defaultLabel.classList.add('d-none');
            if (loadingLabel) loadingLabel.classList.remove('d-none');
        });
    }

    function formatDuration(totalSeconds) {
        var safeSeconds = Math.max(0, totalSeconds);
        var minutes = String(Math.floor(safeSeconds / 60)).padStart(2, '0');
        var seconds = String(safeSeconds % 60).padStart(2, '0');
        return minutes + ':' + seconds;
    }

    function bindOtpInput() {
        var otpInput = document.getElementById('otpCodeInput');
        if (!otpInput) return;

        otpInput.addEventListener('input', function () {
            this.value = this.value.replace(/\D/g, '').slice(0, 6);
        });
    }

    function applyExpiredState() {
        var otpInput = document.getElementById('otpCodeInput');
        var verifyButton = document.getElementById('verifyOtpButton');
        var resendButton = document.getElementById('resendOtpButton');
        var resendCooldownHint = document.getElementById('resendCooldownHint');
        var expiredAlert = document.getElementById('otpExpiredAlert');

        if (otpInput) otpInput.disabled = true;
        if (verifyButton) verifyButton.disabled = true;
        if (resendButton) resendButton.disabled = false;
        if (resendCooldownHint) resendCooldownHint.hidden = true;
        if (expiredAlert) expiredAlert.classList.remove('d-none');
    }

    function bindResendCooldown(resendAvailableAt) {
        var resendButton = document.getElementById('resendOtpButton');
        var resendCooldownHint = document.getElementById('resendCooldownHint');
        var resendCooldownElement = document.getElementById('resendCooldown');

        if (!resendAvailableAt || !resendButton || !resendCooldownHint || !resendCooldownElement) return;

        function updateResendCooldown() {
            var remainingMs = new Date(resendAvailableAt).getTime() - Date.now();
            if (remainingMs <= 0) {
                resendButton.disabled = false;
                resendCooldownHint.hidden = true;
                return false;
            }

            resendButton.disabled = true;
            resendCooldownHint.hidden = false;
            resendCooldownElement.textContent = formatDuration(Math.ceil(remainingMs / 1000));
            return true;
        }

        if (updateResendCooldown()) {
            var resendTimerId = window.setInterval(function () {
                if (!updateResendCooldown()) window.clearInterval(resendTimerId);
            }, 1000);
        }
    }

    function bindOtpExpiry(expiresAt) {
        var countdownElement = document.getElementById('otpCountdown');
        var countdownContainer = document.getElementById('otpCountdownContainer');

        if (!expiresAt || !countdownElement || !countdownContainer) return;

        function updateCountdown() {
            var remainingMs = new Date(expiresAt).getTime() - Date.now();
            if (remainingMs <= 0) {
                countdownElement.textContent = '00:00';
                applyExpiredState();
                return false;
            }

            countdownElement.textContent = formatDuration(Math.floor(remainingMs / 1000));
            return true;
        }

        if (!updateCountdown()) return;

        var timerId = window.setInterval(function () {
            if (!updateCountdown()) window.clearInterval(timerId);
        }, 1000);
    }

    function dismissTransientAlerts() {
        if (typeof window.bootstrap === 'undefined') return;

        document.querySelectorAll('.alert-dismissible:not(.alert-permanent)').forEach(function (alert) {
            window.setTimeout(function () {
                window.bootstrap.Alert.getOrCreateInstance(alert).close();
            }, 5000);
        });
    }

    document.addEventListener('DOMContentLoaded', function () {
        var script = document.querySelector('script[data-auth-recovery]');

        bindSubmitState('forgotPasswordForm', 'forgotPasswordSubmitButton', ['forgotPasswordAccount']);
        bindSubmitState('resetPasswordForm', 'resetPasswordSubmitButton', ['newPasswordInput', 'confirmPasswordInput']);
        bindSubmitState('verifyResetOtpForm', 'verifyOtpButton', ['otpCodeInput']);
        bindOtpInput();
        bindResendCooldown(script?.getAttribute('data-resend-available-at') || '');
        bindOtpExpiry(script?.getAttribute('data-otp-expires-at') || '');
        dismissTransientAlerts();
    });
})();
