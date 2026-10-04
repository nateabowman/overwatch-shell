import QtQuick
import qs.core
import qs.services

// Real Combine display art, dimmed and faded into the panel colour at the bottom.
Item {
    id: root
    property string role: ""
    property real strength: 0.34
    clip: true
    Image {
        id: art
        anchors.fill: parent
        source: Assets.ui(root.role)
        fillMode: Image.PreserveAspectCrop
        opacity: root.strength
        visible: status === Image.Ready && !Theme.stealth
    }
    Rectangle {
        anchors.fill: parent
        visible: art.visible
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: Theme.panelSolid }
        }
    }
}
