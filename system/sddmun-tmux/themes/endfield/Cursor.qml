pragma Singleton

import QtQuick

// The one highlight on screen, shared by the mouse and the keyboard.
// Interactive components paint themselves from `item === <their own root>`
// rather than from their own `containsMouse`, and write themselves here when
// hovered, so a single row is lit at any moment.
QtObject {
    // Null means no highlight at all, which is what the greeter comes up with:
    // a stray keypress must not act on whatever happened to be first.
    property var item: null
}
