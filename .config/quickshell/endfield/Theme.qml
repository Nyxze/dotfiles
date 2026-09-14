pragma Singleton

import Quickshell
import QtQuick

Singleton {
    // Neutrals, darkest to lightest
    readonly property color base: "#171717"
    readonly property color charcoal: "#313739"
    readonly property color overlay: "#565656"
    readonly property color mediumGray: "#7E807C"
    readonly property color lightGray: "#A0AAA9"
    readonly property color text: "#DFE3E3"

    // Accents
    readonly property color oliveGreen: "#657136"
    readonly property color feintYellow: "#F8F546"
    readonly property color brightYellow: "#FFFA00"

    // Status
    readonly property color success: "#A3B84A"
    readonly property color critical: "#E95460"

    readonly property string fontFamily: "HarmonyOS Sans"
    readonly property string monoFamily: "NotoMono Nerd Font"

    readonly property int radius: 10
    readonly property int padding: 16
}
