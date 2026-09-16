pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Surfaces, deepest first. Depth is the only thing that separates them:
    // never stack two opaque plates without a step between them.
    readonly property color bgDeep: "#0B1118"
    readonly property color bgPanel: "#111A23"
    readonly property color bgRaised: "#1B2733"
    readonly property color line: "#3A4A59"

    // Three text steps, not two: micro-data and metadata sit below secondary
    // text and still have to clear 4.5:1 on bgRaised, which is what fixes
    // textMuted where it is rather than any darker.
    readonly property color textPrimary: "#E8EDF1"
    readonly property color textSecondary: "#AAB7C2"
    readonly property color textMuted: "#8A99A6"

    // accent fills and marks; accentSoft is the same hue used as a foreground,
    // where a solid fill would shout.
    readonly property color accent: "#FFD400"
    readonly property color accentSoft: "#FFE14D"

    readonly property color info: "#4B9BFF"
    readonly property color success: "#8BD32E"
    readonly property color danger: "#FF6B45"

    // Anything sitting on an accent, success or danger fill. White fails on
    // danger at 2.4:1, so the inverted foreground is always this.
    readonly property color onAccent: bgDeep

    readonly property string fontFamily: "HarmonyOS Sans"
    // Condensed is reserved for serials, metadata and display labels — the
    // technical register, not body copy.
    readonly property string condensedFamily: "HarmonyOS Sans Condensed"
    readonly property string monoFamily: "NotoMono Nerd Font"

    // One font value per role, assigned whole (`font: Theme.body`), so a size
    // and its weight can never drift apart at a call site. Uppercase and
    // tracking are baked into the roles that always carry them.

    // Above the top of the scale on purpose: the scale is for interface, and
    // a clock read from across a room is not interface. The lock screen and
    // the greeter both draw it, which is why it is a role and not a literal.
    readonly property font clock: Qt.font({
        family: fontFamily,
        pixelSize: 96,
        weight: 700
    })
    readonly property font display: Qt.font({
        family: fontFamily,
        pixelSize: 32,
        weight: 700
    })
    readonly property font h2: Qt.font({
        family: fontFamily,
        pixelSize: 20,
        weight: 650
    })
    readonly property font h3: Qt.font({
        family: fontFamily,
        pixelSize: 14,
        weight: 650
    })
    readonly property font body: Qt.font({
        family: fontFamily,
        pixelSize: 13,
        weight: 400
    })
    // Label's size without its capitals: a value read off a device — an SSID, a
    // percentage, a device name — is data, and uppercasing data corrupts it.
    readonly property font bodySmall: Qt.font({
        family: fontFamily,
        pixelSize: 11,
        weight: 400
    })
    readonly property font label: Qt.font({
        family: fontFamily,
        pixelSize: 11,
        weight: 600,
        capitalization: Font.AllUppercase,
        letterSpacing: 0.8
    })
    readonly property font micro: Qt.font({
        family: condensedFamily,
        pixelSize: 9,
        weight: 500,
        capitalization: Font.AllUppercase,
        letterSpacing: 1.2
    })
    readonly property font numeric: Qt.font({
        family: fontFamily,
        pixelSize: 24,
        weight: 650
    })

    readonly property real bodyLineHeight: 20

    // Nerd Font glyphs, at the three sizes an outlined icon stays readable at.
    readonly property font glyphSmall: Qt.font({
        family: monoFamily,
        pixelSize: 16
    })
    readonly property font glyphMedium: Qt.font({
        family: monoFamily,
        pixelSize: 20
    })
    readonly property font glyphLarge: Qt.font({
        family: monoFamily,
        pixelSize: 24
    })

    // Every margin, gap and size is a multiple of 4. Taking the step count
    // rather than the pixel value is what keeps a stray 9 or 14 out.
    function space(steps) {
        return steps * 4;
    }

    readonly property int padding: space(4)

    // A 45 degree cut replaces the radius; there is no rounding anywhere.
    readonly property int chamfer: 5
    readonly property int border: 1
    readonly property int borderEmphasis: 2

    readonly property int durHover: 100
    readonly property int durPress: 80
    readonly property int durOpen: 180
}
