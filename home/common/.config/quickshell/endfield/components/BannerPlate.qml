import ".."
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

// A plate whose trailing edge is a long diagonal, trailed by two stepped bands
// of its own colour at falling opacity — the treatment the source puts on its
// primary selected row.
//
// This and a corner chamfer are alternatives, not a pair: a plate carrying the
// tail does not also cut its bottom right, because the diagonal already is
// that corner. Small rows take the chamfer, the primary row takes this.
//
// Measured off the source: bands at 62% and 46% of the fill, a brighter
// hairline at the step between them, and a slope of about 0.4 of the height
// across the height — shallow, nothing like the 45 degrees of a chamfer.
Item {
    id: root

    property color color: "transparent"

    // The diagonal material over the solid body.
    property bool hatched: true

    // Share of the width the bands take, leaving the rest to the solid body.
    // A fraction rather than a multiple of the height, because that is the one
    // form GTK and rofi can express too, and the four surfaces have to agree.
    property real tail: 0.2

    // Horizontal travel of every diagonal across the full height. This one
    // stays keyed to the height: it is a slope, and a slope is an angle.
    property real slant: height * 0.4

    readonly property real tailWidth: width * tail
    readonly property real band1: tailWidth * 0.66
    readonly property real band2: tailWidth * 0.34

    // What content on the right has to clear. The tail reaches further left at
    // the bottom than at the top, by the whole slant, so its width alone is
    // not enough room.
    readonly property real clearance: tailWidth + slant

    Shape {
        id: plate

        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        readonly property real w: root.width
        readonly property real h: root.height
        readonly property real s: root.slant
        // Where each diagonal meets the top edge.
        readonly property real d1: w - root.band2 - root.band1
        readonly property real d2: w - root.band2

        // Solid body.
        ShapePath {
            fillColor: root.color
            strokeColor: "transparent"

            startX: 0
            startY: 0
            PathLine { x: plate.d1; y: 0 }
            PathLine { x: plate.d1 - plate.s; y: plate.h }
            PathLine { x: 0; y: plate.h }
            PathLine { x: 0; y: 0 }
        }

        ShapePath {
            fillColor: Qt.alpha(root.color, 0.62)
            strokeColor: "transparent"

            startX: plate.d1
            startY: 0
            PathLine { x: plate.d2; y: 0 }
            PathLine { x: plate.d2 - plate.s; y: plate.h }
            PathLine { x: plate.d1 - plate.s; y: plate.h }
            PathLine { x: plate.d1; y: 0 }
        }

        ShapePath {
            fillColor: Qt.alpha(root.color, 0.46)
            strokeColor: "transparent"

            startX: plate.d2
            startY: 0
            PathLine { x: plate.w; y: 0 }
            PathLine { x: plate.w - plate.s; y: plate.h }
            PathLine { x: plate.d2 - plate.s; y: plate.h }
            PathLine { x: plate.d2; y: 0 }
        }

        // The step between the two bands catches a brighter line in the
        // source; without it the tail reads as one soft fade rather than as
        // two deliberate steps.
        ShapePath {
            fillColor: "transparent"
            strokeColor: Qt.alpha(root.color, 0.85)
            strokeWidth: 1

            startX: plate.d2
            startY: 0
            PathLine { x: plate.d2 - plate.s; y: plate.h }
        }
    }

    // The hatch has to stop on the body's diagonal, and a Shape clips to its
    // bounding rect rather than to its path. Any rectangular bound is therefore
    // wrong in one direction or the other: at the body's top corner the hatch
    // spills onto the first band as a dirty wedge, at its bottom corner a bare
    // sliver of fill is left along the diagonal. The body is drawn a second
    // time as a silhouette and used as an alpha mask instead, which follows the
    // real edge.
    Shape {
        id: silhouette

        anchors.fill: parent
        visible: false
        layer.enabled: true

        ShapePath {
            fillColor: "white"
            strokeColor: "transparent"

            startX: 0
            startY: 0
            PathLine { x: plate.d1; y: 0 }
            PathLine { x: plate.d1 - plate.s; y: plate.h }
            PathLine { x: 0; y: plate.h }
            PathLine { x: 0; y: 0 }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.hatched
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: silhouette
        }

        Texture {
            anchors.fill: parent
            kind: "hatch-dark"
        }
    }
}
