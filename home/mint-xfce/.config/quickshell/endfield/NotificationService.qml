pragma Singleton

import Quickshell

// Xfce owns org.freedesktop.Notifications in this profile. The sidebar keeps
// the same interface but does not compete for the D-Bus name.
Singleton {
    property bool doNotDisturb: false
    property var popupIds: []
    property var historyIds: []

    function notificationFor() { return null; }
    function dropPopup() {}
    function dismiss() {}
    function clearHistory() {}
}
