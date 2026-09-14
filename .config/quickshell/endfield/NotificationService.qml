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
    property var popups: []

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

            if (!root.doNotDisturb)
                root.popups = root.popups.concat([notification]);
        }
    }

    // Take it off screen but keep it in history.
    function dropPopup(notification) {
        popups = popups.filter(popup => popup !== notification);
    }

    function dismiss(notification) {
        dropPopup(notification);
        notification.dismiss();
    }

    function clearHistory() {
        const all = history.values.slice();
        popups = [];
        for (const notification of all)
            notification.dismiss();
    }
}
