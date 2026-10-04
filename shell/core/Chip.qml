import QtQuick
import qs.core
import qs.services

// Toggle tile: a caption, a state line, and an on/off fill.
Item {
    id: root
    property string title: ""
    property string state: ""
    property bool on: false
    property color tone: Theme.teal
    signal tapped()
    implicitHeight: 46

    Chamfer {
        anchors.fill: parent
        cut: 7; tr: false; bl: false
        fillColor: root.on ? Qt.rgba(root.tone.r, root.tone.g, root.tone.b, hover.hovered ? 0.34 : 0.24) : (hover.hovered ? Theme.fill : "transparent")
        strokeColor: root.on ? root.tone : Theme.faint
    }
    Column {
        anchors { left: parent.left; leftMargin: 11; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
        spacing: 1
        Label { text: root.title; color: root.on ? Theme.white : Theme.text; width: parent.width; elide: Text.ElideRight }
        Text {
            text: root.state
            color: root.on ? root.tone : Theme.muted
            width: parent.width; elide: Text.ElideRight
            font.family: Theme.mono; font.pixelSize: 11
        }
    }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor; onHoveredChanged: if (hovered) Shell.fx("hover") }
    TapHandler { onTapped: { Shell.fx("click"); root.tapped() } }
}
