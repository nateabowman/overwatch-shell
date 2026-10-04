import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland
import qs.core
import qs.services

// Window switcher (SUPER+Tab): every window as a live surveillance feed.
PanelWindow {
    id: win
    readonly property bool shown: Shell.open === "switcher"
    property var items: []
    property int current: 0
    visible: shown
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "overwatch-panel"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    onShownChanged: {
        if (!shown) return
        items = Hyprland.toplevels.values.filter(t => (t.title || t.wayland) && Windows.hidden.indexOf("0x" + t.address) < 0)
        current = items.length > 1 ? 1 : 0
        keys.forceActiveFocus()
    }
    function pick(i) {
        var t = items[i]
        Shell.close()
        if (t) { Shell.fx("select"); Windows.act("focus", "0x" + t.address) }
    }
    function step(d) { if (items.length) { current = (current + d + items.length) % items.length; Shell.fx("move") } }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.03, 0.04, 0.72)
        TapHandler { onTapped: Shell.close() }
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: true
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) Shell.close()
            else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Right || event.key === Qt.Key_Down) win.step(1)
            else if (event.key === Qt.Key_Backtab || event.key === Qt.Key_Left || event.key === Qt.Key_Up) win.step(-1)
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) win.pick(win.current)
            else if (event.key === Qt.Key_Delete && win.items[win.current]) {
                Windows.act("close", "0x" + win.items[win.current].address)
                win.items = win.items.filter((t, i) => i !== win.current)
                win.current = Math.min(win.current, Math.max(0, win.items.length - 1))
            }
            event.accepted = true
        }
        Keys.onReleased: event => { if (event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R) win.pick(win.current) }

        Column {
            anchors.centerIn: parent
            spacing: 16
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10
                Emblem { implicitWidth: 22; implicitHeight: 22; anchors.verticalCenter: parent.verticalCenter }
                Text {
                    text: Theme.t("SURVEILLANCE FEEDS  //  " + win.items.length + " SUBJECTS", "Windows")
                    color: Theme.white
                    font.family: Theme.label; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: Theme.stealth ? 0 : 2
                }
            }
            Grid {
                id: grid
                anchors.horizontalCenter: parent.horizontalCenter
                columns: Math.min(4, Math.max(1, Math.ceil(Math.sqrt(win.items.length))))
                spacing: 14
                readonly property real cw: Math.min(340, (win.width - 160) / columns - spacing)
                Repeater {
                    model: win.items
                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index
                        readonly property bool sel: win.current === index
                        readonly property string cls: modelData.lastIpcObject && modelData.lastIpcObject.class ? modelData.lastIpcObject.class : ""
                        readonly property var entry: DesktopEntries.heuristicLookup(cls)
                        width: grid.cw; height: grid.cw * 0.62 + 30

                        Chamfer { anchors.fill: parent; cut: 9; tr: false; bl: false
                            fillColor: cell.sel ? Theme.fill : Theme.panelSolid
                            strokeColor: cell.sel ? Theme.teal : Theme.faint; strokeWidth: cell.sel ? 2 : 1 }
                        Item {
                            id: feed
                            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 6 }
                            height: parent.height - 36
                            clip: true
                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 48
                                opacity: view.hasContent ? 0 : 0.8
                                source: Quickshell.iconPath(cell.entry && cell.entry.icon ? cell.entry.icon : cell.cls.toLowerCase(), "application-x-executable")
                            }
                            ScreencopyView {
                                id: view
                                anchors.fill: parent
                                captureSource: win.shown ? cell.modelData.wayland : null
                                live: win.shown
                                constraintSize: Qt.size(feed.width, feed.height)
                            }
                        }
                        Text {
                            anchors { left: parent.left; leftMargin: 10; right: tag.left; rightMargin: 6; bottom: parent.bottom; bottomMargin: 8 }
                            text: cell.modelData.title || cell.cls
                            color: cell.sel ? Theme.white : Theme.text
                            elide: Text.ElideRight
                            font.family: Theme.label; font.pixelSize: 13; font.weight: Font.DemiBold
                        }
                        Text {
                            id: tag
                            anchors { right: parent.right; rightMargin: 10; bottom: parent.bottom; bottomMargin: 9 }
                            readonly property string ws: cell.modelData.workspace ? cell.modelData.workspace.name : ""
                            text: ws.indexOf("special") === 0 ? Theme.t("HELD", "min") : Theme.t("S", "") + ws
                            color: Theme.muted
                            font.family: Theme.mono; font.pixelSize: 10
                        }
                        HoverHandler { cursorShape: Qt.PointingHandCursor; onHoveredChanged: if (hovered) win.current = cell.index }
                        TapHandler { onTapped: win.pick(cell.index) }
                    }
                }
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Theme.t("TAB  CYCLE     ENTER  ACQUIRE     DEL  TERMINATE     ESC  DISMISS", "Tab to cycle, Enter to switch, Del to close, Esc to cancel")
                color: Theme.faint
            }
        }
    }
}
