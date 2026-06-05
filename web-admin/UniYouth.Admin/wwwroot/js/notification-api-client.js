(function () {
    'use strict';

    function toInt(value, fallbackValue) {
        const n = Number(value);
        if (!Number.isFinite(n)) return fallbackValue;
        return Math.floor(n);
    }

    function getCurrentReturnUrl() {
        if (typeof window === 'undefined' || !window.location) {
            return '/';
        }

        return (window.location.pathname || '/')
            + (window.location.search || '')
            + (window.location.hash || '');
    }

    function buildLoginUrl(loginPath, message) {
        const path = loginPath || '/Account/Login';

        try {
            const url = new URL(path, window.location.origin);
            url.searchParams.set('returnUrl', getCurrentReturnUrl());

            if (message) {
                url.searchParams.set('message', message);
            }

            return url.pathname + url.search;
        } catch {
            const hasQuery = path.indexOf('?') >= 0;
            const encodedMessage = encodeURIComponent(message || '');
            const encodedReturnUrl = encodeURIComponent(getCurrentReturnUrl());
            const separator = hasQuery ? '&' : '?';

            if (encodedMessage) {
                return `${path}${separator}returnUrl=${encodedReturnUrl}&message=${encodedMessage}`;
            }

            return `${path}${separator}returnUrl=${encodedReturnUrl}`;
        }
    }

    function redirectToLogin(loginPath, message) {
        if (typeof window === 'undefined' || !window.location) {
            return;
        }

        const currentPath = (window.location.pathname || '').toLowerCase();
        if (currentPath.startsWith('/account/login')) {
            return;
        }

        const targetUrl = buildLoginUrl(loginPath, message);
        window.location.assign(targetUrl);
    }

    function isLoginUrl(urlValue) {
        if (!urlValue) return false;

        try {
            const url = new URL(urlValue, window.location.origin);
            return url.pathname.toLowerCase().startsWith('/account/login');
        } catch {
            return urlValue.toLowerCase().indexOf('/account/login') >= 0;
        }
    }

    function isAccessDeniedUrl(urlValue) {
        if (!urlValue) return false;

        try {
            const url = new URL(urlValue, window.location.origin);
            return url.pathname.toLowerCase().startsWith('/account/accessdenied');
        } catch {
            return urlValue.toLowerCase().indexOf('/account/accessdenied') >= 0;
        }
    }

    async function parseJsonSafe(response) {
        try {
            return await response.json();
        } catch {
            return null;
        }
    }

    function normalizeResult(response, payload, fallbackMessage, forcedStatusCode) {
        const statusCode = Number.isInteger(forcedStatusCode) ? forcedStatusCode : response.status;
        const payloadMessage = payload && typeof payload.message === 'string' ? payload.message : '';
        const payloadData = payload && Object.prototype.hasOwnProperty.call(payload, 'data') ? payload.data : null;

        const result = {
            success: false,
            message: payloadMessage || fallbackMessage || 'Request failed.',
            data: payloadData,
            statusCode: statusCode,
            isUnauthorized: statusCode === 401,
            isForbidden: statusCode === 403,
            redirectedToLogin: false
        };

        if (payload && typeof payload.success === 'boolean') {
            result.success = payload.success;
            if (!payloadMessage && payload.success) {
                result.message = '';
            }
        } else if (response.ok && !result.isUnauthorized && !result.isForbidden) {
            result.success = true;
            result.message = '';
            result.data = payload;
        }

        if (result.isUnauthorized || result.isForbidden) {
            result.success = false;
        }

        return result;
    }

    function handleUnauthorized(cfg, result) {
        let shouldRedirect = cfg.redirectOnAuthExpired !== false;

        if (typeof cfg.onAuthExpired === 'function') {
            try {
                const callbackResult = cfg.onAuthExpired(result);
                if (callbackResult === false) {
                    shouldRedirect = false;
                }
            } catch {
                // Ignore callback errors.
            }
        }

        if (shouldRedirect) {
            const message = result.message || 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
            redirectToLogin(cfg.loginPath, message);
            result.redirectedToLogin = true;
        }
    }

    function handleForbidden(cfg, result) {
        if (typeof cfg.onForbidden === 'function') {
            try {
                cfg.onForbidden(result);
            } catch {
                // Ignore callback errors.
            }
        }
    }

    function createClient(options) {
        const cfg = options || {};
        const baseUrl = (cfg.baseUrl || '/Notifications/ajax').replace(/\/+$/, '');

        async function request(path, method, fallbackMessage) {
            let response;
            try {
                response = await fetch(baseUrl + path, {
                    method: method,
                    headers: {
                        'Accept': 'application/json'
                    }
                });
            } catch {
                return {
                    success: false,
                    message: fallbackMessage || 'Request failed.',
                    data: null,
                    statusCode: 0,
                    isUnauthorized: false,
                    isForbidden: false,
                    redirectedToLogin: false
                };
            }

            if (response.redirected && isLoginUrl(response.url)) {
                const redirectedResult = normalizeResult(response, null, fallbackMessage, 401);
                redirectedResult.isUnauthorized = true;
                redirectedResult.redirectedToLogin = true;
                handleUnauthorized(cfg, redirectedResult);
                return redirectedResult;
            }

            const payload = await parseJsonSafe(response);
            const result = normalizeResult(response, payload, fallbackMessage);

            if (!result.isForbidden && response.redirected && isAccessDeniedUrl(response.url)) {
                result.isForbidden = true;
                result.success = false;
                result.statusCode = 403;
            }

            if (result.isUnauthorized) {
                handleUnauthorized(cfg, result);
            } else if (result.isForbidden) {
                handleForbidden(cfg, result);
            }

            return result;
        }

        return {
            async getList(pageNumber, pageSize) {
                const page = Math.max(1, toInt(pageNumber, 1));
                const size = Math.max(1, toInt(pageSize, 20));
                return await request(
                    `/list?pageNumber=${encodeURIComponent(page)}&pageSize=${encodeURIComponent(size)}`,
                    'GET',
                    'Không thể tải danh sách thông báo.'
                );
            },

            async getUnreadCount() {
                return await request(
                    '/unread-count',
                    'GET',
                    'Không thể tải số thông báo chưa đọc.'
                );
            },

            async markAsRead(notificationId) {
                const id = Math.max(0, toInt(notificationId, 0));
                return await request(
                    `/${encodeURIComponent(id)}/read`,
                    'PUT',
                    'Không thể đánh dấu thông báo đã đọc.'
                );
            },

            async markAllAsRead() {
                return await request(
                    '/read-all',
                    'PUT',
                    'Không thể đánh dấu tất cả thông báo đã đọc.'
                );
            }
        };
    }

    window.UniYouth = window.UniYouth || {};
    window.UniYouth.NotificationApiClient = {
        create: createClient
    };
})();
