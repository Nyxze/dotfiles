pragma Singleton

import Quickshell

Singleton {
    function resolve(callback) {
        callback(Quickshell.screens.length > 0 ? Quickshell.screens[0] : null);
    }
}
