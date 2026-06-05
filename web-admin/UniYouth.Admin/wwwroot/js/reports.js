(function () {
    'use strict';

    function dismissNonInfoAlerts() {
        if (!window.bootstrap?.Alert) return;

        var alerts = document.querySelectorAll('.alert:not(.alert-info)');
        alerts.forEach(function (alert) {
            var bsAlert = new window.bootstrap.Alert(alert);
            bsAlert.close();
        });
    }

    function initPrintButtons() {
        document.querySelectorAll('[data-report-print]').forEach(function (button) {
            button.addEventListener('click', function () {
                window.print();
            });
        });
    }

    document.addEventListener('DOMContentLoaded', function () {
        initPrintButtons();
        window.setTimeout(dismissNonInfoAlerts, 5000);
    });
})();
