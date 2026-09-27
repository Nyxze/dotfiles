pragma Singleton

import Quickshell
import Quickshell.Services.Notifications

// Owns org.freedesktop.Notifications. Only one process on the session can, so
// nothing else may run a notification daemon alongside this.
//
// Two lists, deliberately: `history` is everything still tracked, `popups` is
// the subset currently on screen as a toast. A toast timing out leaves history
// untouched; dismissing drops it from both.
Singleton {
    id: root

    property bool doNotDisturb: false
    property var popupIds: []
    property var historyIds: []

    property var notifications: ({})
    property int nextSerial: 1

    readonly property var history: server.trackedNotifications

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        actionIconsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        bodyImagesSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notification => {
            // Untracked notifications are destroyed immediately.
            notification.tracked = true;

            const id = notification.id;
            const serial = root.nextSerial++;
            const record = { notification, serial };

            notification.closed.connect(() => root.retire(id, serial));

            // Repeater rows stay primitive. Publishing the native object from
            // inside this signal can invalidate it while Qt builds a delegate.
            Qt.callLater(() => root.publish(id, record));
        }
    }

    function appendUnique(values, id) {
        return values.includes(id) ? values : values.concat([id]);
    }

    function without(values, id) {
        return values.filter(candidate => candidate !== id);
    }

    function publish(id, record) {
        if (!record.notification)
            return;

        const next = Object.assign({}, notifications);
        next[id] = record;
        notifications = next;
        historyIds = appendUnique(historyIds, id);

        if (!doNotDisturb)
            popupIds = appendUnique(popupIds, id);
    }

    function retire(id, serial) {
        Qt.callLater(() => {
            const record = notifications[id];
            if (!record || record.serial !== serial)
                return;

            popupIds = without(popupIds, id);
            historyIds = without(historyIds, id);

            Qt.callLater(() => {
                const current = notifications[id];
                if (!current || current.serial !== serial)
                    return;
                const next = Object.assign({}, notifications);
                delete next[id];
                notifications = next;
            });
        });
    }

    function notificationFor(id) {
        const record = notifications[id];
        return record ? record.notification : null;
    }

    // Take it off screen but keep it in history.
    function dropPopup(id) {
        popupIds = without(popupIds, id);
    }

    function dismiss(id) {
        const notification = notificationFor(id);
        dropPopup(id);
        historyIds = without(historyIds, id);

        if (!notification)
            return;
        notification.dismiss();
    }

    function clearHistory() {
        const all = history.values.slice();
        popupIds = [];
        historyIds = [];
        for (const notification of all)
            notification.dismiss();
    }
}
