(function () {
    'use strict';

    const DEFAULT_RECONNECT_DELAYS = [0, 2000, 5000, 10000, 30000];
    const ALLOWED_ACTION_ROUTE_PREFIXES = [
        '/account',
        '/attendance',
        '/events',
        '/home',
        '/notifications',
        '/points',
        '/qrcodes',
        '/registrations',
        '/reports',
        '/roles',
        '/support-chat',
        '/units',
        '/users'
    ];
    let singletonClient = null;

    function toIntOrNull(value) {
        const n = Number(value);
        if (!Number.isFinite(n)) return null;
        return Math.floor(n);
    }

    function readUnreadCount(payload) {
        if (payload == null) return null;
        if (typeof payload === 'number') return toIntOrNull(payload);
        if (typeof payload !== 'object') return null;

        const keys = ['unreadCount', 'UnreadCount', 'count', 'Count'];
        for (let i = 0; i < keys.length; i++) {
            const key = keys[i];
            if (Object.prototype.hasOwnProperty.call(payload, key)) {
                return toIntOrNull(payload[key]);
            }
        }

        return null;
    }

    function readNotificationId(payload) {
        if (!payload || typeof payload !== 'object') return null;
        const candidates = ['notificationID', 'notificationId', 'NotificationID', 'NotificationId', 'id', 'Id'];
        for (let i = 0; i < candidates.length; i++) {
            const id = toIntOrNull(payload[candidates[i]]);
            if (id !== null && id > 0) {
                return id;
            }
        }
        return null;
    }

    function getFirstValue(payload, keys) {
        for (let i = 0; i < keys.length; i++) {
            const key = keys[i];
            if (Object.prototype.hasOwnProperty.call(payload, key)) {
                return payload[key];
            }
        }
        return undefined;
    }

    function sanitizeText(value, maxLength) {
        if (typeof value !== 'string') return '';
        const clean = value.replace(/[\u0000-\u001F\u007F]/g, ' ').trim();
        if (!clean) return '';
        if (clean.length > maxLength) {
            return clean.slice(0, maxLength);
        }
        return clean;
    }

    function sanitizeDateString(value) {
        if (typeof value !== 'string') return null;
        const timestamp = Date.parse(value);
        if (Number.isNaN(timestamp)) return null;
        return new Date(timestamp).toISOString();
    }

    function sanitizeActionUrl(actionUrl) {
        if (typeof actionUrl !== 'string') return null;

        const value = actionUrl.trim();
        if (!value || value.length > 2048) return null;

        const lower = value.toLowerCase();
        if (value.startsWith('//')) return null;
        if (lower.startsWith('javascript:') || lower.startsWith('data:') || lower.startsWith('vbscript:')) {
            return null;
        }
        if (!value.startsWith('/')) return null;

        const queryIndex = value.search(/[?#]/);
        const suffix = queryIndex >= 0 ? value.slice(queryIndex) : '';
        let pathOnly = queryIndex >= 0 ? value.slice(0, queryIndex) : value;
        pathOnly = pathOnly.replace(/\/+$/g, '') || '/';

        const eventDetailMatch = /^\/events\/(\d+)$/i.exec(pathOnly);
        if (eventDetailMatch) {
            return '/Events/Details/' + eventDetailMatch[1] + suffix;
        }

        if (pathOnly === '/') {
            return '/' + suffix.replace(/^\/+/, '');
        }

        const normalized = pathOnly.toLowerCase();
        const allowed = ALLOWED_ACTION_ROUTE_PREFIXES.some(function (prefix) {
            return normalized === prefix || normalized.startsWith(prefix + '/');
        });

        return allowed ? pathOnly + suffix : null;
    }

    function sanitizeCreatedPayload(payload) {
        if (!payload || typeof payload !== 'object') return null;

        const id = readNotificationId(payload);
        if (id === null || id <= 0) return null;

        const sanitized = {
            notificationID: id,
            notificationId: id
        };

        const title = sanitizeText(getFirstValue(payload, ['title', 'Title']), 250);
        if (title) sanitized.title = title;

        const content = sanitizeText(getFirstValue(payload, ['content', 'Content']), 2000);
        if (content) sanitized.content = content;

        const type = sanitizeText(getFirstValue(payload, ['notificationType', 'NotificationType']), 100);
        if (type) sanitized.notificationType = type;

        const priority = toIntOrNull(getFirstValue(payload, ['priority', 'Priority']));
        if (priority !== null) sanitized.priority = priority;

        const isReadValue = getFirstValue(payload, ['isRead', 'IsRead']);
        if (typeof isReadValue === 'boolean') sanitized.isRead = isReadValue;

        const actionUrl = sanitizeActionUrl(getFirstValue(payload, ['actionUrl', 'ActionUrl']));
        if (actionUrl) sanitized.actionUrl = actionUrl;

        const eventId = toIntOrNull(getFirstValue(payload, ['eventID', 'eventId', 'EventID', 'EventId']));
        if (eventId !== null && eventId > 0) {
            sanitized.eventID = eventId;
            sanitized.eventId = eventId;
        }

        const eventName = sanitizeText(getFirstValue(payload, ['eventName', 'EventName']), 250);
        if (eventName) sanitized.eventName = eventName;

        const createdDate = sanitizeDateString(getFirstValue(payload, ['createdDate', 'CreatedDate']));
        if (createdDate) sanitized.createdDate = createdDate;

        const readDate = sanitizeDateString(getFirstValue(payload, ['readDate', 'ReadDate']));
        if (readDate) sanitized.readDate = readDate;

        const expiryDate = sanitizeDateString(getFirstValue(payload, ['expiryDate', 'ExpiryDate']));
        if (expiryDate) sanitized.expiryDate = expiryDate;

        const unreadCount = readUnreadCount(payload);
        if (unreadCount !== null) sanitized.unreadCount = unreadCount;

        return sanitized;
    }

    function sanitizeReadPayload(payload) {
        if (!payload || typeof payload !== 'object') return null;

        const id = readNotificationId(payload);
        const unreadCount = readUnreadCount(payload);

        if ((id === null || id <= 0) && unreadCount === null) {
            return null;
        }

        const sanitized = {};
        if (id !== null && id > 0) {
            sanitized.notificationID = id;
            sanitized.notificationId = id;
            sanitized.id = id;
        }
        if (unreadCount !== null) {
            sanitized.unreadCount = unreadCount;
        }

        return sanitized;
    }

    function sanitizeReadAllPayload(payload) {
        if (payload == null) return {};
        if (typeof payload !== 'object') return {};

        const unreadCount = readUnreadCount(payload);
        if (unreadCount === null) return {};
        return { unreadCount: unreadCount };
    }

    function sanitizeRealtimePayload(eventName, payload, events) {
        if (eventName === events.created || eventName === events.fallbackCreated) {
            return sanitizeCreatedPayload(payload);
        }

        if (eventName === events.read) {
            return sanitizeReadPayload(payload);
        }

        if (eventName === events.readAll) {
            return sanitizeReadAllPayload(payload);
        }

        return null;
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

    function readErrorMessage(error) {
        if (!error) return '';
        if (typeof error === 'string') return error;
        if (typeof error.message === 'string') return error.message;

        try {
            return String(error);
        } catch {
            return '';
        }
    }

    function isAuthError(error) {
        const text = readErrorMessage(error).toLowerCase();
        if (!text) return false;

        if (text.indexOf('401') >= 0 || text.indexOf('unauthor') >= 0) {
            return true;
        }

        if (text.indexOf('403') >= 0 || text.indexOf('forbidden') >= 0) {
            return true;
        }

        if (text.indexOf('token') >= 0 && text.indexOf('expired') >= 0) {
            return true;
        }

        return false;
    }

    function createClient(options) {
        const cfg = options || {};
        const hubUrl = cfg.hubUrl || '/hubs/notifications';
        const reconnectDelays = Array.isArray(cfg.reconnectDelays) && cfg.reconnectDelays.length > 0
            ? cfg.reconnectDelays
            : DEFAULT_RECONNECT_DELAYS;
        const events = Object.assign({
            created: 'notification_created',
            read: 'notification_read',
            readAll: 'notification_read_all',
            fallbackCreated: 'ReceiveNotification'
        }, cfg.events || {});

        const hasSignalR = !!(window.signalR && window.signalR.HubConnectionBuilder);
        const stateStore = window.UniYouth && window.UniYouth.NotificationStateStore
            ? window.UniYouth.NotificationStateStore
            : null;

        const callbacks = {
            started: new Set(),
            stopped: new Set(),
            reconnecting: new Set(),
            reconnected: new Set(),
            close: new Set(),
            notification: new Set(),
            error: new Set(),
            authExpired: new Set()
        };

        let connection = null;
        let startingPromise = null;
        let disposed = false;
        let bridgeHandlers = [];
        let authExpiredHandled = false;

        function emit(eventName, payload) {
            const set = callbacks[eventName];
            if (!set) return;
            set.forEach(function (cb) {
                try {
                    cb(payload);
                } catch {
                    // Ignore subscriber errors to keep realtime loop running.
                }
            });
        }

        function handleAuthExpired(error, source) {
            if (authExpiredHandled) {
                return;
            }
            authExpiredHandled = true;

            if (stateStore) {
                stateStore.reset('auth_expired');
            }

            const message = readErrorMessage(error) || 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
            emit('authExpired', {
                source: source || 'signalr',
                message: message,
                error: error || null
            });

            if (connection && !disposed) {
                try {
                    connection.stop();
                } catch {
                    // Ignore stop errors when auth is expired.
                }
            }

            let shouldRedirect = cfg.redirectOnAuthExpired !== false;
            if (typeof cfg.onAuthExpired === 'function') {
                try {
                    const callbackResult = cfg.onAuthExpired({
                        source: source || 'signalr',
                        message: message,
                        error: error || null
                    });
                    if (callbackResult === false) {
                        shouldRedirect = false;
                    }
                } catch {
                    // Ignore callback errors.
                }
            }

            if (shouldRedirect) {
                redirectToLogin(cfg.loginPath, message);
            }
        }

        function applyPayloadToStateStore(eventName, payload) {
            if (!stateStore) return;

            const unread = readUnreadCount(payload);
            if (unread !== null) {
                stateStore.setUnreadCount(unread, 'realtime_unread_count');
            }

            if (eventName === events.created || eventName === events.fallbackCreated) {
                stateStore.upsertNotification(payload, 'realtime_created');
                return;
            }

            if (eventName === events.read) {
                const id = readNotificationId(payload);
                if (id !== null) {
                    stateStore.markAsRead(id, 'realtime_read');
                }
                return;
            }

            if (eventName === events.readAll) {
                stateStore.markAllAsRead('realtime_read_all');
            }
        }

        function attachRealtimeBridges() {
            if (!connection) return;

            const eventNames = [events.created, events.read, events.readAll, events.fallbackCreated]
                .filter(function (value, index, arr) {
                    return typeof value === 'string' && value.trim() && arr.indexOf(value) === index;
                });

            bridgeHandlers = eventNames.map(function (eventName) {
                const handler = function (payload) {
                    const sanitizedPayload = sanitizeRealtimePayload(eventName, payload, events);
                    if (eventName !== events.readAll && !sanitizedPayload) {
                        return;
                    }

                    const payloadForProcessing = sanitizedPayload || {};
                    applyPayloadToStateStore(eventName, payloadForProcessing);
                    emit('notification', { eventName: eventName, payload: payloadForProcessing });
                };
                connection.on(eventName, handler);
                return { eventName: eventName, handler: handler };
            });
        }

        function detachRealtimeBridges() {
            if (!connection || !Array.isArray(bridgeHandlers)) return;
            bridgeHandlers.forEach(function (item) {
                try {
                    connection.off(item.eventName, item.handler);
                } catch {
                    // no-op
                }
            });
            bridgeHandlers = [];
        }

        function buildConnection() {
            if (!hasSignalR || connection || disposed) return;

            connection = new window.signalR.HubConnectionBuilder()
                .withUrl(hubUrl, {
                    accessTokenFactory: function () {
                        if (typeof cfg.accessTokenFactory === 'function') {
                            const token = cfg.accessTokenFactory();
                            return token || '';
                        }
                        return '';
                    }
                })
                .withAutomaticReconnect(reconnectDelays)
                .build();

            connection.onreconnecting(function (error) {
                emit('reconnecting', error || null);
                if (isAuthError(error)) {
                    handleAuthExpired(error, 'reconnecting');
                }
            });

            connection.onreconnected(function (connectionId) {
                emit('reconnected', connectionId || null);
            });

            connection.onclose(function (error) {
                emit('close', error || null);
                if (isAuthError(error)) {
                    handleAuthExpired(error, 'close');
                }
            });

            attachRealtimeBridges();
        }

        async function start() {
            if (disposed || !hasSignalR) return false;
            buildConnection();
            if (!connection) return false;

            if (connection.state === window.signalR.HubConnectionState.Connected) {
                return true;
            }

            if (startingPromise) {
                return await startingPromise;
            }

            startingPromise = (async function () {
                try {
                    await connection.start();
                    authExpiredHandled = false;
                    emit('started', null);
                    return true;
                } catch (error) {
                    emit('error', error || null);
                    if (isAuthError(error)) {
                        handleAuthExpired(error, 'start');
                    }
                    return false;
                } finally {
                    startingPromise = null;
                }
            })();

            return await startingPromise;
        }

        async function stop() {
            if (!connection) return;

            try {
                await connection.stop();
                emit('stopped', null);
            } catch (error) {
                emit('error', error || null);
            }
        }

        async function dispose() {
            if (disposed) return;
            disposed = true;

            if (startingPromise) {
                try { await startingPromise; } catch { }
            }

            detachRealtimeBridges();
            await stop();

            connection = null;
            callbacks.started.clear();
            callbacks.stopped.clear();
            callbacks.reconnecting.clear();
            callbacks.reconnected.clear();
            callbacks.close.clear();
            callbacks.notification.clear();
            callbacks.error.clear();
            callbacks.authExpired.clear();
        }

        function on(eventName, callback) {
            if (!callbacks[eventName] || typeof callback !== 'function') {
                return function () { };
            }

            callbacks[eventName].add(callback);
            return function unsubscribe() {
                callbacks[eventName].delete(callback);
            };
        }

        function isConnected() {
            if (!hasSignalR || !connection) return false;
            return connection.state === window.signalR.HubConnectionState.Connected;
        }

        function getState() {
            return {
                disposed: disposed,
                hasSignalR: hasSignalR,
                isConnected: isConnected(),
                connectionState: connection ? connection.state : 'NotInitialized',
                hubUrl: hubUrl
            };
        }

        return {
            start: start,
            stop: stop,
            dispose: dispose,
            on: on,
            isConnected: isConnected,
            getState: getState
        };
    }

    function getOrCreate(options) {
        if (!singletonClient) {
            singletonClient = createClient(options);
        }
        return singletonClient;
    }

    function resetSingleton() {
        singletonClient = null;
    }

    window.UniYouth = window.UniYouth || {};
    window.UniYouth.NotificationSignalRClient = {
        create: createClient,
        getOrCreate: getOrCreate,
        resetSingleton: resetSingleton
    };
})();

