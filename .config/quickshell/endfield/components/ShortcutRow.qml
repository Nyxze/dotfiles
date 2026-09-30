import ".."
import QtQuick

Item {
    id: row

    property string section: ""
    property string keys: ""
    property string action: ""
    readonly property bool navigable: true
    readonly property bool selected: Cursor.item === row

    function navActivate() {
        Cursor.item = row;
    }

    implicitHeight: Theme.space(8)

    ChamferedRect {
        anchors.fill: parent
        bottomRight: true
        chamfer: Theme.chamfer
        color: row.selected ? Theme.bgRaised : "transparent"
        borderColor: Theme.accent
        borderWidth: row.selected ? Theme.borderEmphasis : 0
    }

    Text {
        id: sectionLabel

        anchors.left: parent.left
        anchors.leftMargin: Theme.space(3)
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.space(19)
        text: row.section
        color: row.selected ? Theme.accentSoft : Theme.textMuted
        elide: Text.ElideRight
        font: Theme.label
    }

    Text {
        id: keyLabel

        anchors.left: sectionLabel.right
        anchors.leftMargin: Theme.space(2)
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.space(43)
        text: row.keys
        color: row.selected ? Theme.textPrimary : Theme.textSecondary
        elide: Text.ElideRight
        font: Theme.shortcut
    }

    Text {
        anchors.left: keyLabel.right
        anchors.right: parent.right
        anchors.leftMargin: Theme.space(2)
        anchors.rightMargin: Theme.space(3)
        anchors.verticalCenter: parent.verticalCenter
        text: row.action
        color: row.selected ? Theme.textPrimary : Theme.textSecondary
        elide: Text.ElideRight
        font: Theme.body
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onContainsMouseChanged: {
            if (containsMouse)
                Cursor.item = row;
        }
        onClicked: Cursor.item = row
    }
}
