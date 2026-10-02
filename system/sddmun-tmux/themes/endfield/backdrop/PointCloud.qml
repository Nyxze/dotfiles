import ".."
import QtQuick

// A baked point cloud, placed in the orbit scene.
//
// The cloud arrives as a texture pair rather than as geometry: neither the
// greeter nor the shell can hand vertex data to the scene graph, so the
// positions are read out of an image in the vertex stage instead. `side` has to
// match the bake — the mesh is sized from it, and a mismatch reads points out
// of the wrong cells.
Item {
    id: root

    // Base name of the texture pair, without the -hi/-lo suffix.
    required property string source
    required property int side

    // Where the cloud sits and how big it is, in planet radii. The bake
    // normalises every model to [-1, 1] on its longest axis, so `size` is a
    // half-extent and not a scale factor against some original.
    property vector3d origin: Qt.vector3d(0, 0, 0)
    property real size: 0.1

    // Where the model's own Y points. `yaw` then turns it about that axis.
    property vector3d up: Qt.vector3d(0, 1, 0)
    property real yaw: 0

    // The camera, which belongs to the scene and not to this. Everything drawn
    // around the planet has to solve the same projection from the same numbers.
    property real camDist: 3.6
    property real disc: 0.78

    // Radius of the sphere that hides points behind it. Zero draws the cloud
    // whole, which is what a model shown on its own wants.
    property real occluder: 1

    property color color: Theme.textPrimary
    property real ink: 0.3
    property real dotSize: 1.7

    ShaderEffect {
        anchors.fill: parent
        blending: true
        mesh: GridMesh {
            resolution: Qt.size(root.side * 2 - 1, root.side * 2 - 1)
        }
        vertexShader: Qt.resolvedUrl("shaders/cloud.vert.qsb")
        fragmentShader: Qt.resolvedUrl("shaders/cloud.frag.qsb")

        property variant cloudHi: hi
        property variant cloudLo: lo
        property color lineColor: root.color
        property vector3d origin: root.origin
        property vector3d up: root.up
        property vector2d viewport: Qt.vector2d(root.width, root.height)
        property real radius: root.occluder
        property real camDist: root.camDist
        property real disc: root.disc
        property real side: root.side
        property real size: root.size
        property real yaw: root.yaw
        property real dotSize: root.dotSize
        property real ink: root.ink
        property real time: 0
    }

    // Nearest, not linear: a filtered texel is the average of two unrelated
    // points and lands the sprite somewhere neither of them is.
    Image {
        id: hi

        source: root.source + "-hi.png"
        smooth: false
        visible: false
    }

    Image {
        id: lo

        source: root.source + "-lo.png"
        smooth: false
        visible: false
    }
}
