import ".."
import QtQuick
import QtQuick.Shapes

// A plate with cut corners instead of rounded ones — GTK can only paint a
// chamfer as a triangle over a flat, known ground, but QML's Shape gives a
// real cut. Only flag the corners a given plate actually cuts: the restraint
// (some corners, not all) is what keeps this reading as machined rather than
// as an octagon.
//
// The Shape is wrapped in a plain Item rather than being the root, because a
// Shape derives its implicit size from the bounding box of its path. A stroke
// widens that box, so a bordered Shape sitting in a layout grows by the stroke
// width every pass — implicit size feeds the layout, the layout feeds the
// path — until it fills whatever contains it. Anchoring the Shape inside an
// Item leaves the implicit size to the caller and breaks the loop.
Item {
    id: root

    property color color: "transparent"
    property color borderColor: "transparent"
    property real borderWidth: 0
    property real chamfer: Theme.chamfer

    property bool topLeft: false
    property bool topRight: false
    property bool bottomLeft: false
    property bool bottomRight: false

    Shape {
        id: plate

        anchors.fill: parent

        // The stroke is centred on the path, so the path is inset by half of
        // it and the border lands wholly inside the plate.
        readonly property real x0: root.borderWidth / 2
        readonly property real y0: root.borderWidth / 2
        readonly property real x1: root.width - x0
        readonly property real y1: root.height - y0

        ShapePath {
            fillColor: root.color
            strokeColor: root.borderColor
            strokeWidth: root.borderWidth

            startX: root.topLeft ? plate.x0 + root.chamfer : plate.x0
            startY: plate.y0
            PathLine {
                x: root.topRight ? plate.x1 - root.chamfer : plate.x1
                y: plate.y0
            }
            PathLine {
                x: plate.x1
                y: root.topRight ? plate.y0 + root.chamfer : plate.y0
            }
            PathLine {
                x: plate.x1
                y: root.bottomRight ? plate.y1 - root.chamfer : plate.y1
            }
            PathLine {
                x: root.bottomRight ? plate.x1 - root.chamfer : plate.x1
                y: plate.y1
            }
            PathLine {
                x: root.bottomLeft ? plate.x0 + root.chamfer : plate.x0
                y: plate.y1
            }
            PathLine {
                x: plate.x0
                y: root.bottomLeft ? plate.y1 - root.chamfer : plate.y1
            }
            PathLine {
                x: plate.x0
                y: root.topLeft ? plate.y0 + root.chamfer : plate.y0
            }
            PathLine {
                x: root.topLeft ? plate.x0 + root.chamfer : plate.x0
                y: plate.y0
            }
        }
    }
}
