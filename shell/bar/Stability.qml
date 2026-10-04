import QtQuick
import Quickshell.Services.UPower
import qs.core

// Battery as a segmented STABILITY meter.
Row {
    id: root
    readonly property var dev: UPower.displayDevice
    readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0
    readonly property bool charging: !UPower.onBattery
    readonly property color tone: pct <= 7 ? Theme.red : (pct <= 15 ? Theme.amber : Theme.teal)
    spacing: 6

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Theme.t("STABILITY", "Battery")
        color: Theme.muted
        font.family: Theme.label
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.spacing
    }
    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2
        Repeater {
            model: 10
            Rectangle {
                required property int index
                width: 4; height: 11
                color: index < Math.ceil(root.pct / 10) ? root.tone : Theme.faint
            }
        }
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.pct + "%" + (root.charging ? "+" : "")
        color: root.tone
        font.family: Theme.mono
        font.pixelSize: 13
    }
}
