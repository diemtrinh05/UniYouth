(function () {
    'use strict';

    function getExportFileName() {
        const script = document.currentScript || document.querySelector('script[data-attendance-export-file-name]');
        return script?.getAttribute('data-attendance-export-file-name') || 'DanhSachDiemDanh.csv';
    }

    const exportFileName = getExportFileName();

    function initializeTooltips() {
        document
            .querySelectorAll('[data-bs-toggle="tooltip"]')
            .forEach((element) => bootstrap.Tooltip.getOrCreateInstance(element));
    }

    function exportAttendanceToExcel() {
        const table = document.getElementById('attendancesTable');
        if (!table) {
            return;
        }

        const csv = [];
        const rows = table.querySelectorAll('tr');

        rows.forEach((row) => {
            const csvRow = [];
            row.querySelectorAll('td, th').forEach((col) => {
                csvRow.push(`"${col.innerText.replace(/"/g, '""')}"`);
            });
            csv.push(csvRow.join(','));
        });

        const blob = new Blob([`\ufeff${csv.join('\n')}`], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        const url = URL.createObjectURL(blob);

        link.setAttribute('href', url);
        link.setAttribute('download', exportFileName);
        link.style.visibility = 'hidden';

        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(url);
    }

    function initializeExportButton() {
        document.querySelectorAll('[data-attendance-export="true"]').forEach((button) => {
            button.addEventListener('click', exportAttendanceToExcel);
        });
    }

    function autoDismissAlerts() {
        window.setTimeout(() => {
            document.querySelectorAll('.alert-dismissible').forEach((alert) => {
                bootstrap.Alert.getOrCreateInstance(alert).close();
            });
        }, 5000);
    }

    document.addEventListener('DOMContentLoaded', () => {
        initializeTooltips();
        initializeExportButton();
        autoDismissAlerts();
    });
})();
