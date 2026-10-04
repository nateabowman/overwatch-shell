pragma Singleton
import Quickshell
import QtQuick
import qs.services

// Single source for colours, fonts and sizes. `stealth` swaps the whole shell to a
// plain, neutral work look: no Combine wording, art, glyphs or cut corners.
Singleton {
    readonly property bool stealth: Assets.stealth
    function t(themed, plain) { return stealth ? plain : themed }

    readonly property color teal: stealth ? "#6ea8dc" : "#5fd7e8"       // accent
    readonly property color tealDim: stealth ? "#3d5f80" : "#1f6f7d"
    readonly property color white: stealth ? "#f2f4f6" : "#e6f6fa"
    readonly property color text: stealth ? "#d9dde2" : "#cfeaf0"
    readonly property color muted: stealth ? "#98a1ab" : "#6f8a94"
    readonly property color faint: stealth ? "#3b424b" : "#33434e"
    readonly property color steel: stealth ? "#262b32" : "#131b23"
    readonly property color base: stealth ? "#1c2026" : "#0a0f14"
    readonly property color amber: "#ffb347"
    readonly property color red: stealth ? "#e0645c" : "#ff5a4f"

    readonly property color panel: stealth ? Qt.rgba(0.110, 0.125, 0.149, 0.97) : Qt.rgba(0.039, 0.059, 0.078, 0.82)
    readonly property color panelSolid: stealth ? Qt.rgba(0.125, 0.141, 0.165, 0.99) : Qt.rgba(0.039, 0.059, 0.078, 0.94)
    readonly property color line: stealth ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0.373, 0.843, 0.910, 0.45)
    readonly property color fill: stealth ? Qt.rgba(0.431, 0.659, 0.863, 0.16) : Qt.rgba(0.373, 0.843, 0.910, 0.14)

    readonly property var families: Qt.fontFamilies()
    readonly property string plainFont: families.indexOf("Adwaita Sans") >= 0 ? "Adwaita Sans" : "Noto Sans"
    readonly property string label: stealth ? plainFont : (families.indexOf("GorDIN") >= 0 ? "GorDIN" : "Rajdhani")   // GorDIN = Half-Life 2 menu font
    readonly property string glyphs: !stealth && families.indexOf("Universal Union") >= 0 ? "Universal Union" : ""    // Combine script, decoration only
    readonly property string mono: stealth ? plainFont : "Share Tech Mono"
    readonly property string icons: "MesloLGS Nerd Font Mono"
    readonly property real spacing: stealth ? 0 : 1.2

    readonly property int barHeight: 34
    readonly property int cut: 8
}
