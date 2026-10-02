import ".."
import QtQuick

// Turns key presses into semantic signals so the panel that owns this keeps
// its own state machine instead of every component wiring its own keys.
Item {
    id: catcher

    signal moved(int dx, int dy)
    signal activated
    signal removed
    signal dismissed
    signal tabbed(int direction)

    focus: true
    // BeforeItem: without it an inner Flickable eats arrow keys before this
    // handler sees them.
    Keys.priority: Keys.BeforeItem

    Keys.onPressed: event => {
        // A field owns its own keys while editing, so "j" reaches it as a
        // letter rather than a move. Escape is not exempt: the field accepts
        // its own Escape before this handler ever sees it.
        if (Cursor.editing)
            return;

        switch (event.key) {
        case Qt.Key_Escape:
            catcher.dismissed();
            event.accepted = true;
            return;
        case Qt.Key_Tab:
            catcher.tabbed(event.modifiers & Qt.ShiftModifier ? -1 : 1);
            event.accepted = true;
            return;
        case Qt.Key_Backtab:
            catcher.tabbed(-1);
            event.accepted = true;
            return;
        case Qt.Key_Down:
            catcher.moved(0, 1);
            event.accepted = true;
            return;
        case Qt.Key_Up:
            catcher.moved(0, -1);
            event.accepted = true;
            return;
        case Qt.Key_Right:
            catcher.moved(1, 0);
            event.accepted = true;
            return;
        case Qt.Key_Left:
            catcher.moved(-1, 0);
            event.accepted = true;
            return;
        case Qt.Key_Return:
        case Qt.Key_Enter:
        case Qt.Key_Space:
            catcher.activated();
            event.accepted = true;
            return;
        }

        switch (event.text) {
        case "j":
            catcher.moved(0, 1);
            break;
        case "k":
            catcher.moved(0, -1);
            break;
        case "l":
            catcher.moved(1, 0);
            break;
        case "h":
            catcher.moved(-1, 0);
            break;
        case "x":
            catcher.removed();
            break;
        default:
            return;
        }

        event.accepted = true;
    }
}
