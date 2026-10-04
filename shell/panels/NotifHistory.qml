import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

// Right-hand panel listing every notice still on record.
PanelWindow {
    id: win
    readonly property bool shown: Shell.open === "notifications"
    visible: shown
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "overwatch-panel"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onShownChanged: if (shown) { slide.restart(); burst.fire(); panel.forceActiveFocus() }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.03, 0.04, 0.28)
        TapHandler { onTapped: point => { var p = point.position; if (p.x < panel.x || p.x > panel.x + panel.width || p.y < panel.y || p.y > panel.y + panel.height) Shell.close() } }
    }

    Item {
        id: panel
        width: 440
        // pinned to the right edge; the slide-in only offsets it, so it can never rest in the wrong place
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right; topMargin: 10; bottomMargin: 10; rightMargin: 10 }
        transform: Translate { id: shift; x: 0 }
        focus: true
        Keys.onEscapePressed: Shell.close()
        NumberAnimation { id: slide; target: shift; property: "x"; from: panel.width + 20; to: 0; duration: 170; easing.type: Easing.OutCubic }

        Chamfer { anchors.fill: parent; cut: 14; tr: false; br: false; fillColor: Theme.panelSolid }
        Backdrop { role: "panel_history"; anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1; leftMargin: 15 } height: 150 }
        StaticBurst { id: burst; anchors.fill: parent; anchors.margins: 1; anchors.leftMargin: 15 }
        TapHandler { }

        Item {
            id: head
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            height: 40
            Column {
                spacing: 1
                Text {
                    text: Theme.t("DISPATCH LOG", "Notifications")
                    color: Theme.white
                    font.family: Theme.label; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 2
                }
                DecodeText { target: Notifs.history.values.length + Theme.t(" NOTICES ON RECORD", " notifications"); color: Theme.muted; font.pixelSize: 10 }
            }
            Row {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                spacing: 8
                Item {
                    width: dndLbl.implicitWidth + 18; height: 24
                    Chamfer { anchors.fill: parent; cut: 5; tr: false; bl: false; fillColor: Notifs.dnd ? Theme.amber : "transparent"; strokeColor: Notifs.dnd ? Theme.amber : Theme.tealDim }
                    Label { id: dndLbl; anchors.centerIn: parent; text: Theme.t("SILENCE", "Do not disturb"); color: Notifs.dnd ? Theme.base : Theme.teal }
                    TapHandler { onTapped: { Shell.fx("click"); Notifs.dnd = !Notifs.dnd } }
                }
                Item {
                    width: clrLbl.implicitWidth + 18; height: 24
                    Chamfer { anchors.fill: parent; cut: 5; tr: false; bl: false; fillColor: "transparent"; strokeColor: Theme.tealDim }
                    Label { id: clrLbl; anchors.centerIn: parent; text: Theme.t("PURGE", "Clear all"); color: Theme.teal }
                    TapHandler { onTapped: { Shell.fx("click"); Notifs.clearAll() } }
                }
            }
        }

        ListView {
            id: list
            anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom; margins: 20; topMargin: 10 }
            clip: true
            spacing: 8
            model: Notifs.history
            verticalLayoutDirection: ListView.TopToBottom
            delegate: NotifCard { required property var modelData; n: modelData; popup: false; width: list.width }
        }
        Image {
            anchors.centerIn: list
            anchors.verticalCenterOffset: -60
            visible: list.count === 0 && !Theme.stealth && status === Image.Ready
            width: 150; height: 150
            source: Assets.ui("spray")
            fillMode: Image.PreserveAspectFit
            opacity: 0.35
        }
        Label {
            anchors.centerIn: list
            visible: list.count === 0
            text: Theme.t("NO NOTICES", "No notifications")
            color: Theme.faint
        }
    }
}
