// Khởi tạo giá trị mặc định cho datetime inputs
document.addEventListener('DOMContentLoaded', function() {
    document.querySelectorAll('.js-ampm-datetime').forEach((input) => {
        const picker = flatpickr(input, {
            enableTime: true,
            time_24hr: false,
            dateFormat: 'Y-m-d\\TH:i',
            altInput: true,
            altInputClass: 'form-control',
            altFormat: 'd/m/Y h:i K',
            allowInput: true
        });

        if (picker.altInput && input.getAttribute('aria-label')) {
            picker.altInput.setAttribute('aria-label', input.getAttribute('aria-label'));
        }
    });

    const now = new Date();
    const validFrom = document.getElementById('GenerateForm_ValidFrom');
    const validUntil = document.getElementById('GenerateForm_ValidUntil');

    // Set default: bắt đầu = giờ hiện tại, kết thúc = 2 giờ sau
    if (!validFrom.value) {
        validFrom.value = formatDateTimeLocal(now);
    }

    const twoHoursLater = new Date(now.getTime() + 2 * 60 * 60 * 1000);
    if (!validUntil.value) {
        validUntil.value = formatDateTimeLocal(twoHoursLater);
    }

    // Update duration info
    updateDurationInfo();
});

// Format Date to datetime-local input format
function formatDateTimeLocal(date) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    return `${year}-${month}-${day}T${hours}:${minutes}`;
}

// Update duration info khi thay đổi datetime
document.getElementById('GenerateForm_ValidFrom').addEventListener('change', updateDurationInfo);
document.getElementById('GenerateForm_ValidUntil').addEventListener('change', updateDurationInfo);

function updateDurationInfo() {
    const validFrom = new Date(document.getElementById('GenerateForm_ValidFrom').value);
    const validUntil = new Date(document.getElementById('GenerateForm_ValidUntil').value);

    if (validFrom && validUntil) {
        const duration = validUntil - validFrom;
        const durationInfo = document.getElementById('durationInfo');
        const durationText = document.getElementById('durationText');

        if (duration > 0) {
            const days = Math.floor(duration / (1000 * 60 * 60 * 24));
            const hours = Math.floor((duration % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60));
            const minutes = Math.floor((duration % (1000 * 60 * 60)) / (1000 * 60));

            let durationStr = '';
            if (days > 0) durationStr += `${days} ngày `;
            if (hours > 0) durationStr += `${hours} giờ `;
            if (minutes > 0) durationStr += `${minutes} phút`;

            durationText.textContent = durationStr || 'Ít hơn 1 phút';
            durationInfo.style.display = 'block';
        } else {
            durationInfo.style.display = 'none';
        }
    }
}

// Quick action: Bắt đầu ngay
document.getElementById('setNowButton').addEventListener('click', function() {
    const now = new Date();
    const validFromInput = document.getElementById('GenerateForm_ValidFrom');
    if (validFromInput?._flatpickr) {
        validFromInput._flatpickr.setDate(now, true);
    } else {
        validFromInput.value = formatDateTimeLocal(now);
    }
    updateDurationInfo();
});

// Quick action: Hiệu lực 2 giờ
document.getElementById('set2HoursButton').addEventListener('click', function() {
    const now = new Date();
    const twoHoursLater = new Date(now.getTime() + 2 * 60 * 60 * 1000);

    const validFromInput = document.getElementById('GenerateForm_ValidFrom');
    const validUntilInput = document.getElementById('GenerateForm_ValidUntil');

    if (validFromInput?._flatpickr) {
        validFromInput._flatpickr.setDate(now, true);
    } else {
        validFromInput.value = formatDateTimeLocal(now);
    }

    if (validUntilInput?._flatpickr) {
        validUntilInput._flatpickr.setDate(twoHoursLater, true);
    } else {
        validUntilInput.value = formatDateTimeLocal(twoHoursLater);
    }

    updateDurationInfo();
});

// Khi submit: chỉ disable nút khi form hợp lệ (để tránh double submit).
document.getElementById('generateForm').addEventListener('submit', function () {
    if (window.jQuery && window.jQuery.validator) {
        const $form = window.jQuery(this);
        if (!$form.valid()) {
            return;
        }
    }

    const generateButton = document.getElementById('generateButton');
    generateButton.disabled = true;
    generateButton.innerHTML = '<i class="bi bi-hourglass-split me-1"></i>Đang tạo...';
});

// Xác nhận deactivate
function confirmDeactivate(qrId) {
    document.getElementById('deactivateQrId').value = qrId;
    const deactivateModal = new bootstrap.Modal(document.getElementById('deactivateModal'));
    deactivateModal.show();
}

document.querySelectorAll('[data-qr-deactivate]').forEach(function (button) {
    button.addEventListener('click', function () {
        const qrId = Number(button.getAttribute('data-qr-id') || 0);
        confirmDeactivate(qrId);
    });
});

window.confirmDeactivate = confirmDeactivate;

