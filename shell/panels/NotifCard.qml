import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import qs.core
import qs.services

// One dispatch notice. Used by both the popup stack and the history panel.
Item {
    id: card
    required property var n
    property bool popup: true
    readonly property bool critical: n && n.urgency === NotificationUrgency.Critical
    readonly property color tone: critical ? Theme.red : Theme.teal
    implicitHeight: body.implicitHeight + 22

    Chamfer {
        anchors.fill: parent
        cut: 10; tl: false; br: false
        fillColor: Theme.panelSolid
        strokeColor: card.critical ? Theme.red : Theme.line
    }
    Image {
        anchors.fill: parent; anchors.margins: 1; anchors.rightMargin: 11
        visible: card.critical && status === Image.Ready && !Theme.stealth
        source: card.critical ? Assets.ui("panel_alert") : ""
        fillMode: Image.PreserveAspectCrop
        opacity: 0.26
    }
    Rectangle { x: 1; y: 1; width: 3; height: parent.height - 12; color: card.tone }

    Column {
        id: body
        anchors { left: parent.left; right: parent.right; top: parent.top; leftMargin: 16; rightMargin: 14; topMargin: 10 }
        spacing: 3

        Item {
            width: parent.width; height: 14
            Label {
                text: Theme.stealth ? ((card.n && card.n.appName) || "Notification") : (card.critical ? "PRIORITY ALERT // " : "DISPATCH // ") + ((card.n && card.n.appName) || "UNKNOWN").toUpperCase()
                color: card.tone
                width: parent.width - 40
                elide: Text.ElideRight
            }
            Label { anchors.right: parent.right; text: "✕"; color: Theme.muted; font.family: Theme.mono
                TapHandler { onTapped: if (card.n) card.n.dismiss() } }
        }
        DecodeText {
            width: parent.width
            target: card.n ? card.n.summary : ""
            color: Theme.white
            font.family: Theme.label; font.pixelSize: 16; font.weight: Font.DemiBold
            elide: Text.ElideRight
            stepMs: card.popup ? 22 : 1
            charsPerStep: card.popup ? 2 : 400
        }
        Text {
            width: parent.width
            visible: text.length > 0
            text: card.n ? card.n.body : ""
            color: Theme.text
            wrapMode: Text.Wrap
            maximumLineCount: card.popup ? 3 : 6
            elide: Text.ElideRight
            textFormat: Text.PlainText
            font.family: Theme.mono; font.pixelSize: 12
        }
        Row {
            spacing: 6
            topPadding: 4
            visible: !!card.n && card.n.actions.length > 0
            Repeater {
                model: card.n ? card.n.actions : []
                delegate: Item {
                    id: act
                    required property var modelData
                    width: lbl.implicitWidth + 18; height: 22
                    Chamfer { anchors.fill: parent; cut: 4; tr: false; bl: false; fillColor: ah.hovered ? Theme.fill : "transparent"; strokeColor: Theme.tealDim }
                    Label { id: lbl; anchors.centerIn: parent; text: act.modelData.text.toUpperCase(); color: Theme.teal }
                    HoverHandler { id: ah }
                    TapHandler { onTapped: act.modelData.invoke() }
                }
            }
        }
    }

    TapHandler { acceptedButtons: Qt.RightButton; onTapped: card.n.dismiss() }

    Timer {
        running: card.popup && !card.critical && !hold.hovered
        interval: card.n && card.n.expireTimeout > 0 ? card.n.expireTimeout : 6000
        onTriggered: Notifs.drop(card.n)
    }
    HoverHandler { id: hold }

    NumberAnimation on opacity { from: 0; to: 1; duration: 160 }
}
