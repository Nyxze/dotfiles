import ".."
import "../components"

Panel {
    anchors {
        top: true
        right: true
    }

    margins {
        top: 10
        right: 10
    }

    surfaceName: "endfield-calendar"

    implicitWidth: 340
    implicitHeight: 400

    MonthGrid {
        anchors.fill: parent
    }
}
