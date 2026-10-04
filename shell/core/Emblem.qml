import QtQuick
import QtQuick.Effects
import qs.core

// The Combine claw (assets/claw.svg, built by scripts/make-emblem.py from the game's own
// poster art), tinted with `color`. Stealth mode shows a plain app-grid icon instead.
Item {
    id: root
    property color color: Theme.teal
    implicitWidth: 18
    implicitHeight: 18

    Image {
        id: claw
        anchors.fill: parent
        visible: false
        source: Qt.resolvedUrl("../assets/claw.svg")
        sourceSize: Qt.size(Math.ceil(root.width * 2), Math.ceil(root.height * 2))
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
    MultiEffect {
        anchors.fill: parent
        visible: !Theme.stealth
        source: claw
        colorization: 1
        colorizationColor: root.color
    }
    Grid {
        anchors.fill: parent
        visible: Theme.stealth
        columns: 2
        spacing: root.width * 0.14
        Repeater {
            model: 4
            Rectangle { width: (root.width - root.width * 0.14) / 2; height: width; color: root.color }
        }
    }
}
