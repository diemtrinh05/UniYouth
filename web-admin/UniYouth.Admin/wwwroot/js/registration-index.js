(function () {
    'use strict';

    function normalizeText(value) {
        return (value || '')
            .toString()
            .toLowerCase()
            .normalize('NFD')
            .replace(/[\u0300-\u036f]/g, '')
            .trim();
    }

    function applyClientSearch() {
        var input = document.getElementById('q');
        var table = document.getElementById('registrationsTable');
        if (!input || !table) return;

        var query = normalizeText(input.value);
        var rows = table.querySelectorAll('tbody tr');

        rows.forEach(function (row) {
            var text = normalizeText(row.innerText);
            var match = query.length === 0 || text.includes(query);
            row.style.display = match ? '' : 'none';
        });
    }

    function getExportFileName() {
        var script = document.currentScript || document.querySelector('script[data-registration-export-file-name]');
        return script?.getAttribute('data-registration-export-file-name') || 'DanhSachDangKy.csv';
    }

    var exportFileName = getExportFileName();

    function exportToExcel() {
        var table = document.getElementById('registrationsTable');
        if (!table) return;

        var csv = [];
        var rows = table.querySelectorAll('tr');

        rows.forEach(function (row) {
            var cols = row.querySelectorAll('td, th');
            var csvRow = [];

            cols.forEach(function (col) {
                csvRow.push('"' + col.innerText.replace(/"/g, '""') + '"');
            });

            csv.push(csvRow.join(','));
        });

        var csvContent = csv.join('\n');
        var blob = new Blob(['\ufeff' + csvContent], { type: 'text/csv;charset=utf-8;' });
        var link = document.createElement('a');
        var url = URL.createObjectURL(blob);

        link.setAttribute('href', url);
        link.setAttribute('download', exportFileName);
        link.style.visibility = 'hidden';

        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    }

    function initAlertDismissal() {
        window.setTimeout(function () {
            var alerts = document.querySelectorAll('.alert-dismissible');
            alerts.forEach(function (alert) {
                if (!window.bootstrap?.Alert) return;
                var bsAlert = new window.bootstrap.Alert(alert);
                bsAlert.close();
            });
        }, 5000);
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

    document.addEventListener('DOMContentLoaded', function () {
        var searchInput = document.getElementById('q');
        var exportButton = document.querySelector('[data-registration-export]');

        initAutoSubmitControls();

        if (searchInput) {
            searchInput.addEventListener('input', applyClientSearch);
            applyClientSearch();
        }

        if (exportButton) {
            exportButton.addEventListener('click', exportToExcel);
        }

        initAlertDismissal();
    });

    window.exportToExcel = exportToExcel;
})();
