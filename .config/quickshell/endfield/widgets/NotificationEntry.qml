import ".."
import "../components"
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

// One notification, rendered the same way whether it is a live toast or a row
// in the history.
ChamferedRect {
    id: entry

    required property var notification

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property string iconSource: notification.image
        || (notification.appIcon ? Quickshell.iconPath(notification.appIcon, true) : "")

    signal dismissed

    readonly property bool navigable: true
    readonly property bool hasCursor: Cursor.item === entry

    // Enter takes the notification's first action when it offers one, since
    // that is what the sender wants you to do with it; x always just clears it.
    function navActivate() {
        const actions = entry.notification.actions;
        if (actions.length === 0)
            return;
        actions[0].invoke();
        entry.dismissed();
    }

    function navRemove() {
        entry.dismissed();
    }

    implicitHeight: layout.implicitHeight + Theme.space(6)
    topLeft: true
    bottomRight: true
    color: Theme.bgRaised
    borderWidth: entry.hasCursor || entry.critical ? Theme.borderEmphasis : Theme.border
    borderColor: {
        if (entry.hasCursor)
            return Theme.accent;
        return critical ? Theme.danger : Theme.line;
    }

    HoverHandler {
        onHoveredChanged: if (hovered)
            Cursor.item = entry
    }

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Theme.space(3)
        spacing: Theme.space(3)

        Image {
            visible: entry.iconSource !== ""
            source: entry.iconSource
            Layout.preferredWidth: Theme.space(8)
            Layout.preferredHeight: Theme.space(8)
            Layout.alignment: Qt.AlignTop
            fillMode: Image.PreserveAspectFit
            sourceSize.width: 68
            sourceSize.height: 68
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.space(1)

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.space(2)

                Text {
                    Layout.fillWidth: true
                    text: entry.notification.summary
                    color: Theme.textPrimary
                    elide: Text.ElideRight
                    font: Theme.h3
                }

                Text {
                    text: entry.notification.appName
                    color: Theme.textMuted
                    font: Theme.micro
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: entry.notification.body
                color: Theme.textSecondary
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
                textFormat: Text.StyledText
                font: Theme.body
                lineHeight: Theme.bodyLineHeight
                lineHeightMode: Text.FixedHeight
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: Theme.space(1)
                visible: entry.notification.actions.length > 0
                spacing: Theme.space(2)

                Repeater {
                    model: entry.notification.actions

                    Rectangle {
                        required property var modelData

                        // Secondary: a dark plate inside an accent hairline.
                        // The accent fill is what a primary action takes, and
                        // a notification's own buttons are never that.
                        width: actionLabel.implicitWidth + Theme.space(5)
                        height: Theme.space(7)
                        color: actionMouse.containsMouse ? Theme.accent : Theme.bgDeep
                        border.width: actionMouse.containsMouse ? 0 : Theme.border
                        border.color: Theme.accent

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            color: actionMouse.containsMouse ? Theme.onAccent : Theme.textSecondary
                            font: Theme.label
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                parent.modelData.invoke();
                                entry.dismissed();
                            }
                        }
                    }
                }
            }
        }

        IconButton {
            cursorTarget: entry
            Layout.alignment: Qt.AlignTop
            glyph: "×"
            onActivated: entry.dismissed()
        }
    }
}
