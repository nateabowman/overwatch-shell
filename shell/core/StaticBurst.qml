import QtQuick
import qs.services

// A few frames of real broadcast static that fade out. Call fire().
Item {
    id: root
    property int frame: 0
    clip: true
    visible: fade.running
    function fire() { if (Assets.stealth) return; frame = 0; fade.restart(); cycle.restart() }
    Image {
        anchors.fill: parent
        source: Assets.ui("static_" + root.frame)
        fillMode: Image.Tile
        smooth: false
    }
    Timer { id: cycle; interval: 45; repeat: true; onTriggered: { root.frame = (root.frame + 1) % 4; if (!fade.running) stop() } }
    NumberAnimation { id: fade; target: root; property: "opacity"; from: 0.42; to: 0; duration: 260 }
}
