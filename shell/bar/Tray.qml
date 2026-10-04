import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Services.SystemTray
import qs.core
import qs.services

Row {
    id: root
    required property var window
    spacing: 6
    Repeater {
        model: SystemTray.items
        delegate: IconImage {
            id: icon
            required property var modelData
            anchors.verticalCenter: parent.verticalCenter
            implicitSize: 16
            source: modelData.icon
            readonly property string about: (modelData.tooltipTitle || modelData.title || modelData.id || "Tray item")
                + (modelData.tooltipDescription ? "\n" + modelData.tooltipDescription.replace(/<[^>]+>/g, "") : "")
                + "\n" + Theme.t("LEFT CLICK: OPEN   RIGHT CLICK: MENU", "Left click: open, right click: menu")
            HoverHandler {
                cursorShape: Qt.PointingHandCursor
                onHoveredChanged: hovered ? Shell.tip(icon.about, icon) : Shell.untip(icon.about)
            }
            TapHandler {
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onTapped: (point, button) => {
                    if (button === Qt.LeftButton && !icon.modelData.onlyMenu) {
                        icon.modelData.activate()
                    } else if (icon.modelData.hasMenu) {
                        var p = icon.mapToItem(null, 0, icon.height + 6)
                        icon.modelData.display(root.window, p.x, p.y)
                    }
                }
            }
        }
    }
}
