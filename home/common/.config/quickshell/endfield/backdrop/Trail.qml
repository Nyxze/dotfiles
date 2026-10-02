import ".."
import QtQuick
import QtQuick.Shapes

// A polyline in screen space. It knows nothing about what it traces: the scene
// owns the camera and hands over points already projected.
//
// The Shape is wrapped in a plain Item because a Shape takes its implicit size
// from its path's bounding box, and a stroked path in a layout then grows by
// the stroke width on every pass until it fills whatever holds it.
Item {
    id: root

    property var points: []
    property color color: Theme.textPrimary
    property real ink: 0.25
    property real thickness: 1
    property var dash: []

    Shape {
        anchors.fill: parent

        ShapePath {
            strokeColor: Qt.rgba(root.color.r, root.color.g, root.color.b, root.ink)
            strokeWidth: root.thickness
            fillColor: "transparent"
            strokeStyle: root.dash.length > 0 ? ShapePath.DashLine : ShapePath.SolidLine
            dashPattern: root.dash

            PathPolyline {
                path: root.points
            }
        }
    }
}
