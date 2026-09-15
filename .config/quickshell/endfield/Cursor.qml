pragma Singleton

import Quickshell
import QtQuick

// The one highlight on screen, shared by the mouse and the keyboard.
//
// Interactive components paint themselves from `item === <their own root>`
// rather than from their own `containsMouse`, and write themselves here when
// hovered. That is what keeps a single row lit at any moment: moving the mouse
// picks the cursor up, and the next arrow key carries on from there instead of
// jumping back to the top of the list.
Singleton {
    id: root

    // Null means no highlight at all — a freshly opened panel shows nothing,
    // so a stray keypress cannot act on whatever happened to be first.
    property var item: null

    // Where the cursor sat in the panel's ordered list, so a list that
    // rebuilds underneath it (a Wi-Fi scan replaces every delegate) can put it
    // back at the same position instead of dropping it.
    property int index: -1

    // Set while a text field owns the keyboard, so the panel's key handler
    // lets "j" reach a passphrase instead of moving down a row.
    property bool editing: false

    function clear() {
        item = null;
        index = -1;
    }
}
