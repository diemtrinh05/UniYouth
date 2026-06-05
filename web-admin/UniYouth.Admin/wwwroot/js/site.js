/**
 * UniYouth Admin - JavaScript Tùy chỉnh
 * Xử lý toggle sidebar, highlight menu đang active và các tương tác UI khác
 */

(function () {
    'use strict';

    // ============================================
    // Toggle Sidebar
    // ============================================
    const sidebarToggle = document.getElementById('sidebarToggle');
    const sidebarToggleTop = document.getElementById('sidebarToggleTop');
    const sidebar = document.getElementById('sidebar');
    const sidebarToggleDesktop = document.getElementById('sidebarToggleDesktop');
    const mainContent = document.querySelector('.main-content');

    // Toggle cho Mobile (hiện/ẩn sidebar từ bên trái)
    if (sidebarToggle) {
        sidebarToggle.addEventListener('click', function (e) {
            e.preventDefault();
            sidebar.classList.toggle('active');
        });
    }

    if (sidebarToggleTop) {
        sidebarToggleTop.addEventListener('click', function (e) {
            e.preventDefault();
            sidebar.classList.toggle('active');
        });
    }

    // Toggle cho Desktop (thu gọn/mở rộng sidebar)
    if (sidebarToggleDesktop) {
        sidebarToggleDesktop.addEventListener('click', function (e) {
            e.preventDefault();

            // Toggle class 'toggled' cho cả sidebar và main-content
            sidebar.classList.toggle('toggled');
            if (mainContent) {
                mainContent.classList.toggle('toggled');
            }

            // Lưu trạng thái vào localStorage để duy trì khi reload
            const isToggled = sidebar.classList.contains('toggled');
            localStorage.setItem('sidebarToggled', isToggled);

            // Animation mượt cho icon
            const icon = this.querySelector('i');
            if (icon) {
                icon.style.transform = isToggled ? 'rotate(180deg)' : 'rotate(0deg)';
            }
        });
    }

    // Khôi phục trạng thái sidebar từ localStorage khi tải trang
    function restoreSidebarState() {
        const isToggled = localStorage.getItem('sidebarToggled') === 'true';
        if (isToggled) {
            sidebar.classList.add('toggled');
            if (mainContent) {
                mainContent.classList.add('toggled');
            }
        }
    }

    // Gọi hàm khôi phục trạng thái
    restoreSidebarState();

    // Đóng sidebar khi click ra ngoài trên mobile
    document.addEventListener('click', function (e) {
        if (window.innerWidth <= 768) {
            if (!sidebar.contains(e.target) &&
                !sidebarToggle?.contains(e.target) &&
                !sidebarToggleTop?.contains(e.target)) {
                sidebar.classList.remove('active');
            }
        }
    });

    // Xử lý resize window - đảm bảo sidebar state phù hợp
    let resizeTimer;
    window.addEventListener('resize', function () {
        clearTimeout(resizeTimer);
        resizeTimer = setTimeout(function () {
            if (window.innerWidth <= 768) {
                // Mobile: đảm bảo toggle state được reset
                sidebar.classList.remove('toggled');
                mainContent.classList.remove('toggled');
            } else {
                // Desktop: khôi phục state từ localStorage
                restoreSidebarState();
            }
        }, 250);
    });

    // ============================================
    // Highlight Menu Item Đang Active
    // ============================================
    function setActiveMenuItem() {
        const currentPath = window.location.pathname;
        const menuLinks = document.querySelectorAll('.sidebar .nav-link');

        menuLinks.forEach(link => {
            // Xóa class active khỏi tất cả các link
            link.classList.remove('active');

            // Lấy thuộc tính href
            const href = link.getAttribute('href');

            // Kiểm tra nếu đường dẫn hiện tại khớp với link
            if (href && currentPath.includes(href) && href !== '/') {
                link.classList.add('active');
            }
            // Trường hợp đặc biệt cho trang chủ
            else if (href === '/' && (currentPath === '/' || currentPath === '/Home/Index')) {
                link.classList.add('active');
            }
        });
    }

    // Set menu item đang active khi tải trang
    setActiveMenuItem();

    // ============================================
    // Cuộn Mượt cho Anchor Links
    // ============================================
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        if (anchor.classList.contains('uy-skip-link')) {
            anchor.addEventListener('focus', function () {
                this.classList.add('uy-skip-link-visible');
            });

            anchor.addEventListener('blur', function () {
                this.classList.remove('uy-skip-link-visible');
            });
        }

        anchor.addEventListener('click', function (e) {
            const href = this.getAttribute('href');
            if (href !== '#' && href !== '#!') {
                e.preventDefault();
                const target = document.querySelector(href);
                if (target) {
                    target.scrollIntoView({
                        behavior: 'smooth',
                        block: 'start'
                    });

                    if (this.classList.contains('uy-skip-link')) {
                        target.focus({ preventScroll: true });
                    }
                }
            }
        });
    });

    // ============================================
    // Khởi tạo Bootstrap Tooltip
    // ============================================
    const tooltipTriggerList = document.querySelectorAll('[data-bs-toggle="tooltip"]');
    if (tooltipTriggerList.length > 0 && typeof bootstrap !== 'undefined') {
        const tooltipList = [...tooltipTriggerList].map(tooltipTriggerEl =>
            new bootstrap.Tooltip(tooltipTriggerEl)
        );
    }

    // ============================================
    // Khởi tạo Bootstrap Popover
    // ============================================
    const popoverTriggerList = document.querySelectorAll('[data-bs-toggle="popover"]');
    if (popoverTriggerList.length > 0 && typeof bootstrap !== 'undefined') {
        const popoverList = [...popoverTriggerList].map(popoverTriggerEl =>
            new bootstrap.Popover(popoverTriggerEl)
        );
    }

    // ============================================
    // Cải tiến Validation Form
    // ============================================
    const forms = document.querySelectorAll('.needs-validation');
    Array.from(forms).forEach(form => {
        form.addEventListener('submit', event => {
            if (!form.checkValidity()) {
                event.preventDefault();
                event.stopPropagation();
            }
            form.classList.add('was-validated');
        }, false);
    });

    // ============================================
    // Tự động ẩn alerts sau 5 giây
    // ============================================
    const alerts = document.querySelectorAll('.alert:not(.alert-permanent)');
    if (typeof bootstrap !== 'undefined') {
        alerts.forEach(alert => {
            setTimeout(() => {
                const bsAlert = new bootstrap.Alert(alert);
                bsAlert.close();
            }, 5000);
        });
    }

    // ============================================
    // Hộp thoại Xác nhận cho thao tác Xóa
    // ============================================
    const deleteButtons = document.querySelectorAll('[data-confirm-delete]');
    deleteButtons.forEach(button => {
        button.addEventListener('click', function (e) {
            const message = this.getAttribute('data-confirm-delete') ||
                'Bạn có chắc chắn muốn xóa mục này?';
            if (!confirm(message)) {
                e.preventDefault();
            }
        });
    });

    // ============================================
    // Xử lý Click Row của Table (Tùy chọn)
    // ============================================
    const clickableRows = document.querySelectorAll('tr[data-href]');
    clickableRows.forEach(row => {
        row.addEventListener('click', function (e) {
            // Không kích hoạt nếu click vào button hoặc link
            if (e.target.tagName !== 'BUTTON' &&
                e.target.tagName !== 'A' &&
                !e.target.closest('button') &&
                !e.target.closest('a')) {
                const href = this.getAttribute('data-href');
                if (href) {
                    window.location.href = href;
                }
            }
        });
        // Thêm con trỏ pointer
        row.style.cursor = 'pointer';
    });

    // ============================================
    // Chức năng Tìm kiếm/Lọc Table
    // ============================================
    const tableSearchInputs = document.querySelectorAll('[data-table-search]');
    tableSearchInputs.forEach(input => {
        const tableId = input.getAttribute('data-table-search');
        const table = document.getElementById(tableId);

        if (table) {
            input.addEventListener('keyup', function () {
                const filter = this.value.toLowerCase();
                const rows = table.querySelectorAll('tbody tr');

                rows.forEach(row => {
                    const text = row.textContent.toLowerCase();
                    row.style.display = text.includes(filter) ? '' : 'none';
                });
            });
        }
    });

    // ============================================
    // Chức năng In
    // ============================================
    const printButtons = document.querySelectorAll('[data-print]');
    printButtons.forEach(button => {
        button.addEventListener('click', function () {
            window.print();
        });
    });

    // ============================================
    // Chức năng Sao chép vào Clipboard
    // ============================================
    const copyButtons = document.querySelectorAll('[data-copy]');
    copyButtons.forEach(button => {
        button.addEventListener('click', function () {
            const target = document.querySelector(this.getAttribute('data-copy'));
            if (target) {
                const text = target.textContent || target.value;
                navigator.clipboard.writeText(text).then(() => {
                    // Hiển thị thông báo thành công
                    const originalText = this.innerHTML;
                    this.innerHTML = '<i class="bi bi-check"></i> Đã sao chép!';
                    setTimeout(() => {
                        this.innerHTML = originalText;
                    }, 2000);
                });
            }
        });
    });

    // ============================================
    // Thêm tooltip cho sidebar khi collapsed
    // ============================================
    function updateSidebarTooltips() {
        const navLinks = document.querySelectorAll('.sidebar .nav-link');
        const isCollapsed = sidebar.classList.contains('toggled');

        navLinks.forEach(link => {
            const span = link.querySelector('span');
            if (span && isCollapsed) {
                // Thêm tooltip khi collapsed
                const text = span.textContent.trim();
                link.setAttribute('data-bs-toggle', 'tooltip');
                link.setAttribute('data-bs-placement', 'right');
                link.setAttribute('title', text);

                // Khởi tạo tooltip
                if (typeof bootstrap !== 'undefined') {
                    new bootstrap.Tooltip(link);
                }
            } else {
                // Xóa tooltip khi expanded
                link.removeAttribute('data-bs-toggle');
                link.removeAttribute('data-bs-placement');
                link.removeAttribute('title');

                // Hủy tooltip nếu có
                const tooltip = bootstrap.Tooltip.getInstance(link);
                if (tooltip) {
                    tooltip.dispose();
                }
            }
        });
    }

    // Cập nhật tooltips khi toggle sidebar
    if (sidebarToggleDesktop) {
        sidebarToggleDesktop.addEventListener('click', function () {
            setTimeout(updateSidebarTooltips, 350); // Đợi animation hoàn thành
        });
    }

    // Cập nhật tooltips khi tải trang
    updateSidebarTooltips();

    // ============================================
    // Notification Topbar Dropdown (Dynamic)
    // ============================================
    function initNotificationTopbarDropdown() {
        const alertsDropdown = document.getElementById('alertsDropdown');
        const badge = document.getElementById('notificationBadge');
        const dropdownList = document.getElementById('notificationDropdownList');
        const loadingState = document.getElementById('notificationDropdownLoading');
        const emptyState = document.getElementById('notificationDropdownEmpty');
        const errorState = document.getElementById('notificationDropdownError');
        const errorText = document.getElementById('notificationDropdownErrorText');
        const retryBtn = document.getElementById('notificationDropdownRetryBtn');
        const markAllBtn = document.getElementById('notificationDropdownMarkAllBtn');
        const unreadLabel = document.getElementById('notificationDropdownUnreadLabel');

        if (!alertsDropdown || !badge || !dropdownList) {
            return;
        }

        const unreadUrl = alertsDropdown.getAttribute('data-unread-url') || '';
        const allUrl = alertsDropdown.getAttribute('data-all-url') || '/Notifications';
        const loginUrl = alertsDropdown.getAttribute('data-login-url') || '/Account/Login';
        const pageSize = Math.max(1, Number.parseInt(alertsDropdown.getAttribute('data-list-page-size') || '5', 10) || 5);

        function deriveApiBaseFromUnreadUrl(url) {
            if (!url || typeof url !== 'string') {
                return '/Notifications/ajax';
            }

            const clean = url.split('?')[0];
            if (clean.endsWith('/unread-count')) {
                return clean.slice(0, -'/unread-count'.length) || '/Notifications/ajax';
            }

            return clean.replace(/\/+$/, '') || '/Notifications/ajax';
        }

        const dropdownApiBaseUrl = deriveApiBaseFromUnreadUrl(unreadUrl);

        const stateStore = window.UniYouth && window.UniYouth.NotificationStateStore
            ? window.UniYouth.NotificationStateStore
            : null;
        const apiClient = window.UniYouth && window.UniYouth.NotificationApiClient && typeof window.UniYouth.NotificationApiClient.create === 'function'
            ? window.UniYouth.NotificationApiClient.create({
                loginPath: loginUrl,
                baseUrl: dropdownApiBaseUrl
            })
            : null;

        let currentNotifications = [];
        let currentUnreadCount = 0;
        let loadedOnce = false;
        let loadingInProgress = false;
        const markReadInProgressIds = new Set();
        const LIST_CACHE_TTL_MS = 15000;
        const UNREAD_CACHE_TTL_MS = 8000;
        let lastListFetchedAt = 0;
        let lastUnreadFetchedAt = 0;
        let lastDropdownRefreshAt = 0;

        function toInt(value, fallbackValue) {
            const n = Number(value);
            if (!Number.isFinite(n)) return fallbackValue;
            return Math.floor(n);
        }

        function setDropdownMode(mode) {
            if (loadingState) loadingState.classList.toggle('d-none', mode !== 'loading');
            if (emptyState) emptyState.classList.toggle('d-none', mode !== 'empty');
            if (errorState) errorState.classList.toggle('d-none', mode !== 'error');
            if (dropdownList) dropdownList.classList.toggle('d-none', mode !== 'list');
        }

        function setErrorMessage(message) {
            if (!errorText) return;
            errorText.textContent = (message || 'Không thể tải thông báo.').trim();
        }

        function setBadgeCount(count) {
            const safeCount = Number.isFinite(count) && count > 0 ? Math.floor(count) : 0;
            currentUnreadCount = safeCount;

            if (safeCount <= 0) {
                badge.textContent = '0';
                badge.classList.add('d-none');
            } else {
                badge.textContent = safeCount > 99 ? '99+' : String(safeCount);
                badge.classList.remove('d-none');
            }

            if (unreadLabel) {
                unreadLabel.textContent = 'Chưa đọc: ' + safeCount;
            }

            if (markAllBtn) {
                markAllBtn.disabled = safeCount <= 0;
            }
        }

        function getFirstValue(obj, keys) {
            if (!obj || typeof obj !== 'object') return undefined;
            for (let i = 0; i < keys.length; i++) {
                if (Object.prototype.hasOwnProperty.call(obj, keys[i])) {
                    return obj[keys[i]];
                }
            }
            return undefined;
        }

        function getNotificationId(item) {
            const rawId = getFirstValue(item, ['notificationID', 'notificationId', 'NotificationID', 'NotificationId', 'id', 'Id']);
            const id = toInt(rawId, 0);
            return id > 0 ? id : null;
        }

        function sanitizeText(value, maxLength) {
            if (typeof value !== 'string') return '';
            const clean = value.replace(/[\u0000-\u001F\u007F]/g, ' ').trim();
            if (!clean) return '';
            return clean.length > maxLength ? clean.slice(0, maxLength) : clean;
        }

        function sanitizeActionUrl(value) {
            if (typeof value !== 'string') return null;
            const url = value.trim();
            if (!url || url.length > 2048) return null;
            if (url.startsWith('//')) return null;

            const lower = url.toLowerCase();
            if (lower.startsWith('javascript:') || lower.startsWith('data:') || lower.startsWith('vbscript:')) {
                return null;
            }

            if (!url.startsWith('/')) {
                return null;
            }

            const queryIndex = url.search(/[?#]/);
            const suffix = queryIndex >= 0 ? url.slice(queryIndex) : '';
            const pathOnly = (queryIndex >= 0 ? url.slice(0, queryIndex) : url)
                .replace(/\/+$/g, '')
                || '/';

            const eventDetailMatch = /^\/events\/(\d+)$/i.exec(pathOnly);
            if (eventDetailMatch) {
                return '/Events/Details/' + eventDetailMatch[1] + suffix;
            }

            return pathOnly === '/' ? '/' + suffix.replace(/^\/+/, '') : pathOnly + suffix;
        }

        function normalizeNotification(item) {
            const id = getNotificationId(item);
            if (!id) return null;

            const normalized = {
                notificationId: id,
                title: sanitizeText(getFirstValue(item, ['title', 'Title']), 250),
                content: sanitizeText(getFirstValue(item, ['content', 'Content']), 400),
                notificationType: sanitizeText(getFirstValue(item, ['notificationType', 'NotificationType']), 100),
                isRead: getFirstValue(item, ['isRead', 'IsRead']) === true,
                actionUrl: sanitizeActionUrl(getFirstValue(item, ['actionUrl', 'ActionUrl'])),
                createdDate: getFirstValue(item, ['createdDate', 'CreatedDate']) || null,
                priority: toInt(getFirstValue(item, ['priority', 'Priority']), 0)
            };

            return normalized;
        }

        function normalizeNotifications(items) {
            if (!Array.isArray(items)) return [];
            return items
                .map(normalizeNotification)
                .filter(function (item) { return item !== null; });
        }

        function readUnreadCountFromData(data) {
            if (typeof data === 'number') {
                return Math.max(0, toInt(data, 0));
            }

            if (data && typeof data === 'object') {
                const value = getFirstValue(data, ['unreadCount', 'UnreadCount', 'count', 'Count']);
                if (value !== undefined) {
                    return Math.max(0, toInt(value, 0));
                }
            }

            return null;
        }

        function formatDate(value) {
            if (!value) return '';
            const date = new Date(value);
            if (Number.isNaN(date.getTime())) return '';
            return date.toLocaleString('vi-VN', {
                day: '2-digit',
                month: '2-digit',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            });
        }

        function getIconClass(notification) {
            const type = (notification.notificationType || '').toLowerCase();
            if (type.includes('success') || type.includes('read')) return 'bi-check-circle';
            if (type.includes('warning')) return 'bi-exclamation-triangle';
            if (notification.priority >= 4) return 'bi-exclamation-circle';
            return 'bi-bell';
        }

        function getIconBgClass(notification) {
            const type = (notification.notificationType || '').toLowerCase();
            if (type.includes('success') || type.includes('read')) return 'bg-success';
            if (type.includes('warning')) return 'bg-warning';
            if (notification.priority >= 4) return 'bg-danger';
            return 'bg-primary';
        }

        function markItemLocallyAsRead(notificationId) {
            currentNotifications = currentNotifications.map(function (item) {
                if (item.notificationId !== notificationId) return item;
                return Object.assign({}, item, { isRead: true });
            });
        }

        function renderDropdownList() {
            dropdownList.innerHTML = '';

            const preview = currentNotifications.slice(0, pageSize);
            if (preview.length === 0) {
                setDropdownMode('empty');
                return;
            }

            preview.forEach(function (notification) {
                const link = document.createElement('a');
                link.className = 'dropdown-item topbar-notification-item';
                if (notification.isRead !== true) {
                    link.classList.add('topbar-notification-item-unread');
                }
                link.href = notification.actionUrl || allUrl;
                link.setAttribute('data-notification-id', String(notification.notificationId));

                const wrapper = document.createElement('div');
                wrapper.className = 'd-flex align-items-start';

                const iconWrap = document.createElement('div');
                iconWrap.className = 'me-3';
                const iconCircle = document.createElement('div');
                iconCircle.className = 'icon-circle ' + getIconBgClass(notification);
                const icon = document.createElement('i');
                icon.className = 'bi ' + getIconClass(notification) + ' text-white';
                iconCircle.appendChild(icon);
                iconWrap.appendChild(iconCircle);

                const body = document.createElement('div');
                body.className = 'topbar-notification-body';

                const dateEl = document.createElement('div');
                dateEl.className = 'small text-gray-500';
                dateEl.textContent = formatDate(notification.createdDate) || 'Mới cập nhật';

                const titleEl = document.createElement('div');
                titleEl.className = 'topbar-notification-title';
                titleEl.textContent = notification.title || 'Thông báo hệ thống';

                const contentEl = document.createElement('div');
                contentEl.className = 'topbar-notification-content';
                contentEl.textContent = notification.content || '';

                body.appendChild(dateEl);
                body.appendChild(titleEl);
                if (contentEl.textContent) {
                    body.appendChild(contentEl);
                }

                wrapper.appendChild(iconWrap);
                wrapper.appendChild(body);
                link.appendChild(wrapper);

                link.addEventListener('click', async function (event) {
                    if (notification.isRead === true) {
                        return;
                    }

                    event.preventDefault();

                    const targetUrl = link.getAttribute('href') || allUrl;
                    const markResult = await handleMarkRead(notification.notificationId, true);

                    if (markResult && markResult.redirectedToLogin === true) {
                        return;
                    }

                    window.location.assign(targetUrl);
                });

                dropdownList.appendChild(link);
            });

            setDropdownMode('list');
        }

        function applySnapshot(snapshot) {
            if (!snapshot || typeof snapshot !== 'object') return;

            if (Array.isArray(snapshot.notifications)) {
                currentNotifications = normalizeNotifications(snapshot.notifications);
            }

            if (snapshot.unreadCount !== undefined) {
                setBadgeCount(Math.max(0, toInt(snapshot.unreadCount, 0)));
            }

            if (loadedOnce) {
                renderDropdownList();
            }
        }

        async function requestUnreadCount(options) {
            const cfg = options || {};
            const force = cfg.force === true;

            if (!force && lastUnreadFetchedAt > 0 && (Date.now() - lastUnreadFetchedAt) < UNREAD_CACHE_TTL_MS) {
                return true;
            }

            if (apiClient && typeof apiClient.getUnreadCount === 'function') {
                const result = await apiClient.getUnreadCount();
                if (!result || result.success !== true) {
                    return false;
                }

                const unread = readUnreadCountFromData(result.data);
                if (unread !== null) {
                    setBadgeCount(unread);
                    if (stateStore && typeof stateStore.setUnreadCount === 'function') {
                        stateStore.setUnreadCount(unread, 'topbar_unread_sync');
                    }
                }
                lastUnreadFetchedAt = Date.now();
                return true;
            }

            if (!unreadUrl) return false;

            try {
                const response = await fetch(unreadUrl, {
                    method: 'GET',
                    headers: { 'Accept': 'application/json' }
                });
                if (!response.ok) return false;

                const payload = await response.json();
                if (!payload || payload.success !== true) return false;

                const unread = readUnreadCountFromData(payload.data);
                if (unread !== null) {
                    setBadgeCount(unread);
                }
                lastUnreadFetchedAt = Date.now();
                return true;
            } catch {
                return false;
            }
        }

        async function requestNotificationList(options) {
            const cfg = options || {};
            const force = cfg.force === true;

            if (!force && loadedOnce && lastListFetchedAt > 0 && (Date.now() - lastListFetchedAt) < LIST_CACHE_TTL_MS) {
                return {
                    ok: true,
                    unreadProvided: true,
                    fromCache: true
                };
            }

            if (!apiClient || typeof apiClient.getList !== 'function') {
                return {
                    ok: false,
                    unreadProvided: false
                };
            }

            const result = await apiClient.getList(1, pageSize);
            if (!result || result.success !== true || !result.data || typeof result.data !== 'object') {
                return {
                    ok: false,
                    unreadProvided: false
                };
            }

            const notifications = normalizeNotifications(getFirstValue(result.data, ['notifications', 'Notifications']) || []);
            const unread = readUnreadCountFromData(result.data);

            currentNotifications = notifications;
            if (unread !== null) {
                setBadgeCount(unread);
                lastUnreadFetchedAt = Date.now();
            }

            if (stateStore && typeof stateStore.setNotifications === 'function') {
                stateStore.setNotifications(notifications, 'topbar_list_sync');
            }

            if (stateStore && unread !== null && typeof stateStore.setUnreadCount === 'function') {
                stateStore.setUnreadCount(unread, 'topbar_list_unread_sync');
            }

            lastListFetchedAt = Date.now();
            return {
                ok: true,
                unreadProvided: unread !== null,
                fromCache: false
            };
        }

        async function refreshDropdown(forceShowLoading, options) {
            const cfg = options || {};
            const force = cfg.force === true;

            if (loadingInProgress) return;

            const isCacheFresh = !force &&
                loadedOnce &&
                lastDropdownRefreshAt > 0 &&
                (Date.now() - lastDropdownRefreshAt) < LIST_CACHE_TTL_MS;

            if (isCacheFresh) {
                renderDropdownList();
                return;
            }

            loadingInProgress = true;

            if (forceShowLoading) {
                setDropdownMode('loading');
            }

            let listOk = false;
            let unreadOk = false;
            try {
                const listResult = await requestNotificationList({ force: force });
                listOk = listResult.ok === true;

                if (listOk && listResult.unreadProvided === true) {
                    unreadOk = true;
                } else {
                    unreadOk = await requestUnreadCount({ force: force });
                }
            } catch {
                listOk = false;
                unreadOk = false;
            } finally {
                loadingInProgress = false;
            }

            loadedOnce = true;

            if (!listOk && !unreadOk) {
                setErrorMessage('Không thể tải thông báo. Vui lòng thử lại.');
                setDropdownMode('error');
                return;
            }

            lastDropdownRefreshAt = Date.now();
            renderDropdownList();
        }

        async function handleMarkRead(notificationId, silent) {
            if (!apiClient || typeof apiClient.markAsRead !== 'function') {
                return { success: false };
            }

            const id = toInt(notificationId, 0);
            if (id <= 0) return { success: false };
            if (markReadInProgressIds.has(id)) {
                return { success: false, skipped: true };
            }

            markReadInProgressIds.add(id);

            let result;
            try {
                result = await apiClient.markAsRead(id);
            } finally {
                markReadInProgressIds.delete(id);
            }

            if (!result || result.success !== true) {
                if (!silent) {
                    setErrorMessage(result && result.message ? result.message : 'Không thể đánh dấu đã đọc.');
                    setDropdownMode('error');
                }
                return result || { success: false };
            }

            markItemLocallyAsRead(id);
            if (stateStore && typeof stateStore.markAsRead === 'function') {
                stateStore.markAsRead(id, 'topbar_mark_read');
            }

            await requestUnreadCount({ force: true });
            renderDropdownList();
            return result;
        }

        async function handleMarkAllRead() {
            if (!apiClient || typeof apiClient.markAllAsRead !== 'function') {
                return;
            }

            if (markAllBtn) {
                markAllBtn.disabled = true;
            }

            const result = await apiClient.markAllAsRead();
            if (!result || result.success !== true) {
                setErrorMessage(result && result.message ? result.message : 'Không thể đánh dấu tất cả đã đọc.');
                setDropdownMode('error');
                if (markAllBtn) {
                    markAllBtn.disabled = false;
                }
                return;
            }

            currentNotifications = currentNotifications.map(function (item) {
                return Object.assign({}, item, { isRead: true });
            });

            if (stateStore && typeof stateStore.markAllAsRead === 'function') {
                stateStore.markAllAsRead('topbar_mark_all_read');
            }

            await requestUnreadCount({ force: true });
            renderDropdownList();
        }

        if (retryBtn) {
            retryBtn.addEventListener('click', function () {
                refreshDropdown(true, { force: true });
            });
        }

        if (markAllBtn) {
            markAllBtn.addEventListener('click', function (event) {
                event.preventDefault();
                handleMarkAllRead();
            });
        }

        alertsDropdown.addEventListener('show.bs.dropdown', function () {
            refreshDropdown(!loadedOnce, { force: false });
        });

        if (stateStore && typeof stateStore.subscribe === 'function') {
            stateStore.subscribe(function (snapshot) {
                applySnapshot(snapshot);
            });

            applySnapshot(stateStore.getState());
        }

        refreshDropdown(false, { force: false });
    }

    function initNotificationRealtime() {
        const alertsDropdown = document.getElementById('alertsDropdown');
        if (!alertsDropdown) {
            return;
        }

        const realtimeEnabled = String(alertsDropdown.getAttribute('data-realtime-enabled') || '')
            .trim()
            .toLowerCase() === 'true';
        if (!realtimeEnabled) {
            return;
        }

        if (window.UniYouth && window.UniYouth.__notificationRealtimeInitialized === true) {
            return;
        }

        const signalRClientFactory = window.UniYouth && window.UniYouth.NotificationSignalRClient;
        if (!signalRClientFactory || typeof signalRClientFactory.getOrCreate !== 'function') {
            return;
        }

        const stateStore = window.UniYouth && window.UniYouth.NotificationStateStore
            ? window.UniYouth.NotificationStateStore
            : null;
        const toastContainer = document.getElementById('globalToastContainer');

        const unreadUrl = alertsDropdown.getAttribute('data-unread-url') || '';
        const loginUrl = alertsDropdown.getAttribute('data-login-url') || '/Account/Login';
        const hubUrl = (alertsDropdown.getAttribute('data-realtime-hub-url') || '').trim();
        const listPageSize = Math.max(1, Number.parseInt(alertsDropdown.getAttribute('data-list-page-size') || '5', 10) || 5);
        let disposed = false;
        const TOAST_DEDUPE_TTL_MS = 30000;
        const TOAST_MAX_TRACKED_KEYS = 200;
        const TOAST_MAX_VISIBLE = 4;
        const recentToastKeys = new Map();
        let snapshotSyncInProgress = false;
        let snapshotSyncPending = false;

        function deriveApiBaseFromUnreadUrl(url) {
            if (!url || typeof url !== 'string') {
                return '/Notifications/ajax';
            }

            const clean = url.split('?')[0];
            if (clean.endsWith('/unread-count')) {
                return clean.slice(0, -'/unread-count'.length) || '/Notifications/ajax';
            }

            return clean.replace(/\/+$/, '') || '/Notifications/ajax';
        }

        const realtimeApiBaseUrl = deriveApiBaseFromUnreadUrl(unreadUrl);
        const realtimeApiClient = window.UniYouth && window.UniYouth.NotificationApiClient && typeof window.UniYouth.NotificationApiClient.create === 'function'
            ? window.UniYouth.NotificationApiClient.create({
                loginPath: loginUrl,
                baseUrl: realtimeApiBaseUrl
            })
            : null;

        function toInt(value, fallbackValue) {
            const n = Number(value);
            if (!Number.isFinite(n)) return fallbackValue;
            return Math.floor(n);
        }

        function readUnreadCount(payload) {
            if (typeof payload === 'number') {
                return Math.max(0, toInt(payload, 0));
            }

            if (!payload || typeof payload !== 'object') {
                return null;
            }

            const keys = ['unreadCount', 'UnreadCount', 'count', 'Count'];
            for (let i = 0; i < keys.length; i++) {
                const key = keys[i];
                if (Object.prototype.hasOwnProperty.call(payload, key)) {
                    return Math.max(0, toInt(payload[key], 0));
                }
            }

            return null;
        }

        function readNotifications(payload) {
            const notifications = getFirstValue(payload, ['notifications', 'Notifications']);
            return Array.isArray(notifications) ? notifications : null;
        }

        function getFirstValue(payload, keys) {
            if (!payload || typeof payload !== 'object') {
                return undefined;
            }

            for (let i = 0; i < keys.length; i++) {
                const key = keys[i];
                if (Object.prototype.hasOwnProperty.call(payload, key)) {
                    return payload[key];
                }
            }

            return undefined;
        }

        function readNotificationId(payload) {
            const id = toInt(getFirstValue(payload, [
                'notificationID',
                'notificationId',
                'NotificationID',
                'NotificationId',
                'id',
                'Id'
            ]), 0);
            return id > 0 ? id : null;
        }

        function sanitizeText(value, maxLength) {
            if (typeof value !== 'string') return '';
            const cleaned = value.replace(/[\u0000-\u001F\u007F]/g, ' ').trim();
            if (!cleaned) return '';
            return cleaned.length > maxLength ? cleaned.slice(0, maxLength) : cleaned;
        }

        function readPriority(payload, storePayload) {
            const rawPriority = getFirstValue(payload, ['priority', 'Priority'])
                ?? getFirstValue(storePayload, ['priority', 'Priority']);
            return Math.max(0, toInt(rawPriority, 0));
        }

        function readNotificationType(payload, storePayload) {
            return sanitizeText(
                getFirstValue(payload, ['notificationType', 'NotificationType'])
                ?? getFirstValue(storePayload, ['notificationType', 'NotificationType']),
                100
            ).toLowerCase();
        }

        function mapToastAppearance(priority, notificationType) {
            const type = notificationType || '';
            const isErrorType = type.indexOf('error') >= 0 || type.indexOf('fail') >= 0;
            const isWarningType = type.indexOf('warn') >= 0 || type.indexOf('alert') >= 0;
            const isSuccessType = type.indexOf('success') >= 0 || type.indexOf('done') >= 0;

            if (priority >= 4 || isErrorType) {
                return {
                    levelClass: 'notification-toast-level-high',
                    iconClass: 'bi bi-exclamation-triangle-fill text-danger me-2',
                    priorityLabel: 'Ưu tiên cao',
                    delay: 11000
                };
            }

            if (priority === 3 || isWarningType) {
                return {
                    levelClass: 'notification-toast-level-medium',
                    iconClass: 'bi bi-exclamation-circle-fill text-warning me-2',
                    priorityLabel: 'Ưu tiên',
                    delay: 8000
                };
            }

            if (isSuccessType) {
                return {
                    levelClass: 'notification-toast-level-normal',
                    iconClass: 'bi bi-check-circle-fill text-success me-2',
                    priorityLabel: 'Thông tin',
                    delay: 5000
                };
            }

            return {
                levelClass: 'notification-toast-level-normal',
                iconClass: 'bi bi-bell-fill text-primary me-2',
                priorityLabel: 'Thông tin',
                delay: 5000
            };
        }

        function formatTimeLabel(value) {
            if (!value || typeof value !== 'string') {
                return 'Vừa xong';
            }

            const parsed = new Date(value);
            if (Number.isNaN(parsed.getTime())) {
                return 'Vừa xong';
            }

            return parsed.toLocaleTimeString('vi-VN', {
                hour: '2-digit',
                minute: '2-digit'
            });
        }

        function cleanupRecentToastKeys() {
            const now = Date.now();
            recentToastKeys.forEach(function (time, key) {
                if (now - time > TOAST_DEDUPE_TTL_MS) {
                    recentToastKeys.delete(key);
                }
            });

            while (recentToastKeys.size > TOAST_MAX_TRACKED_KEYS) {
                const oldestKey = recentToastKeys.keys().next().value;
                if (!oldestKey) {
                    break;
                }
                recentToastKeys.delete(oldestKey);
            }
        }

        function trimVisibleToasts() {
            if (!toastContainer) return;

            const visibleToasts = toastContainer.querySelectorAll('.notification-toast');
            const overflow = visibleToasts.length - TOAST_MAX_VISIBLE + 1;
            if (overflow <= 0) {
                return;
            }

            for (let i = 0; i < overflow; i++) {
                const toastEl = visibleToasts[i];
                if (!toastEl) continue;

                const existingToast = (typeof bootstrap !== 'undefined' && bootstrap.Toast)
                    ? bootstrap.Toast.getInstance(toastEl)
                    : null;

                if (existingToast && typeof existingToast.dispose === 'function') {
                    existingToast.dispose();
                }
                toastEl.remove();
            }
        }

        function getToastPayloadFromStore(notificationId) {
            if (!notificationId || !stateStore || typeof stateStore.getState !== 'function') {
                return null;
            }

            const snapshot = stateStore.getState();
            if (!snapshot || !Array.isArray(snapshot.notifications)) {
                return null;
            }

            return snapshot.notifications.find(function (item) {
                const id = readNotificationId(item);
                return id === notificationId;
            }) || null;
        }

        function buildToastData(args) {
            if (!args || !args.payload || typeof args.payload !== 'object') {
                return null;
            }

            const eventName = String(args.eventName || '');
            const isCreateEvent = eventName === 'notification_created' || eventName === 'ReceiveNotification';
            if (!isCreateEvent) {
                return null;
            }

            const payload = args.payload;
            const notificationId = readNotificationId(payload);
            const storePayload = getToastPayloadFromStore(notificationId);

            const title = sanitizeText(
                getFirstValue(payload, ['title', 'Title']) ?? getFirstValue(storePayload, ['title', 'Title']),
                250
            );
            const content = sanitizeText(
                getFirstValue(payload, ['content', 'Content']) ?? getFirstValue(storePayload, ['content', 'Content']),
                500
            );
            const createdDate = getFirstValue(payload, ['createdDate', 'CreatedDate'])
                ?? getFirstValue(storePayload, ['createdDate', 'CreatedDate']);
            const priority = readPriority(payload, storePayload);
            const notificationType = readNotificationType(payload, storePayload);
            const appearance = mapToastAppearance(priority, notificationType);

            const dedupeKey = notificationId
                ? 'id_' + notificationId
                : 'content_' + title + '_' + content + '_' + String(createdDate || '');

            return {
                dedupeKey: dedupeKey,
                title: title || 'Thông báo mới',
                content: content,
                timeLabel: formatTimeLabel(createdDate),
                priorityLabel: appearance.priorityLabel,
                delay: appearance.delay,
                levelClass: appearance.levelClass,
                iconClass: appearance.iconClass
            };
        }

        function showRealtimeToast(args) {
            if (!toastContainer || typeof bootstrap === 'undefined' || !bootstrap.Toast) {
                return;
            }

            const toastData = buildToastData(args);
            if (!toastData) {
                return;
            }

            cleanupRecentToastKeys();
            if (recentToastKeys.has(toastData.dedupeKey)) {
                return;
            }
            recentToastKeys.set(toastData.dedupeKey, Date.now());
            trimVisibleToasts();

            const toastEl = document.createElement('div');
            toastEl.className = 'toast border-0 shadow-sm notification-toast ' + toastData.levelClass;
            toastEl.setAttribute('role', 'status');
            toastEl.setAttribute('aria-live', 'polite');
            toastEl.setAttribute('aria-atomic', 'true');

            const header = document.createElement('div');
            header.className = 'toast-header notification-toast-header';

            const icon = document.createElement('i');
            icon.className = toastData.iconClass;
            header.appendChild(icon);

            const title = document.createElement('strong');
            title.className = 'me-auto notification-toast-title';
            title.textContent = toastData.title;
            header.appendChild(title);

            const priority = document.createElement('span');
            priority.className = 'notification-toast-priority';
            priority.textContent = toastData.priorityLabel;
            header.appendChild(priority);

            const time = document.createElement('small');
            time.className = 'text-muted ms-2';
            time.textContent = toastData.timeLabel;
            header.appendChild(time);

            const closeBtn = document.createElement('button');
            closeBtn.type = 'button';
            closeBtn.className = 'btn-close ms-2 mb-1';
            closeBtn.setAttribute('data-bs-dismiss', 'toast');
            closeBtn.setAttribute('aria-label', 'Close');
            header.appendChild(closeBtn);

            toastEl.appendChild(header);

            if (toastData.content) {
                const body = document.createElement('div');
                body.className = 'toast-body';
                body.textContent = toastData.content;
                toastEl.appendChild(body);
            }

            toastContainer.appendChild(toastEl);
            const toastInstance = new bootstrap.Toast(toastEl, {
                autohide: true,
                delay: toastData.delay
            });

            toastEl.addEventListener('hidden.bs.toast', function () {
                toastEl.remove();
            }, { once: true });

            toastInstance.show();
        }

        async function syncUnreadCount() {
            if (!unreadUrl || !stateStore || typeof stateStore.setUnreadCount !== 'function') {
                return;
            }

            if (realtimeApiClient && typeof realtimeApiClient.getUnreadCount === 'function') {
                const result = await realtimeApiClient.getUnreadCount();
                if (!result || result.success !== true) {
                    return;
                }

                const unread = readUnreadCount(result.data);
                if (unread !== null) {
                    stateStore.setUnreadCount(unread, 'signalr_resync_unread');
                }
                return;
            }

            let response;
            try {
                response = await fetch(unreadUrl, {
                    method: 'GET',
                    headers: { 'Accept': 'application/json' }
                });
            } catch {
                return;
            }

            if (response.redirected && response.url && response.url.toLowerCase().indexOf('/account/login') >= 0) {
                return;
            }

            if (response.status === 401 || response.status === 403 || !response.ok) {
                return;
            }

            let payload;
            try {
                payload = await response.json();
            } catch {
                return;
            }

            if (!payload || payload.success !== true) {
                return;
            }

            const unread = readUnreadCount(payload.data);
            if (unread !== null) {
                stateStore.setUnreadCount(unread, 'signalr_resync_unread');
            }
        }

        async function syncNotificationSnapshot(reason) {
            if (snapshotSyncInProgress) {
                snapshotSyncPending = true;
                return;
            }

            snapshotSyncInProgress = true;
            try {
                let unreadSyncedFromList = false;

                if (realtimeApiClient && typeof realtimeApiClient.getList === 'function' && stateStore) {
                    const listResult = await realtimeApiClient.getList(1, listPageSize);
                    if (listResult && listResult.success === true && listResult.data && typeof listResult.data === 'object') {
                        const listItems = readNotifications(listResult.data);
                        if (listItems && typeof stateStore.setNotifications === 'function') {
                            stateStore.setNotifications(listItems, 'signalr_resync_list_' + (reason || 'default'));
                        }

                        const unreadFromList = readUnreadCount(listResult.data);
                        if (unreadFromList !== null && typeof stateStore.setUnreadCount === 'function') {
                            stateStore.setUnreadCount(unreadFromList, 'signalr_resync_unread_from_list_' + (reason || 'default'));
                            unreadSyncedFromList = true;
                        }
                    }
                }

                if (!unreadSyncedFromList) {
                    await syncUnreadCount();
                }
            } finally {
                snapshotSyncInProgress = false;
                if (snapshotSyncPending) {
                    snapshotSyncPending = false;
                    syncNotificationSnapshot('queued');
                }
            }
        }

        const realtimeClient = signalRClientFactory.getOrCreate({
            loginPath: loginUrl,
            redirectOnAuthExpired: true,
            hubUrl: hubUrl || undefined
        });

        if (!realtimeClient || typeof realtimeClient.start !== 'function') {
            return;
        }

        window.UniYouth = window.UniYouth || {};
        window.UniYouth.__notificationRealtimeInitialized = true;

        if (typeof realtimeClient.on === 'function') {
            realtimeClient.on('notification', function (args) {
                if (!args || !args.payload) {
                    return;
                }

                const unread = readUnreadCount(args.payload);
                if (unread !== null && stateStore && typeof stateStore.setUnreadCount === 'function') {
                    stateStore.setUnreadCount(unread, 'signalr_event_unread');
                }

                showRealtimeToast(args);
            });

            realtimeClient.on('reconnected', function () {
                syncNotificationSnapshot('reconnected');
            });
        }

        const disposeRealtime = function () {
            if (disposed) return;
            disposed = true;

            if (typeof realtimeClient.dispose === 'function') {
                realtimeClient.dispose().finally(function () {
                    if (typeof signalRClientFactory.resetSingleton === 'function') {
                        signalRClientFactory.resetSingleton();
                    }
                });
            }
        };

        document.querySelectorAll('form[action*="/Account/Logout"], form[action*="/account/logout"]').forEach(function (form) {
            form.addEventListener('submit', disposeRealtime);
        });
        window.addEventListener('beforeunload', disposeRealtime, { once: true });

        realtimeClient.start().then(function (started) {
            if (started === true) {
                syncNotificationSnapshot('started');
            }
        });
    }

    initNotificationTopbarDropdown();
    initNotificationRealtime();

    // ============================================
    // Debug console log
    // ============================================
    console.log('UniYouth Admin JavaScript loaded successfully');
    console.log('Sidebar state:', sidebar.classList.contains('toggled') ? 'Collapsed' : 'Expanded');

})();

