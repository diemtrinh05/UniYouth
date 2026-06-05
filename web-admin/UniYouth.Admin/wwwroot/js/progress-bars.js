(function () {
    function toPercent(value) {
        var parsed = Number.parseFloat(String(value || '').replace(',', '.'));
        if (!Number.isFinite(parsed)) return 0;
        return Math.min(100, Math.max(0, parsed));
    }

    function applyProgressWidths() {
        document.querySelectorAll('[data-progress-width]').forEach(function (bar) {
            bar.style.width = toPercent(bar.getAttribute('data-progress-width')) + '%';
        });
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', applyProgressWidths);
    } else {
        applyProgressWidths();
    }
})();
