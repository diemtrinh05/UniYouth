(function () {
    const pageRoot = document.getElementById('notificationPageRoot');
    if (!pageRoot) return;

    const filterSelect = document.getElementById('isReadFilter');
    const list = document.getElementById('notificationList');
    const filteredEmptyState = document.getElementById('filteredEmptyState');
    const clientErrorState = document.getElementById('clientErrorState');
    const notificationRetryButton = document.getElementById('notificationRetryButton');
    const visibleCountText = document.getElementById('visibleCountText');
    const loading = document.getElementById('pageLoadingState');
    const loadingRetry = document.getElementById('pageLoadingRetry');
    const loadingRetryBtn = document.getElementById('pageLoadingRetryBtn');
    const skeleton = document.getElementById('notificationLoadingSkeleton');
    const paginationContainer = document.getElementById('notificationPaginationContainer');
    const feedback = document.getElementById('notificationActionFeedback');
    const markAllReadButton = document.getElementById('markAllReadButton');
    const unreadOnPageValue = document.getElementById('unreadOnPageValue');
    const unreadCountApiValue = document.getElementById('unreadCountApiValue');

    const unreadCountUrl = pageRoot.getAttribute('data-unread-count-url') || '';
    const markAllReadUrl = pageRoot.getAttribute('data-mark-all-read-url') || '';
    const loginUrl = pageRoot.getAttribute('data-login-url') || '/Account/Login';

    let loadingRetryTimer = null;

    function hideSkeleton() {
        if (!skeleton) return;
        skeleton.classList.add('d-none');
    }

    function showLoading() {
        if (loading) {
            loading.classList.remove('d-none');
        }

        if (loadingRetry) {
            loadingRetry.classList.add('d-none');
        }

        if (loadingRetryTimer) {
            clearTimeout(loadingRetryTimer);
        }

        loadingRetryTimer = setTimeout(function () {
            if (loadingRetry) {
                loadingRetry.classList.remove('d-none');
            }
        }, 7000);
    }

    function hideLoading() {
        if (loading) {
            loading.classList.add('d-none');
        }

        if (loadingRetryTimer) {
            clearTimeout(loadingRetryTimer);
            loadingRetryTimer = null;
        }
    }

    function showFeedback(type, message) {
        if (!feedback) return;
        const text = (message || '').trim();
        if (!text) {
            feedback.className = 'alert d-none mb-3';
            feedback.textContent = '';
            return;
        }

        const safeType = type === 'success' ? 'success' : 'danger';
        feedback.className = 'alert alert-' + safeType + ' mb-3';
        feedback.textContent = text;
    }

    function buildLoginRedirect(message) {
        const returnUrl = encodeURIComponent(window.location.pathname + window.location.search);
        const encodedMessage = encodeURIComponent(message || 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
        const separator = loginUrl.indexOf('?') >= 0 ? '&' : '?';
        return loginUrl + separator + 'returnUrl=' + returnUrl + '&message=' + encodedMessage;
    }

    async function parseJsonSafe(response) {
        try {
            return await response.json();
        } catch {
            return null;
        }
    }

    async function requestJson(url, method, fallbackMessage) {
        if (!url) {
            return { success: false, message: fallbackMessage || 'Không xác định endpoint.' };
        }

        let response;
        try {
            response = await fetch(url, {
                method: method,
                headers: { 'Accept': 'application/json' }
            });
        } catch {
            return { success: false, message: fallbackMessage || 'Không thể kết nối đến máy chủ.' };
        }

        if (response.redirected && response.url && response.url.toLowerCase().indexOf('/account/login') >= 0) {
            window.location.assign(response.url);
            return { success: false, message: 'Phiên đăng nhập đã hết hạn.' };
        }

        const payload = await parseJsonSafe(response);
        const payloadMessage = payload && typeof payload.message === 'string' ? payload.message : '';

        if (response.status === 401) {
            window.location.assign(buildLoginRedirect(payloadMessage));
            return { success: false, message: payloadMessage || 'Phiên đăng nhập đã hết hạn.' };
        }

        if (response.status === 403) {
            return { success: false, message: payloadMessage || 'Bạn không có quyền thực hiện thao tác này.' };
        }

        if (!response.ok) {
            return { success: false, message: payloadMessage || fallbackMessage || 'Thao tác thất bại.' };
        }

        if (payload && typeof payload.success === 'boolean') {
            return {
                success: payload.success,
                message: payload.message || '',
                data: Object.prototype.hasOwnProperty.call(payload, 'data') ? payload.data : null
            };
        }

        return { success: true, message: '', data: payload };
    }

    function getTopbarBadgeElement() {
        return document.getElementById('notificationBadge');
    }

    function renderTopbarBadge(count) {
        const badge = getTopbarBadgeElement();
        if (!badge) return;

        const safeCount = Number.isFinite(count) && count > 0 ? Math.floor(count) : 0;
        if (safeCount <= 0) {
            badge.textContent = '0';
            badge.classList.add('d-none');
            return;
        }

        badge.textContent = safeCount > 99 ? '99+' : String(safeCount);
        badge.classList.remove('d-none');
    }

    function countUnreadOnPage() {
        if (!list) return 0;
        const items = list.querySelectorAll('[data-notification-item]');
        let unread = 0;
        items.forEach(function (item) {
            if ((item.getAttribute('data-is-read') || '').toLowerCase() !== 'true') {
                unread++;
            }
        });
        return unread;
    }

    function updateUnreadOnPageCounter() {
        if (!unreadOnPageValue) return;
        unreadOnPageValue.textContent = String(countUnreadOnPage());
    }

    function updateBulkActionButtonState() {
        if (!markAllReadButton) return;
        const unread = countUnreadOnPage();
        markAllReadButton.disabled = unread <= 0;
    }

    async function syncUnreadCountFromApi() {
        if (!unreadCountUrl) return;
        const result = await requestJson(unreadCountUrl, 'GET', 'Không thể tải số thông báo chưa đọc.');
        if (!result.success) {
            return;
        }

        let unreadCount = 0;
        if (typeof result.data === 'number') {
            unreadCount = result.data;
        } else if (result.data && typeof result.data.unreadCount === 'number') {
            unreadCount = result.data.unreadCount;
        }

        if (unreadCountApiValue) {
            unreadCountApiValue.textContent = String(Math.max(0, Math.floor(unreadCount)));
        }
        renderTopbarBadge(unreadCount);

        const stateStore = window.UniYouth && window.UniYouth.NotificationStateStore
            ? window.UniYouth.NotificationStateStore
            : null;
        if (stateStore && typeof stateStore.setUnreadCount === 'function') {
            stateStore.setUnreadCount(unreadCount, 'notification_page_sync');
        }
    }

    function markItemAsReadDom(item) {
        if (!item) return;

        item.setAttribute('data-is-read', 'true');

        const badge = item.querySelector('[data-read-badge]');
        if (badge) {
            badge.classList.remove('bg-danger');
            badge.classList.add('bg-secondary');
            badge.textContent = 'Đã đọc';
        }

        const actionCell = item.querySelector('[data-mark-read-btn]')?.parentElement;
        if (actionCell) {
            actionCell.innerHTML = '<button type="button" class="btn btn-sm btn-outline-secondary" disabled aria-label="Thông báo đã đọc">Đã đọc</button>';
        }
    }

    function showClientErrorState() {
        if (clientErrorState) {
            clientErrorState.classList.remove('d-none');
        }
        if (list) {
            list.classList.add('d-none');
        }
        if (filteredEmptyState) {
            filteredEmptyState.classList.add('d-none');
        }
        if (paginationContainer) {
            paginationContainer.classList.add('d-none');
        }
        if (visibleCountText) {
            visibleCountText.textContent = '';
        }
    }

    function hideClientErrorState() {
        if (clientErrorState) {
            clientErrorState.classList.add('d-none');
        }
        if (list) {
            list.classList.remove('d-none');
        }
    }

    function applyReadFilter() {
        if (!list || !filterSelect) return;

        hideClientErrorState();

        const items = list.querySelectorAll('[data-notification-item]');
        const mode = filterSelect.value;
        let visible = 0;

        items.forEach(function (item) {
            const isRead = item.getAttribute('data-is-read');
            const shouldShow = !mode || isRead === mode;
            item.classList.toggle('d-none', !shouldShow);
            if (shouldShow) visible++;
        });

        if (visibleCountText) {
            visibleCountText.textContent = 'Hiển thị: ' + visible;
        }

        if (filteredEmptyState) {
            filteredEmptyState.classList.toggle('d-none', visible > 0);
        }

        if (paginationContainer) {
            const hidePagination = mode && visible === 0;
            paginationContainer.classList.toggle('d-none', hidePagination);
        }
    }

    async function handleMarkReadClick(button) {
        if (!button || button.disabled) return;
        const url = button.getAttribute('data-mark-read-url');
        const item = button.closest('[data-notification-item]');
        const notificationId = item ? Number(item.getAttribute('data-notification-id')) : NaN;

        if (!item || !Number.isFinite(notificationId) || notificationId <= 0) {
            showFeedback('danger', 'Không xác định được thông báo cần cập nhật.');
            return;
        }

        button.disabled = true;
        const originalHtml = button.innerHTML;
        button.innerHTML = '<span class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>Đang cập nhật';

        const result = await requestJson(url, 'PUT', 'Không thể đánh dấu thông báo đã đọc.');
        if (result.success) {
            markItemAsReadDom(item);
            updateUnreadOnPageCounter();
            updateBulkActionButtonState();

            const stateStore = window.UniYouth && window.UniYouth.NotificationStateStore
                ? window.UniYouth.NotificationStateStore
                : null;
            if (stateStore && typeof stateStore.markAsRead === 'function') {
                stateStore.markAsRead(notificationId, 'notification_page_mark_read');
            }

            applyReadFilter();
            await syncUnreadCountFromApi();
            showFeedback('success', result.message || 'Đã đánh dấu thông báo đã đọc.');
            return;
        }

        button.disabled = false;
        button.innerHTML = originalHtml;
        showFeedback('danger', result.message || 'Không thể đánh dấu thông báo đã đọc.');
    }

    async function handleMarkAllReadClick() {
        if (!markAllReadButton || markAllReadButton.disabled) return;

        markAllReadButton.disabled = true;
        const originalText = markAllReadButton.textContent;
        markAllReadButton.textContent = 'Đang cập nhật...';

        const result = await requestJson(markAllReadUrl, 'PUT', 'Không thể đánh dấu tất cả thông báo đã đọc.');
        if (result.success) {
            if (list) {
                list.querySelectorAll('[data-notification-item]').forEach(function (item) {
                    markItemAsReadDom(item);
                });
            }

            updateUnreadOnPageCounter();
            updateBulkActionButtonState();

            const stateStore = window.UniYouth && window.UniYouth.NotificationStateStore
                ? window.UniYouth.NotificationStateStore
                : null;
            if (stateStore && typeof stateStore.markAllAsRead === 'function') {
                stateStore.markAllAsRead('notification_page_mark_all_read');
            }

            applyReadFilter();
            await syncUnreadCountFromApi();
            showFeedback('success', result.message || 'Đã đánh dấu tất cả thông báo đã đọc.');
            return;
        }

        markAllReadButton.disabled = false;
        markAllReadButton.textContent = originalText;
        showFeedback('danger', result.message || 'Không thể đánh dấu tất cả thông báo đã đọc.');
    }

    if (filterSelect) {
        filterSelect.addEventListener('change', function () {
            try {
                applyReadFilter();
            } catch {
                showClientErrorState();
            }
        });

        try {
            applyReadFilter();
        } catch {
            showClientErrorState();
        }
    }

    if (list) {
        list.addEventListener('click', function (event) {
            const button = event.target.closest('[data-mark-read-btn]');
            if (!button) return;
            handleMarkReadClick(button);
        });
    }

    if (markAllReadButton) {
        markAllReadButton.addEventListener('click', function () {
            handleMarkAllReadClick();
        });
    }

    document.querySelectorAll('form[data-loading-form]').forEach(function (form) {
        form.addEventListener('submit', showLoading);
    });

    document.querySelectorAll('.pagination a.page-link').forEach(function (link) {
        link.addEventListener('click', showLoading);
    });

    if (loadingRetryBtn) {
        loadingRetryBtn.addEventListener('click', function () {
            window.location.reload();
        });
    }

    if (notificationRetryButton) {
        notificationRetryButton.addEventListener('click', function () {
            try {
                applyReadFilter();
            } catch {
                window.location.reload();
            }
        });
    }

    updateUnreadOnPageCounter();
    updateBulkActionButtonState();
    syncUnreadCountFromApi();
    hideLoading();
    hideSkeleton();
})();
