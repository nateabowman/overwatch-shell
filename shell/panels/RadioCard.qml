import QtQuick
import qs.core
import qs.services

// City 17 radio controls, shown inside the control panel.
Column {
    spacing: 6
    visible: Radio.tracks.length > 0 && !Theme.stealth
    Label { text: "CITY 17 BROADCAST  //  " + Radio.tracks.length + " RECORDINGS" }
    Item {
        width: parent.width; height: 44
        Chamfer { anchors.fill: parent; cut: 7; tr: false; bl: false; fillColor: Radio.playing ? Theme.fill : "transparent"; strokeColor: Radio.playing ? Theme.teal : Theme.faint }
        DecodeText {
            anchors { left: parent.left; leftMargin: 12; right: buttons.left; rightMargin: 8; verticalCenter: parent.verticalCenter }
            target: Radio.playing ? Radio.title.toUpperCase() : "TRANSMITTER IDLE"
            color: Radio.playing ? Theme.white : Theme.muted
            elide: Text.ElideRight
            font.pixelSize: 12
        }
        Row {
            id: buttons
            anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
            spacing: 6
            Repeater {
                model: [ { t: Radio.playing ? "HALT" : "TRANSMIT", f: () => Radio.toggle() }, { t: "NEXT", f: () => Radio.next() } ]
                delegate: Item {
                    id: btn
                    required property var modelData
                    width: lbl.implicitWidth + 16; height: 26
                    Chamfer { anchors.fill: parent; cut: 5; tr: false; bl: false; fillColor: bh.hovered ? Theme.fill : "transparent"; strokeColor: Theme.tealDim }
                    Label { id: lbl; anchors.centerIn: parent; text: btn.modelData.t; color: Theme.teal }
                    HoverHandler { id: bh; cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: { Shell.fx("click"); btn.modelData.f() } }
                }
            }
        }
    }
}
