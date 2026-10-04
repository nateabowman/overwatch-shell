import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

// Stack of live notices in the top-right corner.
PanelWindow {
    visible: Notifs.popups.length > 0 && Shell.open !== "notifications"
    anchors { top: true; right: true }
    margins { top: 10; right: 10 }
    implicitWidth: 400
    implicitHeight: Math.max(1, stack.implicitHeight)
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "overwatch-notify"

    Column {
        id: stack
        width: parent.width
        spacing: 8
        Repeater {
            model: Notifs.popups
            delegate: NotifCard { required property var modelData; n: modelData; width: stack.width }
        }
    }
}
