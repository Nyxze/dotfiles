import ".."
import "../components"
import Quickshell
import Quickshell.Services.Notifications
import QtQuick
import QtQuick.Layouts

// One notification, rendered the same way whether it is a live toast or a row
// in the history.
Rectangle {
    id: entry

    required property var notification

    readonly property bool critical: notification.urgency === NotificationUrgency.Critical
    readonly property string iconSource: notification.image
        || (notification.appIcon ? Quickshell.iconPath(notification.appIcon, true) : "")

    signal dismissed

    implicitHeight: layout.implicitHeight + 20
    radius: Theme.radius
    color: Theme.base
    border.width: 1
    border.color: critical ? Theme.critical : Qt.alpha(Theme.overlay, 0.4)

    RowLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 10
        spacing: 10

        Image {
            visible: entry.iconSource !== ""
            source: entry.iconSource
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            Layout.alignment: Qt.AlignTop
            fillMode: Image.PreserveAspectFit
            sourceSize.width: 68
            sourceSize.height: 68
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    Layout.fillWidth: true
                    text: entry.notification.summary
                    color: Theme.text
                    elide: Text.ElideRight
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: entry.notification.appName
                    color: Theme.mediumGray
                    font.family: Theme.fontFamily
                    font.pixelSize: 11
                }
            }

            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: entry.notification.body
                color: Theme.lightGray
                wrapMode: Text.WordWrap
                maximumLineCount: 4
                elide: Text.ElideRight
                textFormat: Text.StyledText
                font.family: Theme.fontFamily
                font.pixelSize: 12
            }

            Flow {
                Layout.fillWidth: true
                Layout.topMargin: 4
                visible: entry.notification.actions.length > 0
                spacing: 6

                Repeater {
                    model: entry.notification.actions

                    Rectangle {
                        required property var modelData

                        width: actionLabel.implicitWidth + 20
                        height: 26
                        radius: 7
                        color: actionMouse.containsMouse ? Theme.brightYellow : Theme.charcoal

                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: parent.modelData.text
                            color: actionMouse.containsMouse ? Theme.base : Theme.lightGray
                            font.family: Theme.fontFamily
                            font.pixelSize: 12
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
            Layout.alignment: Qt.AlignTop
            glyph: "×"
            onActivated: entry.dismissed()
        }
    }
}
