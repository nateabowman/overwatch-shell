import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.core
import qs.services

// Hover card under the bar with live detail for CPU, memory or GPU.
PanelWindow {
    id: win
    readonly property bool shown: Shell.detail !== ""
    property var lines: []
    visible: shown && lines.length > 0
    anchors { top: true; left: true }
    margins { top: 6; left: Math.max(8, Math.min(Shell.detailX - 20, (screen ? screen.width : 1600) - implicitWidth - 8)) }
    implicitWidth: 300
    implicitHeight: body.implicitHeight + 26
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "overwatch-osd"

    readonly property bool tip: Shell.detail === "tip"
    function refresh() {
        if (tip) { lines = Shell.tipText.split("\n"); return }
        lines = []; if (shown) proc.running = true
    }
    onShownChanged: refresh()
    Connections { target: Shell; function onDetailChanged() { win.refresh() } function onTipTextChanged() { if (win.tip) win.refresh() } }
    Timer { interval: 2000; repeat: true; running: win.shown && !win.tip; onTriggered: if (!proc.running) proc.running = true }

    Process {
        id: proc
        command: ["bash", Qt.resolvedUrl("../scripts/sysdetail.sh").toString().replace("file://", ""), Shell.detail || "cpu"]
        property var buf: []
        stdout: SplitParser { onRead: line => proc.buf.push(line) }
        onRunningChanged: { if (running) buf = []; else if (win.shown && !win.tip) win.lines = buf }
    }

    mask: Region { }

    Chamfer { anchors.fill: parent; cut: 9; tl: false; br: false; fillColor: Theme.panelSolid }
    Column {
        id: body
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 13 }
        spacing: 2
        Label {
            text: Theme.t({ cpu: "PROCESSOR TELEMETRY", mem: "MEMORY TELEMETRY", gpu: "OPTICS TELEMETRY" }[Shell.detail] || "",
                          { cpu: "Processor", mem: "Memory", gpu: "Graphics" }[Shell.detail] || "")
            color: Theme.teal
            bottomPadding: 4
            visible: !win.tip
        }
        Repeater {
            model: win.lines
            Text {
                required property var modelData
                required property int index
                width: body.width
                text: modelData
                color: index === 0 || /^[A-Z]{4,} \(/.test(modelData) ? Theme.white : Theme.text
                wrapMode: win.tip ? Text.Wrap : Text.NoWrap
                elide: Text.ElideRight
                font.family: Theme.stealth ? "Noto Sans Mono" : Theme.mono
                font.pixelSize: 12
            }
        }
    }
}
