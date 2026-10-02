import ".."
import QtQuick

// The planet. Everything about its shape is in the shader; what lives here is
// the camera it shares with the rest of the scene, and the impact sites it has
// to draw ripples from.
Item {
    id: root

    property real time: 0

    property real radius: 1
    property real camDist: 3.6
    property real disc: 0.78
    property real tilt: 0.38
    property real spin: 0.035

    // Three slots, each a unit vector in the planet's own frame plus the time
    // its ripple started. A negative time is an empty slot. Three because a
    // fourth would never be reached: a ripple outlives its drop by a couple of
    // seconds, not by two more drops.
    property vector4d impactA: Qt.vector4d(0, 0, 0, -1)
    property vector4d impactB: Qt.vector4d(0, 0, 0, -1)
    property vector4d impactC: Qt.vector4d(0, 0, 0, -1)

    // A rasterised still to fall back on. Whose still it is belongs to whoever
    // mounts this, not here — the greeter has one it must not come up without,
    // and the shell has nothing to lose if the shader fails.
    property url fallback

    ShaderEffect {
        id: gpu

        anchors.fill: parent
        vertexShader: Qt.resolvedUrl("shaders/globe.vert.qsb")
        fragmentShader: Qt.resolvedUrl("shaders/globe.frag.qsb")

        property color lineColor: Theme.textPrimary
        property vector2d viewport: Qt.vector2d(root.width, root.height)
        property vector4d impactA: root.impactA
        property vector4d impactB: root.impactB
        property vector4d impactC: root.impactC
        property real radius: root.radius
        property real camDist: root.camDist
        property real disc: root.disc
        property real tilt: root.tilt
        property real spin: root.spin
        property real time: root.time
    }

    Image {
        anchors.fill: parent
        source: root.fallback
        fillMode: Image.PreserveAspectCrop
        visible: root.fallback != "" && gpu.status === ShaderEffect.Error
    }
}
