(function () {
    'use strict';

    const root = document.querySelector('[data-support-chat-realtime]');
    if (!root || !window.signalR || !window.signalR.HubConnectionBuilder) {
        return;
    }

    const hubUrl = (root.getAttribute('data-hub-url') || '').trim();
    const tokenUrl = (root.getAttribute('data-token-url') || '').trim();
    const mode = (root.getAttribute('data-support-chat-realtime') || '').trim();
    const conversationId = Number.parseInt(root.getAttribute('data-conversation-id') || '0', 10) || 0;

    if (!hubUrl || !tokenUrl) {
        return;
    }

    let cachedToken = null;
    let tokenFetchedAt = 0;
    const tokenTtlMs = 4 * 60 * 1000;

    async function getAccessToken() {
        const now = Date.now();
        if (cachedToken && now - tokenFetchedAt < tokenTtlMs) {
            return cachedToken;
        }

        const response = await fetch(tokenUrl, {
            method: 'GET',
            headers: { 'Accept': 'application/json' },
            credentials: 'same-origin'
        });

        if (!response.ok) {
            return '';
        }

        const payload = await response.json();
        cachedToken = payload && payload.success === true && typeof payload.token === 'string'
            ? payload.token
            : '';
        tokenFetchedAt = now;
        return cachedToken;
    }

    function readConversationId(payload) {
        if (!payload || typeof payload !== 'object') {
            return 0;
        }

        const keys = ['conversationId', 'conversationID', 'ConversationId', 'ConversationID'];
        for (let i = 0; i < keys.length; i++) {
            const value = Number.parseInt(payload[keys[i]], 10);
            if (Number.isFinite(value) && value > 0) {
                return value;
            }
        }

        return 0;
    }

    function showBanner() {
        root.classList.remove('d-none');
        root.classList.add('d-flex');
    }

    function shouldShowForPayload(payload) {
        if (mode !== 'detail' || conversationId <= 0) {
            return true;
        }

        return readConversationId(payload) === conversationId;
    }

    const reloadButton = root.querySelector('[data-support-chat-reload]');
    if (reloadButton) {
        reloadButton.addEventListener('click', function () {
            window.location.reload();
        });
    }

    const connection = new window.signalR.HubConnectionBuilder()
        .withUrl(hubUrl, {
            accessTokenFactory: getAccessToken
        })
        .withAutomaticReconnect([0, 2000, 5000, 10000, 30000])
        .build();

    connection.on('support_conversation_created', function (payload) {
        if (shouldShowForPayload(payload)) {
            showBanner();
        }
    });

    connection.on('support_conversation_updated', function (payload) {
        if (shouldShowForPayload(payload)) {
            showBanner();
        }
    });

    connection.on('support_message_created', function (payload) {
        if (shouldShowForPayload(payload)) {
            showBanner();
        }
    });

    connection.on('support_messages_read', function (payload) {
        if (shouldShowForPayload(payload)) {
            showBanner();
        }
    });

    connection.start()
        .then(function () {
            if (mode === 'detail' && conversationId > 0) {
                return connection.invoke('JoinConversation', conversationId);
            }
            return null;
        })
        .catch(function () {
            root.classList.add('d-none');
            root.classList.remove('d-flex');
        });

    window.addEventListener('beforeunload', function () {
        if (mode === 'detail' && conversationId > 0 && connection.state === window.signalR.HubConnectionState.Connected) {
            connection.invoke('LeaveConversation', conversationId).catch(function () { });
        }
    }, { once: true });
})();
