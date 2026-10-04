pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// CPU, memory and network state, fed by scripts/sysmon.sh.
Singleton {
    id: root
    property int cpu: 0
    property int mem: 0
    property int gpu: 0
    property string netType: "none"
    property string netName: ""
    // While demo/owdemo records, network and device names are shown as stand-ins
    // (the file below exists only during a take). Nothing but the displayed text changes.
    property bool masked: false
    readonly property string shownNet: masked && netName.length ? "C17-UPLINK-01" : netName
    function alias(kind, name, index) { return masked ? kind + "-" + ("0" + (index + 1)).slice(-2) : name }
    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/overwatch-demo-mask"
        blockLoading: true
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: root.masked = true
        onLoadFailed: root.masked = false
    }
    property var cpuHist: []
    property var memHist: []
    readonly property int histLen: 30

    function _push(arr, v) {
        var a = arr.slice(-(histLen - 1))
        a.push(v)
        return a
    }

    Process {
        running: true
        command: ["bash", Qt.resolvedUrl("../scripts/sysmon.sh").toString().replace("file://", "")]
        stdout: SplitParser {
            onRead: line => {
                var m = line.match(/^(\d+) (\d+) (\d+) ([^:]*):(.*)$/)
                if (!m) return
                root.cpu = parseInt(m[1])
                root.mem = parseInt(m[2])
                root.gpu = parseInt(m[3])
                root.netType = m[4]
                root.netName = m[5]
                root.cpuHist = root._push(root.cpuHist, root.cpu)
                root.memHist = root._push(root.memHist, root.mem)
            }
        }
    }
}
