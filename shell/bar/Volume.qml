import QtQuick
import Quickshell.Services.Pipewire
import qs.core

// Output volume. Scroll to change, click to mute.
Item {
    id: root
    readonly property var sink: Pipewire.defaultAudioSink
    readonly property bool muted: sink && sink.audio ? sink.audio.muted : false
    readonly property int pct: sink && sink.audio ? Math.round(sink.audio.volume * 100) : 0
    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight

    PwObjectTracker { objects: [root.sink] }

    Readout {
        id: row
        label: Theme.t("AUDIO", "Volume")
        value: root.muted ? Theme.t("MUTE", "muted") : root.pct + "%"
        valueColor: root.muted ? Theme.amber : Theme.text
    }
    TapHandler { acceptedButtons: Qt.MiddleButton; onTapped: if (root.sink && root.sink.audio) root.sink.audio.muted = !root.sink.audio.muted }
    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            if (!root.sink || !root.sink.audio) return
            var d = event.angleDelta.y > 0 ? 0.02 : -0.02
            root.sink.audio.volume = Math.max(0, Math.min(1, root.sink.audio.volume + d))
        }
    }
}
