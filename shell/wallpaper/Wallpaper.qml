import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.services

// Background layer: Half-Life 2 chapter art, cycled with SUPER+SHIFT+W.
PanelWindow {
    id: root
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Background
    WlrLayershell.namespace: "overwatch-wallpaper"
    color: "#0a0f14"

    Image {
        id: art
        anchors.fill: parent
        source: Assets.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        visible: Assets.wallpaperSource !== "" && status === Image.Ready
        asynchronous: true
        smooth: true
        mipmap: true
    }
    // A scanner drifting across now and then, searchlight sweeping
    Item {
        id: scanner
        visible: !Assets.stealth && pass.running
        y: root.height * 0.22
        width: 26; height: 12
        Rectangle { anchors.centerIn: parent; width: 22; height: 7; radius: 2; color: "#0b1116" }
        Rectangle { anchors.centerIn: parent; width: 5; height: 5; radius: 3; color: "#e6f6fa" }
        Rectangle {
            x: 10; y: 6; width: 3; height: root.height * 0.5
            transformOrigin: Item.Top
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0.9, 0.97, 1.0, 0.22) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            SequentialAnimation on rotation {
                loops: Animation.Infinite; running: pass.running
                NumberAnimation { from: -16; to: 16; duration: 2600; easing.type: Easing.InOutSine }
                NumberAnimation { from: 16; to: -16; duration: 2600; easing.type: Easing.InOutSine }
            }
        }
        ParallelAnimation {
            id: pass
            NumberAnimation { target: scanner; property: "x"; from: -40; to: root.width + 40; duration: 26000 }
            SequentialAnimation {
                NumberAnimation { target: scanner; property: "y"; to: root.height * 0.16; duration: 13000; easing.type: Easing.InOutSine }
                NumberAnimation { target: scanner; property: "y"; to: root.height * 0.26; duration: 13000; easing.type: Easing.InOutSine }
            }
        }
        Timer {
            interval: 150000; repeat: true
            running: !Assets.stealth && !UPower.onBattery
            onTriggered: { scanner.y = root.height * (0.14 + Math.random() * 0.2); pass.restart() }
        }
    }

    // Stealth: a plain neutral backdrop over everything else
    Rectangle {
        anchors.fill: parent
        visible: Assets.stealth
        z: 10
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2b323b" }
            GradientStop { position: 1.0; color: "#1b1f25" }
        }
    }
    // keeps bar and window edges readable over bright art
    Rectangle {
        anchors.fill: parent
        visible: art.visible
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.02, 0.04, 0.06, 0.55) }
            GradientStop { position: 0.18; color: Qt.rgba(0.02, 0.04, 0.06, 0.10) }
            GradientStop { position: 0.82; color: Qt.rgba(0.02, 0.04, 0.06, 0.10) }
            GradientStop { position: 1.0; color: Qt.rgba(0.02, 0.04, 0.06, 0.55) }
        }
    }
}
