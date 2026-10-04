import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.services

// Bottom taskbar: one tab per window on any workspace.
// Left click: focus / minimize / restore. Middle click: close. Right click: maximize.
PanelWindow {
    id: bar
    anchors { bottom: true; left: true; right: true }
    implicitHeight: 38
    color: "transparent"
    WlrLayershell.namespace: "overwatch-bar"

    Rectangle { anchors.fill: parent; color: Theme.panel }
    Rectangle { anchors { left: parent.left; right: parent.right; top: parent.top } height: 1; color: Theme.line }

    Label {
        id: cap
        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
        text: Theme.t("SUBJECTS " + (Windows.list.length < 10 ? "0" : "") + Windows.list.length, "Windows")
    }

    Row {
        id: tabs
        anchors { left: cap.right; leftMargin: 12; right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        spacing: 4
        readonly property real tabWidth: Math.max(44, Math.min(210, (width - spacing * Math.max(0, Windows.list.length - 1)) / Math.max(1, Windows.list.length)))

        Repeater {
            model: Windows.list
            delegate: Item {
                id: tab
                required property var modelData
                readonly property var entry: DesktopEntries.heuristicLookup(modelData.cls)
                readonly property string iconName: entry && entry.icon ? entry.icon : modelData.cls.toLowerCase()
                width: tabs.tabWidth
                height: 28
                opacity: modelData.minimized ? 0.55 : 1

                Chamfer {
                    anchors.fill: parent
                    cut: 6; tr: false; bl: false
                    fillColor: tab.modelData.active ? Theme.fill : (hover.hovered ? Qt.rgba(0.373, 0.843, 0.910, 0.07) : "transparent")
                    strokeColor: tab.modelData.active ? Theme.teal : Theme.faint
                }
                Rectangle {
                    visible: tab.modelData.active
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; leftMargin: 1; rightMargin: 7 }
                    height: 2; color: Theme.teal
                }
                IconImage {
                    id: icon
                    anchors { left: parent.left; leftMargin: 8; verticalCenter: parent.verticalCenter }
                    implicitSize: 18
                    source: Quickshell.iconPath(tab.iconName, "application-x-executable")
                }
                Text {
                    visible: tab.width > 80
                    anchors { left: icon.right; leftMargin: 7; right: tag.left; rightMargin: 6; verticalCenter: parent.verticalCenter }
                    text: tab.modelData.title
                    color: tab.modelData.active ? Theme.white : Theme.text
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    font.family: Theme.label; font.pixelSize: 13; font.weight: Font.DemiBold
                    font.italic: tab.modelData.minimized
                }
                Text {
                    id: tag
                    visible: tab.width > 80
                    anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    text: tab.modelData.minimized ? Theme.t("HELD", "min") : (tab.modelData.ws.length <= 2 ? Theme.t("S", "") + tab.modelData.ws : "")
                    color: tab.modelData.minimized ? Theme.amber : Theme.muted
                    font.family: Theme.mono; font.pixelSize: 9
                }
                HoverHandler { id: hover; onHoveredChanged: if (hovered) Shell.fx("hover") }
                TapHandler {
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onTapped: (point, button) => {
                        Shell.fx("click")
                        if (button === Qt.MiddleButton) Windows.act("close", tab.modelData.address)
                        else if (button === Qt.RightButton) Windows.act("maximize", tab.modelData.address)
                        else Windows.act("toggle", tab.modelData.address)
                    }
                }
            }
        }
    }
}
