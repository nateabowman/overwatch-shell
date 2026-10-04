import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.core
import qs.services

// Click-through layer above everything: focus brackets, scanlines, scanner flash.
PanelWindow {
    id: win
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    mask: Region { }
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "overwatch-overlay"

    property bool has: false
    property bool full: false
    property bool covered: false
    property real wx: 0
    property real wy: 0
    property real ww: 0
    property real wh: 0

    Process {
        id: query
        command: ["hyprctl", "activewindow", "-j"]
        property string buf: ""
        stdout: SplitParser { splitMarker: ""; onRead: data => query.buf += data }
        onRunningChanged: {
            if (running) { buf = ""; return }
            try {
                var j = JSON.parse(buf)
                var onScreen = j.address && j.monitor !== undefined && j.mapped !== false
                win.has = !!onScreen
                if (!onScreen) return
                var mon = win.screen
                win.full = j.fullscreen > 0
                win.covered = j.fullscreen === 2
                win.wx = j.at[0] - (mon ? mon.x : 0)
                win.wy = j.at[1] - (mon ? mon.y : 0)
                win.ww = j.size[0]
                win.wh = j.size[1]
                var bar = Windows.barFor(j.class)      // include the title bar in the frame
                win.wy -= bar
                win.wh += bar
            } catch (e) { win.has = false }
        }
    }
    function poll() { if (!query.running) query.running = true }
    Timer { id: soon; interval: 40; onTriggered: win.poll() }
    Timer { id: settle; interval: 320; onTriggered: win.poll() }
    Timer { interval: 2500; running: true; repeat: true; onTriggered: win.poll() }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            var n = event.name
            if (n === "activewindowv2" || n === "openwindow" || n === "closewindow" || n === "movewindowv2"
                || n === "fullscreen" || n === "changefloatingmode" || n === "workspacev2" || n === "focusedmonv2") {
                soon.restart(); settle.restart()
            }
        }
    }
    Component.onCompleted: poll()

    // Focus brackets
    Item {
        id: frame
        readonly property int pad: 4
        readonly property int arm: 16
        visible: win.has && !win.full && Shell.open === "" && !Theme.stealth
        x: win.wx - pad; y: win.wy - pad
        width: win.ww + pad * 2; height: win.wh + pad * 2
        Behavior on x { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on y { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on width { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

        Repeater {
            model: 4
            Item {
                required property int index
                readonly property bool r: index % 2 === 1
                readonly property bool b: index >= 2
                x: r ? frame.width - frame.arm : 0
                y: b ? frame.height - frame.arm : 0
                width: frame.arm; height: frame.arm
                Rectangle { width: parent.width; height: 2; color: Theme.white; y: parent.b ? parent.height - 2 : 0 }
                Rectangle { width: 2; height: parent.height; color: Theme.white; x: parent.r ? parent.width - 2 : 0 }
            }
        }
    }

    // Scanlines
    ShaderEffect {
        anchors.fill: parent
        visible: Shell.scanlines && !win.covered && !Theme.stealth
        property real time: 0
        property real lines: height / 2
        fragmentShader: Qt.resolvedUrl("scan.frag.qsb")
        Timer { interval: 110; repeat: true; running: parent.visible; onTriggered: parent.time += 0.11 }
    }

    // Idle broadcast: shown for the minute before the screen locks; any input clears it
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.01, 0.02, 0.03, 0.82)
        opacity: Shell.idleDim ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 600 } }
        Image {
            id: noise
            property int tick: 0
            anchors.fill: parent
            visible: !Theme.stealth
            source: Assets.ui("static_" + noise.tick)
            fillMode: Image.Tile
            smooth: false
            opacity: 0.10
            Timer { interval: 70; repeat: true; running: Shell.idleDim && !Theme.stealth; onTriggered: noise.tick = (noise.tick + 1) % 4 }
        }
        Column {
            anchors.centerIn: parent
            spacing: 10
            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: !Theme.stealth && status === Image.Ready
                width: 420; height: 210
                source: Assets.ui("transmission_end")
                fillMode: Image.PreserveAspectFit
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Theme.t("NO ACTIVITY DETECTED  //  SECTOR SEALS IN ONE MINUTE", "Locking soon")
                color: Theme.t(Theme.teal, Theme.text)
                font.family: Theme.label; font.pixelSize: 18; font.weight: Font.DemiBold; font.letterSpacing: Theme.stealth ? 0 : 3
            }
        }
    }

    // Scanner flash for screenshots
    Rectangle {
        id: flash
        anchors.fill: parent
        color: "white"
        opacity: 0
        NumberAnimation { id: flashAnim; target: flash; property: "opacity"; from: 0.85; to: 0; duration: 300; easing.type: Easing.OutQuad }
        Connections { target: Shell; function onFlash() { flashAnim.restart() } }
    }
}
