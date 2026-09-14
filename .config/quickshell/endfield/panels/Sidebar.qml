import ".."
import "../components"
import "../widgets"
import QtQuick
import QtQuick.Layouts

Panel {
    anchors {
        top: true
        left: true
        bottom: true
    }

    margins {
        top: 10
        left: 10
        bottom: 10
    }

    surfaceName: "endfield-sidebar"
    implicitWidth: 380

    // Scrolls rather than clipping when the widgets outgrow a short screen.
    Flickable {
        anchors.fill: parent
        contentHeight: stack.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: stack

            width: parent.width
            spacing: 14

            PowerWidget {
                Layout.fillWidth: true
            }

            AudioWidget {
                Layout.fillWidth: true
            }

            CalendarWidget {
                Layout.fillWidth: true
            }
        }
    }
}
