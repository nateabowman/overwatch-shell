import QtQuick
import Quickshell.Hyprland
import qs.core
import qs.services

// Workspaces as sector tabs. Always shows at least four; click to switch, scroll to step.
Row {
    id: root
    spacing: 3
    readonly property var spaces: Hyprland.workspaces.values
    readonly property int activeId: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
    readonly property int count: {
        var top = 4
        for (var i = 0; i < spaces.length; i++) if (spaces[i].id > top) top = spaces[i].id
        return Math.min(top, 10)
    }
    function occupied(id) {
        for (var i = 0; i < spaces.length; i++) if (spaces[i].id === id) return spaces[i].toplevels.values.length > 0
        return false
    }
    function go(id) { if (id !== activeId) Windows.dispatch("hl.dsp.focus({ workspace = " + id + " })") }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        rightPadding: 5
        visible: !Theme.stealth
        text: "SECTOR"
        color: Theme.muted
        font.family: Theme.label
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: 1.2
    }

    Repeater {
        model: root.count
        delegate: Item {
            id: tab
            required property int index
            readonly property int wid: index + 1
            readonly property bool active: root.activeId === wid
            readonly property bool busy: root.occupied(wid)
            width: 30; height: 20
            anchors.verticalCenter: parent.verticalCenter

            Chamfer {
                anchors.fill: parent
                cut: 5
                tr: false; bl: false
                fillColor: tab.active ? Theme.teal : (hover.hovered ? Theme.fill : "transparent")
                strokeColor: tab.active ? Theme.teal : (tab.busy ? Theme.tealDim : Theme.faint)
            }
            Text {
                anchors.centerIn: parent
                text: (tab.wid < 10 && !Theme.stealth ? "0" : "") + tab.wid
                color: tab.active ? Theme.base : (tab.busy ? Theme.text : Theme.muted)
                font.family: Theme.mono
                font.pixelSize: 12
            }
            HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
            TapHandler { onTapped: { Shell.fx("click"); root.go(tab.wid) } }
        }
    }
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            var next = root.activeId + (event.angleDelta.y > 0 ? -1 : 1)
            if (next >= 1 && next <= root.count) root.go(next)
        }
    }
}