// Chi tiết QR (gọi API theo swagger: GET /api/events/qrcode/{qrId})
const qrDetailModal = document.getElementById('qrDetailModal');
const qrDetailUrl = qrDetailModal ? qrDetailModal.getAttribute('data-qr-detail-url') || '' : '';
function formatDateTimeText(value) {
    if (!value) return '-';
    const date = new Date(value);
    if (isNaN(date.getTime())) return '-';
    const dd = String(date.getDate()).padStart(2, '0');
    const mm = String(date.getMonth() + 1).padStart(2, '0');
    const yyyy = date.getFullYear();
    const hh = String(date.getHours()).padStart(2, '0');
    const mi = String(date.getMinutes()).padStart(2, '0');
    return `${dd}/${mm}/${yyyy} ${hh}:${mi}`;
}

qrDetailModal?.addEventListener('show.bs.modal', async function (event) {
    const button = event.relatedTarget;
    if (!button) return;

    const qrId = button.dataset.qrId;
    if (!qrId) return;

    const imgLoading = document.getElementById('qrDetailImageLoading');
    const imgWrapper = document.getElementById('qrImageWrapper');
    const img = document.getElementById('qrDetailImage');
    const downloadBtn = document.getElementById('downloadQrBtn');
    const statusBadge = document.getElementById('qrDetailStatusBadge');

    // reset UI
    document.getElementById('qrDetailId').textContent = `#${qrId}`;
    document.getElementById('qrDetailValidFrom').textContent = '-';
    document.getElementById('qrDetailValidUntil').textContent = '-';
    document.getElementById('qrDetailStatus').textContent = '-';
    document.getElementById('qrDetailFlags').textContent = '-';
    document.getElementById('qrDetailScans').textContent = '-';
    document.getElementById('qrDetailCreatedBy').textContent = '-';
    document.getElementById('qrDetailCreatedDate').textContent = '-';

    imgWrapper.classList.add('d-none');
    img.removeAttribute('src');
    downloadBtn.onclick = null;
    imgLoading.classList.remove('d-none');
    statusBadge.className = 'badge status-badge';

    try {
        const response = await fetch(`${qrDetailUrl}?qrId=${encodeURIComponent(qrId)}`, {
            headers: { 'Accept': 'application/json' }
        });

        const payload = await response.json();
        if (!response.ok || !payload || payload.success !== true) {
            const message = payload && payload.message ? payload.message : 'Không thể tải chi tiết QR code.';
            document.getElementById('qrDetailFlags').textContent = message;
            imgLoading.classList.add('d-none');
            return;
        }

        const data = payload.data;
        document.getElementById('qrDetailId').textContent = `#${data.qrId}`;
        document.getElementById('qrDetailValidFrom').textContent = formatDateTimeText(data.validFrom);
        document.getElementById('qrDetailValidUntil').textContent = formatDateTimeText(data.validUntil);

        // Update status badge với màu sắc
        const statusText = data.isActive ? 'Hoạt động' : 'Không hoạt động';
        document.getElementById('qrDetailStatus').textContent = statusText;

        if (data.isActive) {
            statusBadge.className = 'badge status-badge qr-status-success';
        } else if (data.isExpired) {
            statusBadge.className = 'badge status-badge qr-status-secondary';
        } else {
            statusBadge.className = 'badge status-badge qr-status-danger';
        }

        const flags = [];
        flags.push(data.isActive ? 'Đang hoạt động' : 'Không hoạt động');
        flags.push(data.isExpired ? 'Đã hết hạn' : 'Chưa hết hạn');
        if (data.isOverScanLimit) flags.push('Vượt giới hạn scan');
        document.getElementById('qrDetailFlags').textContent = flags.join(' • ');

        const scanLimitText = data.scanLimit ? data.scanLimit : '∞';
        document.getElementById('qrDetailScans').textContent = `${data.currentScans ?? 0} / ${scanLimitText}`;

        document.getElementById('qrDetailCreatedBy').textContent = data.createdByName || '-';
        document.getElementById('qrDetailCreatedDate').textContent = formatDateTimeText(data.createdDate);

        if (data.qrImageDataUrl) {
            img.src = data.qrImageDataUrl;
            imgWrapper.classList.remove('d-none');

            downloadBtn.onclick = function () {
                const a = document.createElement('a');
                a.href = data.qrImageDataUrl;
                a.download = `qr-${data.qrId}.png`;
                document.body.appendChild(a);
                a.click();
                a.remove();
            };
        }

        imgLoading.classList.add('d-none');
    } catch {
        document.getElementById('qrDetailFlags').textContent = 'Không thể tải chi tiết QR code.';
        imgLoading.classList.add('d-none');
    }
});

    // Tự động ẩn alert sau 8 giây
document.addEventListener('DOMContentLoaded', function() {
    setTimeout(function() {
        const alerts = document.querySelectorAll('.alert');
        alerts.forEach(function(alert) {
            const bsAlert = new bootstrap.Alert(alert);
            bsAlert.close();
        });
    }, 8000);
});
