(function () {
    'use strict';

    // Lightweight in-memory store for notification state.
    // WEB-NOTI-17: add cross-tab sync by BroadcastChannel + storage fallback.
    const state = {
        unreadCount: 0,
        notifications: [],
        updatedAt: null
    };

    const subscribers = new Set();
    const SYNC_CHANNEL_NAME = 'uniyouth_notification_sync_v1';
    const SYNC_STORAGE_KEY = 'uniyouth_notification_sync_event_v1';
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
        '/units',
        '/users'
    ];
    const tabId = 'tab_' + Date.now() + '_' + Math.random().toString(36).slice(2, 8);
    const seenSyncMessageIds = new Map();
    const SEEN_SYNC_TTL_MS = 30000;

    let syncChannel = null;
    let storageListenerAttached = false;

    function cloneState() {
        return {
            unreadCount: state.unreadCount,
            notifications: state.notifications.slice(),
            updatedAt: state.updatedAt
        };
    }

    function toNumberOrZero(value) {
        const n = Number(value);
        if (!Number.isFinite(n) || n < 0) {
            return 0;
        }
        return Math.floor(n);
    }

    function getNotificationId(notification) {
        if (!notification || typeof notification !== 'object') {
            return null;
        }

        const candidates = [
            notification.notificationID,
            notification.notificationId,
            notification.NotificationID,
            notification.NotificationId,
            notification.id,
            notification.Id
        ];

        for (let i = 0; i < candidates.length; i++) {
            const value = Number(candidates[i]);
            if (Number.isFinite(value) && value > 0) {
                return Math.floor(value);
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
        if (typeof value !== 'string') {
            return '';
        }

        const cleaned = value.replace(/[\u0000-\u001F\u007F]/g, ' ').trim();
        if (!cleaned) {
            return '';
        }

        if (cleaned.length > maxLength) {
            return cleaned.slice(0, maxLength);
        }

        return cleaned;
    }

    function sanitizeActionUrl(actionUrl) {
        if (typeof actionUrl !== 'string') {
            return null;
        }

        const value = actionUrl.trim();
        if (!value || value.length > 2048) {
            return null;
        }

        const lower = value.toLowerCase();
        if (value.startsWith('//')) {
            return null;
        }

        if (lower.startsWith('javascript:') || lower.startsWith('data:') || lower.startsWith('vbscript:')) {
            return null;
        }

        if (!value.startsWith('/')) {
            return null;
        }

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

    function sanitizeDateString(value) {
        if (typeof value !== 'string') {
            return null;
        }

        const timestamp = Date.parse(value);
        if (Number.isNaN(timestamp)) {
            return null;
        }

        return new Date(timestamp).toISOString();
    }

    function sanitizeNotification(notification) {
        if (!notification || typeof notification !== 'object') {
            return null;
        }

        const id = getNotificationId(notification);
        if (id === null || id <= 0) {
            return null;
        }

        const sanitized = Object.assign({}, notification);
        sanitized.notificationID = id;
        sanitized.notificationId = id;

        const title = sanitizeText(getFirstValue(notification, ['title', 'Title']), 250);
        sanitized.title = title || '';

        const content = sanitizeText(getFirstValue(notification, ['content', 'Content']), 2000);
        sanitized.content = content || '';

        const notificationType = sanitizeText(getFirstValue(notification, ['notificationType', 'NotificationType']), 100);
        if (notificationType) {
            sanitized.notificationType = notificationType;
        } else {
            delete sanitized.notificationType;
        }

        const priority = Number(getFirstValue(notification, ['priority', 'Priority']));
        if (Number.isFinite(priority)) {
            sanitized.priority = Math.floor(priority);
        } else {
            delete sanitized.priority;
        }

        const isRead = getFirstValue(notification, ['isRead', 'IsRead']);
        sanitized.isRead = isRead === true;

        const actionUrl = sanitizeActionUrl(getFirstValue(notification, ['actionUrl', 'ActionUrl']));
        if (actionUrl) {
            sanitized.actionUrl = actionUrl;
        } else {
            delete sanitized.actionUrl;
        }

        const eventId = Number(getFirstValue(notification, ['eventID', 'eventId', 'EventID', 'EventId']));
        if (Number.isFinite(eventId) && eventId > 0) {
            const safeEventId = Math.floor(eventId);
            sanitized.eventID = safeEventId;
            sanitized.eventId = safeEventId;
        } else {
            delete sanitized.eventID;
            delete sanitized.eventId;
        }

        const eventName = sanitizeText(getFirstValue(notification, ['eventName', 'EventName']), 250);
        if (eventName) {
            sanitized.eventName = eventName;
        } else {
            delete sanitized.eventName;
        }

        const createdDate = sanitizeDateString(getFirstValue(notification, ['createdDate', 'CreatedDate']));
        if (createdDate) {
            sanitized.createdDate = createdDate;
        } else {
            delete sanitized.createdDate;
        }

        const readDate = sanitizeDateString(getFirstValue(notification, ['readDate', 'ReadDate']));
        if (readDate) {
            sanitized.readDate = readDate;
        } else {
            delete sanitized.readDate;
        }

        const expiryDate = sanitizeDateString(getFirstValue(notification, ['expiryDate', 'ExpiryDate']));
        if (expiryDate) {
            sanitized.expiryDate = expiryDate;
        } else {
            delete sanitized.expiryDate;
        }

        return sanitized;
    }

    function notify(action) {
        const snapshot = cloneState();
        subscribers.forEach(function (cb) {
            try {
                cb(snapshot, action);
            } catch {
                // Ignore subscriber errors to keep store stable.
            }
        });
    }

    function cleanupSeenSyncMessageIds(nowMs) {
        seenSyncMessageIds.forEach(function (timestamp, messageId) {
            if (nowMs - timestamp > SEEN_SYNC_TTL_MS) {
                seenSyncMessageIds.delete(messageId);
            }
        });
    }

    function publishSync(type, payload) {
        const nowMs = Date.now();
        const message = {
            id: tabId + '_' + nowMs + '_' + Math.random().toString(36).slice(2, 8),
            version: 1,
            type: type,
            payload: payload || {},
            tabId: tabId,
            timestamp: nowMs
        };

        let sentByBroadcastChannel = false;
        if (syncChannel) {
            try {
                syncChannel.postMessage(message);
                sentByBroadcastChannel = true;
            } catch {
                // Ignore BroadcastChannel failures and fallback to storage.
            }
        }

        if (!sentByBroadcastChannel) {
            try {
                localStorage.setItem(SYNC_STORAGE_KEY, JSON.stringify(message));
                // Remove immediately to keep localStorage clean and still trigger storage event.
                localStorage.removeItem(SYNC_STORAGE_KEY);
            } catch {
                // Ignore storage failures (private mode / disabled storage).
            }
        }
    }

    function setUnreadCount(unreadCount, action, fromSync) {
        state.unreadCount = toNumberOrZero(unreadCount);
        state.updatedAt = Date.now();
        const effectiveAction = action || 'set_unread_count';
        notify(effectiveAction);

        if (!fromSync) {
            publishSync('set_unread_count', {
                unreadCount: state.unreadCount
            });
        }
    }

    function setNotifications(notifications, action, fromSync) {
        if (!Array.isArray(notifications)) {
            state.notifications = [];
        } else {
            state.notifications = notifications
                .map(sanitizeNotification)
                .filter(function (item) { return item !== null; });
        }

        state.updatedAt = Date.now();
        const effectiveAction = action || 'set_notifications';
        notify(effectiveAction);

        if (!fromSync) {
            publishSync('set_notifications', {
                notifications: state.notifications
            });
        }
    }

    function setState(payload, action, fromSync) {
        const p = payload || {};

        if (Object.prototype.hasOwnProperty.call(p, 'unreadCount')) {
            state.unreadCount = toNumberOrZero(p.unreadCount);
        }

        if (Object.prototype.hasOwnProperty.call(p, 'notifications')) {
            state.notifications = Array.isArray(p.notifications)
                ? p.notifications.map(sanitizeNotification).filter(function (item) { return item !== null; })
                : [];
        }

        state.updatedAt = Date.now();
        const effectiveAction = action || 'set_state';
        notify(effectiveAction);

        if (!fromSync) {
            publishSync('set_state', cloneState());
        }
    }

    function upsertNotification(notification, action, fromSync) {
        const sanitizedNotification = sanitizeNotification(notification);
        const id = getNotificationId(sanitizedNotification);
        if (id === null) {
            return false;
        }

        const index = state.notifications.findIndex(function (item) {
            return getNotificationId(item) === id;
        });

        if (index >= 0) {
            state.notifications[index] = Object.assign({}, state.notifications[index], sanitizedNotification);
        } else {
            state.notifications.unshift(sanitizedNotification);
        }

        state.updatedAt = Date.now();
        const effectiveAction = action || 'upsert_notification';
        notify(effectiveAction);

        if (!fromSync) {
            publishSync('upsert_notification', {
                notification: sanitizedNotification
            });
        }

        return true;
    }

    function markAsRead(notificationId, action, fromSync) {
        const id = Number(notificationId);
        if (!Number.isFinite(id) || id <= 0) {
            return false;
        }

        let changed = false;
        state.notifications = state.notifications.map(function (item) {
            if (getNotificationId(item) !== id) {
                return item;
            }

            changed = true;
            return Object.assign({}, item, { isRead: true });
        });

        if (!changed) {
            return false;
        }

        state.updatedAt = Date.now();
        const effectiveAction = action || 'mark_as_read';
        notify(effectiveAction);

        if (!fromSync) {
            publishSync('mark_as_read', {
                notificationId: id
            });
        }

        return true;
    }

    function markAllAsRead(action, fromSync) {
        state.notifications = state.notifications.map(function (item) {
            return Object.assign({}, item, { isRead: true });
        });
        state.updatedAt = Date.now();
        const effectiveAction = action || 'mark_all_as_read';
        notify(effectiveAction);

        if (!fromSync) {
            publishSync('mark_all_as_read', {});
        }
    }

    function subscribe(callback) {
        if (typeof callback !== 'function') {
            return function () { };
        }

        subscribers.add(callback);
        return function unsubscribe() {
            subscribers.delete(callback);
        };
    }

    function reset(action, fromSync) {
        state.unreadCount = 0;
        state.notifications = [];
        state.updatedAt = Date.now();
        const effectiveAction = action || 'reset';
        notify(effectiveAction);

        if (!fromSync) {
            publishSync('reset', {});
        }
    }

    function applySyncMessage(message) {
        if (!message || typeof message !== 'object') {
            return;
        }

        if (message.tabId === tabId) {
            return;
        }

        if (message.version !== 1) {
            return;
        }

        const messageId = typeof message.id === 'string' ? message.id : null;
        if (messageId) {
            const nowMs = Date.now();
            cleanupSeenSyncMessageIds(nowMs);
            if (seenSyncMessageIds.has(messageId)) {
                return;
            }
            seenSyncMessageIds.set(messageId, nowMs);
        }

        const payload = message.payload || {};
        switch (message.type) {
            case 'set_unread_count':
                setUnreadCount(payload.unreadCount, 'sync_set_unread_count', true);
                break;
            case 'set_notifications':
                setNotifications(payload.notifications, 'sync_set_notifications', true);
                break;
            case 'set_state':
                setState(payload, 'sync_set_state', true);
                break;
            case 'upsert_notification':
                upsertNotification(payload.notification, 'sync_upsert_notification', true);
                break;
            case 'mark_as_read':
                markAsRead(payload.notificationId, 'sync_mark_as_read', true);
                break;
            case 'mark_all_as_read':
                markAllAsRead('sync_mark_all_as_read', true);
                break;
            case 'reset':
                reset('sync_reset', true);
                break;
            default:
                break;
        }
    }

    function handleStorageSync(event) {
        if (!event || event.key !== SYNC_STORAGE_KEY || !event.newValue) {
            return;
        }

        try {
            const message = JSON.parse(event.newValue);
            applySyncMessage(message);
        } catch {
            // Ignore malformed storage payload.
        }
    }

    function initCrossTabSync() {
        if (typeof BroadcastChannel !== 'undefined') {
            try {
                syncChannel = new BroadcastChannel(SYNC_CHANNEL_NAME);
                syncChannel.onmessage = function (event) {
                    applySyncMessage(event ? event.data : null);
                };
            } catch {
                syncChannel = null;
            }
        }

        if (!storageListenerAttached && typeof window !== 'undefined') {
            window.addEventListener('storage', handleStorageSync);
            storageListenerAttached = true;
        }
    }

    function destroySync() {
        if (syncChannel) {
            try {
                syncChannel.close();
            } catch {
                // no-op
            }
            syncChannel = null;
        }

        if (storageListenerAttached && typeof window !== 'undefined') {
            window.removeEventListener('storage', handleStorageSync);
            storageListenerAttached = false;
        }
    }

    initCrossTabSync();

    window.UniYouth = window.UniYouth || {};
    window.UniYouth.NotificationStateStore = {
        getState: cloneState,
        setState: setState,
        setUnreadCount: setUnreadCount,
        setNotifications: setNotifications,
        upsertNotification: upsertNotification,
        markAsRead: markAsRead,
        markAllAsRead: markAllAsRead,
        subscribe: subscribe,
        reset: reset,
        destroySync: destroySync
    };
})();
