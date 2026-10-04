import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

// Segmented level readout for volume and brightness.
PanelWindow {
    visible: Shell.osdVisible
    anchors.bottom: true
    margins.bottom: 70
    implicitWidth: 330
    implicitHeight: 46
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "overwatch-osd"

    Chamfer { anchors.fill: parent; cut: 9; tr: false; bl: false; fillColor: Theme.panelSolid }
    Row {
        anchors.centerIn: parent
        spacing: 12
        Label { text: Shell.osdLabel; width: 72; anchors.verticalCenter: parent.verticalCenter }
        Row {
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter
            Repeater {
                model: 20
                Rectangle {
                    required property int index
                    width: 6; height: 14
                    color: index < Math.round(Shell.osdValue * 20)
                        ? (Shell.osdMuted ? Theme.amber : Theme.teal) : Theme.faint
                }
            }
        }
        Text {
            width: 42
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
            text: Shell.osdMuted ? "MUTE" : Math.round(Shell.osdValue * 100) + "%"
            color: Shell.osdMuted ? Theme.amber : Theme.white
            font.family: Theme.mono; font.pixelSize: 13
        }
    }
}
