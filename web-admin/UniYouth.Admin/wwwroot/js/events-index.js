(function () {
    'use strict';

    function getIndexUrl() {
        var script = document.currentScript || document.querySelector('script[data-events-index-url]');
        return script?.getAttribute('data-events-index-url') || window.location.pathname;
    }

    var indexUrl = getIndexUrl();

    function resetFilters() {
        window.location.href = indexUrl;
    }

    function initResetButtons() {
        document.querySelectorAll('[data-events-reset-filters]').forEach(function (button) {
            button.addEventListener('click', resetFilters);
        });
    }

    function initAutoSubmitControls() {
        document.querySelectorAll('[data-auto-submit]').forEach(function (control) {
            control.addEventListener('change', function () {
                if (control.form) {
                    control.form.submit();
                }
            });
        });
    }

    function initCancelModal() {
        var modalEl = document.getElementById('cancelEventModal');
        if (!modalEl) return;

        modalEl.addEventListener('show.bs.modal', function (event) {
            var button = event.relatedTarget;
            if (!button) return;

            var eventId = button.getAttribute('data-event-id');
            var eventName = button.getAttribute('data-event-name');

            var idInput = document.getElementById('cancelEventId');
            var nameEl = document.getElementById('cancelEventName');
            var reasonEl = document.getElementById('cancelReason');

            if (idInput) idInput.value = eventId || '';
            if (nameEl) nameEl.textContent = eventName || '';
            if (reasonEl) reasonEl.value = '';
        });
    }

    document.addEventListener('DOMContentLoaded', function () {
        initAutoSubmitControls();
        initResetButtons();
        initCancelModal();
    });

    window.resetFilters = resetFilters;
})();
