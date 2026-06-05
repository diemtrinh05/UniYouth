(function () {
    'use strict';

    const currentScript = document.currentScript || document.querySelector('script[data-home-dashboard-data]');
    const chartData = (() => {
        const raw = currentScript?.getAttribute('data-home-dashboard-data') || '{}';
        try {
            return JSON.parse(raw);
        } catch {
            return {};
        }
    })();
    const qrPreviewUrl = currentScript?.getAttribute('data-home-qr-preview-url') || '';

    function displayCurrentDate() {
        const currentDate = new Date().toLocaleDateString('vi-VN', {
            weekday: 'long',
            year: 'numeric',
            month: 'long',
            day: 'numeric'
        });

        const currentDateEl = document.getElementById('currentDate');
        if (currentDateEl) {
            currentDateEl.textContent = currentDate;
        }
    }

    function animateCounters() {
        const counters = document.querySelectorAll('.counter');
        const speed = 200;

        counters.forEach((counter) => {
            const target = Number(counter.getAttribute('data-target') || 0);
            const increment = target / speed;

            const updateCount = () => {
                const count = Number(counter.innerText || 0);
                if (count < target) {
                    counter.innerText = Math.ceil(count + increment);
                    window.setTimeout(updateCount, 10);
                    return;
                }

                counter.innerText = target.toLocaleString('vi-VN');
            };

            updateCount();
        });
    }

    function fadeInElements() {
        document.querySelectorAll('.animate-fade-in').forEach((element) => {
            const delay = Number(element.getAttribute('data-delay') || 0);
            window.setTimeout(() => {
                element.style.opacity = '1';
                element.style.transform = 'translateY(0)';
            }, delay);
        });
    }

    function initializeTooltips() {
        document
            .querySelectorAll('[data-bs-toggle="tooltip"]')
            .forEach((element) => bootstrap.Tooltip.getOrCreateInstance(element));
    }

    function initializeChart() {
        const chartElement = document.getElementById('eventsChart');
        if (!chartElement) {
            return;
        }

        const rootStyles = window.getComputedStyle(document.documentElement);
        const primaryColor = rootStyles.getPropertyValue('--uy-primary').trim() || 'rgb(37, 99, 235)';
        const successColor = rootStyles.getPropertyValue('--uy-success').trim() || 'rgb(22, 163, 74)';
        const borderColor = rootStyles.getPropertyValue('--uy-border').trim() || 'rgba(0, 0, 0, 0.05)';
        const textMutedColor = rootStyles.getPropertyValue('--uy-text-muted').trim() || '#64748b';

        const defaultSeries = chartData.week || {
            labels: [],
            eventCounts: [],
            validAttendanceCounts: []
        };

        const eventsChart = new Chart(chartElement, {
            type: 'line',
            data: {
                labels: defaultSeries.labels,
                datasets: [
                    {
                        label: 'Sự kiện đã tổ chức',
                        data: defaultSeries.eventCounts,
                        borderColor: primaryColor,
                        backgroundColor: 'rgba(37, 99, 235, 0.10)',
                        tension: 0.4,
                        fill: true,
                        pointRadius: 4,
                        pointHoverRadius: 6
                    },
                    {
                        label: 'Lượt điểm danh hợp lệ',
                        data: defaultSeries.validAttendanceCounts,
                        borderColor: successColor,
                        backgroundColor: 'rgba(22, 163, 74, 0.10)',
                        tension: 0.4,
                        fill: true,
                        pointRadius: 4,
                        pointHoverRadius: 6
                    }
                ]
            },
            options: {
                responsive: true,
                maintainAspectRatio: false,
                plugins: {
                    legend: {
                        position: 'top',
                        labels: {
                            color: textMutedColor,
                            usePointStyle: true
                        }
                    },
                    tooltip: { mode: 'index', intersect: false }
                },
                scales: {
                    y: {
                        beginAtZero: true,
                        grid: { color: borderColor },
                        ticks: { color: textMutedColor }
                    },
                    x: {
                        grid: { display: false },
                        ticks: { color: textMutedColor }
                    }
                }
            }
        });

        const periodButtons = document.querySelectorAll('[data-period]');
        const applyChartPeriod = (period) => {
            const selectedSeries = chartData[period];
            if (!selectedSeries) {
                return;
            }

            eventsChart.data.labels = selectedSeries.labels;
            eventsChart.data.datasets[0].data = selectedSeries.eventCounts;
            eventsChart.data.datasets[1].data = selectedSeries.validAttendanceCounts;
            eventsChart.update();
        };

        periodButtons.forEach((button) => {
            button.addEventListener('click', function () {
                periodButtons.forEach((current) => current.classList.remove('active'));
                this.classList.add('active');
                applyChartPeriod(this.getAttribute('data-period'));
            });
        });
    }

    function getQrPreviewElements() {
        const modalEl = document.getElementById('eventQrPreviewModal');
        return {
            modal: modalEl ? bootstrap.Modal.getOrCreateInstance(modalEl) : null,
            modalLabel: document.getElementById('eventQrPreviewModalLabel'),
            loading: document.getElementById('eventQrPreviewLoading'),
            content: document.getElementById('eventQrPreviewContent'),
            error: document.getElementById('eventQrPreviewError'),
            errorMessage: document.getElementById('eventQrPreviewErrorMessage'),
            eventName: document.getElementById('eventQrPreviewEventName'),
            timeRange: document.getElementById('eventQrPreviewTimeRange'),
            image: document.getElementById('eventQrPreviewImage'),
            scanCount: document.getElementById('eventQrPreviewScanCount'),
            scanLimit: document.getElementById('eventQrPreviewScanLimit')
        };
    }

    function formatPreviewDateTime(value) {
        if (!value) {
            return '-';
        }

        const date = new Date(value);
        if (Number.isNaN(date.getTime())) {
            return '-';
        }

        const dd = String(date.getDate()).padStart(2, '0');
        const mm = String(date.getMonth() + 1).padStart(2, '0');
        const yyyy = date.getFullYear();
        const hh = String(date.getHours()).padStart(2, '0');
        const mi = String(date.getMinutes()).padStart(2, '0');
        return `${dd}/${mm}/${yyyy} ${hh}:${mi}`;
    }

    function setQrPreviewState(elements, options) {
        if (!elements.loading || !elements.content || !elements.error || !elements.errorMessage) {
            return false;
        }

        elements.loading.classList.toggle('d-none', !options.loading);
        elements.content.classList.toggle('d-none', !options.showContent);
        elements.error.classList.toggle('d-none', options.showContent || options.loading);
        elements.errorMessage.textContent = options.message || '';
        return true;
    }

    async function openQrPreview(button) {
        const elements = getQrPreviewElements();
        const eventId = Number(button?.dataset?.eventId || 0);
        const eventName = button?.dataset?.eventName || 'Sự kiện';
        if (!eventId || !elements.modal || !qrPreviewUrl) {
            return;
        }

        elements.modalLabel.innerHTML = '<i class="bi bi-qr-code me-2"></i>QR Code sự kiện';
        elements.eventName.textContent = eventName;
        elements.timeRange.textContent = '';
        elements.image.removeAttribute('src');
        elements.scanCount.textContent = '-';
        elements.scanLimit.textContent = '-';

        if (!setQrPreviewState(elements, { loading: true, showContent: false, message: '' })) {
            return;
        }

        elements.modal.show();

        try {
            const response = await fetch(`${qrPreviewUrl}?eventId=${eventId}`, {
                headers: { 'X-Requested-With': 'XMLHttpRequest' }
            });
            const payload = await response.json();

            if (!response.ok || payload?.success !== true || !payload?.data?.qrImageDataUrl) {
                const fallbackTime = payload?.data?.validUntil
                    ? `Mốc gần nhất: ${formatPreviewDateTime(payload.data.validUntil)}`
                    : '';

                setQrPreviewState(elements, {
                    loading: false,
                    showContent: false,
                    message: [payload?.message || 'Không thể tải QR code.', fallbackTime]
                        .filter(Boolean)
                        .join(' • ')
                });
                return;
            }

            const data = payload.data;
            elements.eventName.textContent = data.eventName || eventName;
            elements.timeRange.textContent = `Hiệu lực: ${formatPreviewDateTime(data.validFrom)} - ${formatPreviewDateTime(data.validUntil)}`;
            elements.image.src = data.qrImageDataUrl;
            elements.scanCount.textContent = `${data.currentScans ?? 0}`;
            elements.scanLimit.textContent = data.scanLimit == null ? 'Không giới hạn' : `${data.scanLimit}`;
            setQrPreviewState(elements, { loading: false, showContent: true, message: '' });
        } catch (_error) {
            setQrPreviewState(elements, {
                loading: false,
                showContent: false,
                message: 'Đã xảy ra lỗi khi tải QR code chi tiết.'
            });
        }
    }

    function initializeQrPreview() {
        document.querySelectorAll('[data-home-qr-preview-trigger="true"]').forEach((button) => {
            button.addEventListener('click', () => openQrPreview(button));
        });
    }

    document.addEventListener('DOMContentLoaded', () => {
        displayCurrentDate();
        window.setTimeout(animateCounters, 300);
        fadeInElements();
        initializeTooltips();
        initializeChart();
        initializeQrPreview();
    });
})();
