import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.UPower
import qs.core
import qs.services

PanelWindow {
    id: bar
    anchors { top: true; left: true; right: true }
    implicitHeight: Theme.barHeight
    color: "transparent"
    WlrLayershell.namespace: "overwatch-bar"

    readonly property int battery: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) : 100
    readonly property color hairline: UPower.onBattery && battery <= 7 ? Theme.red
        : (UPower.onBattery && battery <= 15 ? Theme.amber : Theme.line)

    SystemClock { id: clock; precision: SystemClock.Seconds }

    Rectangle { anchors.fill: parent; color: Theme.panel }

    // Bottom hairline with a brighter run under the left block
    Rectangle {
        id: rule
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 1
        color: bar.hairline
        SequentialAnimation on opacity {
            running: UPower.onBattery && bar.battery <= 7
            loops: Animation.Infinite
            alwaysRunToEnd: true
            NumberAnimation { to: 0.25; duration: 900 }
            NumberAnimation { to: 1; duration: 900 }
        }
    }
    Rectangle {
        anchors { left: parent.left; bottom: parent.bottom }
        width: left.width + 26; height: 2
        color: Theme.teal
        visible: !Theme.stealth
    }

    // Left: emblem and sectors
    Row {
        id: left
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 12
        Emblem {
            id: emblem
            anchors.verticalCenter: parent.verticalCenter
            readonly property string about: Theme.t("CIVIL PROTECTION TERMINAL\nApplications, search and power controls", "Applications, search and power")
            HoverHandler { cursorShape: Qt.PointingHandCursor; onHoveredChanged: hovered ? Shell.tip(emblem.about, emblem) : Shell.untip(emblem.about) }
            TapHandler { onTapped: Shell.toggle("launcher") }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "OVERWATCH"
            visible: !Theme.stealth
            color: Theme.white
            font.family: Theme.label
            font.pixelSize: 14
            font.weight: Font.Bold
            font.letterSpacing: 2.5
        }
        Rectangle { width: 1; height: 16; color: Theme.faint; anchors.verticalCenter: parent.verticalCenter; visible: !Theme.stealth }
        Sectors { anchors.verticalCenter: parent.verticalCenter }
    }

    // Centre: focused window, kept inside the gap between the two side blocks
    Item {
        id: centre
        anchors { left: left.right; right: right.left; top: parent.top; bottom: parent.bottom; leftMargin: 20; rightMargin: 20 }
        readonly property int maxChars: Math.max(0, Math.floor((width - 170) / 8))
        Row {
            anchors.centerIn: parent
            spacing: 8
            visible: subject.target.length > 0 && centre.maxChars > 6
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "SUBJECT"
                visible: !Theme.stealth
                color: Theme.muted
                font.family: Theme.label
                font.pixelSize: 11
                font.weight: Font.DemiBold
                font.letterSpacing: 1.2
            }
            DecodeText {
                id: subject
                anchors.verticalCenter: parent.verticalCenter
                readonly property var win: ToplevelManager.activeToplevel
                readonly property string full: win && win.title ? win.title : ""
                target: full.length > centre.maxChars ? full.substring(0, centre.maxChars - 1) + "…" : full
            }
            WinControls { anchors.verticalCenter: parent.verticalCenter; leftPadding: 6; visible: Windows.active !== null && Windows.barHeight === 0 }
        }
    }

    // Right: readouts
    Row {
        id: right
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 14

        Waveform { anchors.verticalCenter: parent.verticalCenter }
        Tray { anchors.verticalCenter: parent.verticalCenter; window: bar }

        // Hover for detail, click for the full monitor
        Repeater {
            model: [ { id: "cpu", label: "CPU" }, { id: "mem", label: "MEM" }, { id: "gpu", label: "GPU" } ]
            delegate: Row {
                id: stat
                required property var modelData
                readonly property int value: modelData.id === "cpu" ? Sys.cpu : modelData.id === "mem" ? Sys.mem : Sys.gpu
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6
                Readout {
                    anchors.verticalCenter: parent.verticalCenter
                    label: stat.modelData.label
                    value: (stat.value < 10 ? " " : "") + stat.value + "%"
                    valueColor: stat.value >= 90 ? Theme.amber : (sh.hovered ? Theme.white : Theme.text)
                }
                Spark { anchors.verticalCenter: parent.verticalCenter; visible: stat.modelData.id === "cpu"; samples: Sys.cpuHist }
                HoverHandler {
                    id: sh
                    cursorShape: Qt.PointingHandCursor
                    onHoveredChanged: {
                        if (hovered) { Shell.detailX = stat.mapToItem(null, 0, 0).x; Shell.detail = stat.modelData.id }
                        else if (Shell.detail === stat.modelData.id) Shell.detail = ""
                    }
                }
                TapHandler { onTapped: { Shell.fx("click"); Quickshell.execDetached(["sh", "-c", "uwsm app -- kitty -e btop || kitty -e btop"]) } }
            }
        }
        // Everything from here on opens the control panel
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14
            Readout {
                anchors.verticalCenter: parent.verticalCenter
                label: Theme.t("UPLINK", "Network")
                value: Sys.netType === "none" ? Theme.t("SEVERED", "offline") : (Sys.shownNet.length > 14 ? Sys.shownNet.substring(0, 13) + "…" : Sys.shownNet)
                valueColor: Sys.netType === "none" ? Theme.amber : Theme.text
            }
            Volume { anchors.verticalCenter: parent.verticalCenter }
            Stability { id: stab; anchors.verticalCenter: parent.verticalCenter }
            id: quick
            readonly property var dev: UPower.displayDevice
            readonly property string about: {
                var left = dev ? (UPower.onBattery ? dev.timeToEmpty : dev.timeToFull) : 0
                var hm = left > 0 ? Math.floor(left / 3600) + "h " + Math.round((left % 3600) / 60) + "m " + (UPower.onBattery ? "remaining" : "to full") : (UPower.onBattery ? "on battery" : "plugged in")
                return Theme.t("UPLINK", "Network") + ": " + (Sys.netType === "none" ? "not connected" : Sys.shownNet + " (" + Sys.netType + ")")
                    + "\n" + Theme.t("STABILITY", "Battery") + ": " + bar.battery + "%, " + hm
                    + "\n" + Theme.t("CLICK: CONTROL PANEL   SCROLL ON AUDIO: VOLUME", "Click: quick settings. Scroll on volume to change it")
            }
            HoverHandler { cursorShape: Qt.PointingHandCursor; onHoveredChanged: hovered ? Shell.tip(quick.about, quick) : Shell.untip(quick.about) }
            TapHandler { onTapped: { Shell.fx("click"); Shell.toggle("control") } }
        }
        Rectangle { width: 1; height: 16; color: Theme.faint; anchors.verticalCenter: parent.verticalCenter }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -2
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: { Shell.fx("click"); Shell.toggle("control") } }
            Text {
                anchors.right: parent.right
                text: Qt.formatDateTime(clock.date, "HH:mm:ss")
                color: Theme.white
                font.family: Theme.mono
                font.pixelSize: 14
            }
            Text {
                anchors.right: parent.right
                text: Qt.formatDateTime(clock.date, "yyyy.MM.dd ddd").toUpperCase()
                color: Theme.muted
                font.family: Theme.mono
                font.pixelSize: 9
            }
        }
    }
}
