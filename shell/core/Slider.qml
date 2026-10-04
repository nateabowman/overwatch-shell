import QtQuick
import qs.core

// Segmented level control. Drag or click to set; emits moved(value 0..1).
Item {
    id: root
    property real value: 0
    property color tone: Theme.teal
    property int segments: 28
    signal moved(real value)
    implicitHeight: 18

    Row {
        id: row
        anchors.fill: parent
        spacing: 2
        Repeater {
            model: root.segments
            Rectangle {
                required property int index
                width: (row.width - (root.segments - 1) * row.spacing) / root.segments
                height: row.height
                radius: Theme.stealth ? 2 : 0
                color: index < Math.round(root.value * root.segments) ? root.tone : Theme.faint
            }
        }
    }
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        function set(x) { root.moved(Math.max(0, Math.min(1, x / width))) }
        onPressed: mouse => set(mouse.x)
        onPositionChanged: mouse => { if (pressed) set(mouse.x) }
        onWheel: wheel => root.moved(Math.max(0, Math.min(1, root.value + (wheel.angleDelta.y > 0 ? 0.04 : -0.04))))
    }
}
