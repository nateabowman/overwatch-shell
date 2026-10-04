import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.core
import qs.services

// Live audio levels from cava, shown only while something is playing.
Item {
    id: root
    readonly property int bars: 16
    property var levels: []
    readonly property bool active: !Theme.stealth && (Radio.playing || Mpris.players.values.some(p => p.isPlaying))
    visible: active && levels.length > 0
    implicitWidth: visible ? bars * 4 + 4 : 0
    implicitHeight: 16

    Process {
        running: root.active
        command: ["sh", "-c", "printf '[general]\\nbars=" + root.bars + "\\nframerate=24\\n[output]\\nmethod=raw\\nraw_target=/dev/stdout\\ndata_format=ascii\\nascii_max_range=8\\n' > \"$XDG_RUNTIME_DIR/overwatch-cava.conf\"; exec cava -p \"$XDG_RUNTIME_DIR/overwatch-cava.conf\""]
        stdout: SplitParser { onRead: line => root.levels = line.split(";").slice(0, root.bars).map(v => parseInt(v) || 0) }
        onRunningChanged: if (!running) root.levels = []
    }
    Row {
        anchors.bottom: parent.bottom
        spacing: 2
        Repeater {
            model: root.levels
            Rectangle {
                required property var modelData
                width: 2; height: 2 + modelData * 1.7
                anchors.bottom: parent.bottom
                color: Theme.teal
            }
        }
    }
}
