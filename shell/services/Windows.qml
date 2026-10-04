pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

// Every open window, for the taskbar and the window controls in the top bar.
Singleton {
    id: root
    property var list: []        // { address, cls, title, ws, minimized, maximized, active }
    property var active: null
    // Title bars from the hyprbars plugin: height (0 = plugin not loaded) and the
    // classes that get none. Written by ~/.config/hypr/config/titlebars.lua.
    property int barHeight: 0
    property var nobar: /^$/
    function barFor(cls) { return barHeight > 0 && cls && !nobar.test(cls) ? barHeight : 0 }
    FileView {
        path: Quickshell.env("HOME") + "/.local/state/overwatch/titlebars"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.barHeight = parseInt(text()) || 0
        onLoadFailed: root.barHeight = 0
    }
    FileView {
        path: Qt.resolvedUrl("../nobar.txt").toString().replace("file://", "")
        onLoaded: root.nobar = new RegExp(text().trim())
    }
    // Addresses left out of the taskbar and switcher (one per line). demo/owdemo writes this
    // while it records, so windows that were already open stay out of the picture.
    property string hidden: ""
    FileView {
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/overwatch-hidden"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: { root.hidden = text(); root.poll() }
        onLoadFailed: { root.hidden = ""; root.poll() }
    }
    readonly property string tool: Qt.resolvedUrl("../scripts/owwin").toString().replace("file://", "")

    function act(cmd, address) {
        var args = [tool, cmd]
        if (address) args.push(address)
        Quickshell.execDetached(args)
    }
    function dispatch(lua) { Quickshell.execDetached(["hyprctl", "dispatch", lua]) }

    Process {
        id: query
        command: ["hyprctl", "clients", "-j"]
        property string buf: ""
        stdout: SplitParser { splitMarker: ""; onRead: data => query.buf += data }
        onRunningChanged: {
            if (running) { buf = ""; return }
            try {
                var raw = JSON.parse(buf)
                var out = [], act = null
                for (var i = 0; i < raw.length; i++) {
                    var c = raw[i]
                    if (!c.mapped || (!c.title && !c.class)) continue
                    if (root.hidden.indexOf(c.address) >= 0) continue
                    var min = c.workspace.name === "special:minimized"
                    var w = {
                        address: c.address, cls: c.class || c.initialClass || "", title: c.title || c.class,
                        ws: c.workspace.name, minimized: min, maximized: c.fullscreen === 1,
                        active: c.focusHistoryID === 0 && !min
                    }
                    if (w.active) act = w
                    out.push(w)
                }
                root.list = out
                root.active = act
            } catch (e) { }
        }
    }
    function poll() { if (!query.running) query.running = true; else again.start() }
    Timer { id: again; interval: 120; onTriggered: root.poll() }
    Timer { id: soon; interval: 60; onTriggered: root.poll() }
    Timer { id: titles; interval: 700; onTriggered: root.poll() }
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            var n = event.name
            if (n === "windowtitlev2") { if (!titles.running) titles.start(); return }
            if (n === "minimized") {
                var p = event.data.split(",")
                if (p[1] === "1") root.act("minimize", "0x" + p[0])
            }
            if (n === "activewindowv2" || n === "openwindow" || n === "closewindow" || n === "movewindowv2"
                || n === "fullscreen" || n === "workspacev2" || n === "minimized") soon.restart()
        }
    }
    Component.onCompleted: poll()
}
