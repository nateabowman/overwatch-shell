import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import qs.core
import qs.services

// Left-hand terminal panel. Two modes: application index and clipboard records.
PanelWindow {
    id: win
    readonly property bool emoji: Shell.open === "emoji"
    readonly property bool clip: Shell.open === "clipboard" || emoji     // list mode without icons
    readonly property bool shown: Shell.open === "launcher" || clip
    property var emojiData: []
    property var results: []
    property var clipLines: []

    visible: shown
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "overwatch-panel"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function score(text, q) {
        var t = text.toLowerCase()
        var i = t.indexOf(q)
        if (i === 0) return 100
        if (i > 0) return t.charAt(i - 1) === " " ? 80 : 60 - Math.min(i, 30)
        var k = 0
        for (var j = 0; j < t.length && k < q.length; j++) if (t.charAt(j) === q.charAt(k)) k++
        return k === q.length ? 10 : -1
    }

    function refresh() {
        var q = input.text.trim().toLowerCase()
        var out = []
        if (emoji) {
            for (var k = 0; k < emojiData.length && out.length < 80; k++) {
                var em = emojiData[k]
                if (!q.length || em.name.indexOf(q) >= 0 || (em.keywords || []).some(w => w.indexOf(q) >= 0))
                    out.push({ name: em.emoji + "   " + em.name, sub: "", icon: "", id: em.emoji, s: 0 })
            }
        } else if (clip) {
            for (var i = 0; i < clipLines.length; i++) {
                var tab = clipLines[i].indexOf("\t")
                var body = clipLines[i].substring(tab + 1)
                if (!q.length || body.toLowerCase().indexOf(q) >= 0)
                    out.push({ name: body, sub: "", icon: "", id: clipLines[i].substring(0, tab), s: 0 })
                if (out.length >= 60) break
            }
        } else {
            var apps = DesktopEntries.applications.values
            for (var a = 0; a < apps.length; a++) {
                var e = apps[a]
                if (e.noDisplay) continue
                var s = q.length ? Math.max(score(e.name, q), score(e.genericName || "", q) - 20) : 1
                if (s >= 0) out.push({ name: e.name, sub: e.genericName || e.comment || "", icon: e.icon, entry: e, s: s })
            }
            out.sort((x, y) => y.s - x.s || x.name.localeCompare(y.name))
        }
        results = out
        list.currentIndex = 0
    }

    function activate(item) {
        if (!item) return
        Shell.fx("select")
        if (emoji) Quickshell.execDetached(["wl-copy", item.id])
        else if (clip) Shell.run("cliphist decode " + item.id + " | wl-copy")
        else item.entry.execute()
        Shell.close()
    }

    onShownChanged: {
        if (!shown) return
        input.text = ""
        if (emoji) { if (!emojiData.length) emojiFile.reload() }
        else if (clip) { clipLines = []; clipProc.running = true }
        refresh()
        slide.restart()
        burst.fire()
        input.forceActiveFocus()
    }

    Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { if (win.shown && !win.clip) win.refresh() }
    }

    FileView {
        id: emojiFile
        path: "/usr/share/noctalia/assets/emoji.json"
        onLoaded: { try { win.emojiData = JSON.parse(text()) } catch (e) { } if (win.emoji) win.refresh() }
    }
    Process {
        id: clipProc
        command: ["cliphist", "list"]
        property var buf: []
        stdout: SplitParser { onRead: line => clipProc.buf.push(line) }
        onRunningChanged: {
            if (running) { buf = [] } else { win.clipLines = buf; win.refresh() }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.03, 0.04, 0.28)
        TapHandler { onTapped: point => { var p = point.position; if (p.x < panel.x || p.x > panel.x + panel.width || p.y < panel.y || p.y > panel.y + panel.height) Shell.close() } }
    }

    Item {
        id: panel
        width: 440
        anchors { top: parent.top; bottom: parent.bottom; topMargin: 10; bottomMargin: 10 }
        x: 10
        transform: Translate { id: shift; x: 0 }

        NumberAnimation { id: slide; target: shift; property: "x"; from: -panel.width - 20; to: 0; duration: 170; easing.type: Easing.OutCubic }

        Chamfer { anchors.fill: parent; cut: 14; tl: false; bl: false; fillColor: Theme.panelSolid }
        Backdrop { role: "panel_launcher"; anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1; rightMargin: 15 } height: 190 }
        StaticBurst { id: burst; anchors.fill: parent; anchors.margins: 1; anchors.rightMargin: 15 }
        TapHandler { }  // swallow clicks so the backdrop does not close the panel

        // side rule with tick marks
        Column {
            anchors { right: parent.right; rightMargin: 6; verticalCenter: parent.verticalCenter }
            spacing: 9
            Repeater { model: Theme.stealth ? 0 : 14; Rectangle { width: index % 4 === 0 ? 8 : 4; height: 1; color: Theme.tealDim; anchors.right: parent.right } }
        }

        Column {
            id: head
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 20 }
            spacing: 10

            Row {
                spacing: 10
                Emblem { implicitWidth: 22; implicitHeight: 22; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    spacing: 1
                    Text {
                        text: Theme.t("CIVIL PROTECTION TERMINAL", win.emoji ? "Emoji" : win.clip ? "Clipboard" : "Applications")
                        color: Theme.white
                        font.family: Theme.label; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 2
                    }
                    DecodeText {
                        target: Theme.stealth ? "Type to search" : (win.emoji ? "GLYPH INDEX // SUPER+PERIOD" : win.clip ? "CLIPBOARD RECORDS // SUPER+V" : "APPLICATION INDEX // SUPER+SPACE")
                        color: Theme.muted
                        font.pixelSize: 10
                    }
                }
            }
            Text {
                visible: Theme.glyphs !== ""
                text: "civil protection index"
                color: Theme.teal
                opacity: 0.55
                font.family: Theme.glyphs; font.pixelSize: 11; font.letterSpacing: 1
            }

            Item {
                width: parent.width; height: 34
                Chamfer { anchors.fill: parent; cut: 6; tr: false; bl: false; fillColor: Theme.fill; strokeColor: Theme.teal }
                Label { id: qlabel; text: Theme.t("QUERY", "Search"); color: Theme.teal; anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter } }
                TextInput {
                    id: input
                    anchors { left: qlabel.right; leftMargin: 10; right: parent.right; rightMargin: 10; verticalCenter: parent.verticalCenter }
                    color: Theme.white
                    selectionColor: Theme.teal
                    selectedTextColor: Theme.base
                    font.family: Theme.mono; font.pixelSize: 15
                    clip: true
                    cursorDelegate: Rectangle { width: 8; color: Theme.teal; opacity: 0.8 }
                    onTextChanged: win.refresh()
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) { Shell.close(); event.accepted = true }
                        else if (event.key === Qt.Key_Down || (event.key === Qt.Key_Tab)) { list.incrementCurrentIndex(); event.accepted = true }
                        else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) { list.decrementCurrentIndex(); event.accepted = true }
                        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) { win.activate(win.results[list.currentIndex]); event.accepted = true }
                    }
                }
            }
        }

        ListView {
            id: list
            anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: power.top; leftMargin: 20; rightMargin: 20; topMargin: 12; bottomMargin: 10 }
            clip: true
            model: win.results
            spacing: 2
            highlightMoveDuration: 0
            onCurrentIndexChanged: if (win.shown) Shell.fx("move")
            delegate: Item {
                id: row
                required property var modelData
                required property int index
                readonly property bool current: ListView.isCurrentItem
                width: list.width
                height: win.clip ? 30 : 40

                Rectangle { anchors.fill: parent; color: row.current ? Theme.fill : "transparent" }
                Rectangle { width: 2; height: parent.height; color: row.current ? Theme.teal : "transparent" }

                Text {
                    id: num
                    anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    text: ("00" + (row.index + 1)).slice(-3)
                    color: row.current ? Theme.teal : Theme.faint
                    font.family: Theme.mono; font.pixelSize: 11
                }
                IconImage {
                    id: icon
                    visible: !win.clip
                    anchors { left: num.right; leftMargin: 10; verticalCenter: parent.verticalCenter }
                    implicitSize: win.clip ? 0 : 24
                    source: win.clip || !row.modelData.icon ? "" : Quickshell.iconPath(row.modelData.icon, true)
                }
                Column {
                    anchors { left: icon.right; leftMargin: win.clip ? 0 : 10; right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                    spacing: -1
                    Text {
                        width: parent.width
                        text: row.modelData.name
                        color: row.current ? Theme.white : Theme.text
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        font.family: win.emoji ? Theme.plainFont : win.clip ? Theme.mono : Theme.label
                        font.pixelSize: win.emoji ? 15 : win.clip ? 12 : 15
                        font.weight: Font.DemiBold
                        font.letterSpacing: win.clip ? 0 : 0.6
                    }
                    Text {
                        width: parent.width
                        visible: !win.clip && text.length > 0
                        text: row.modelData.sub
                        color: Theme.muted
                        elide: Text.ElideRight
                        font.family: Theme.mono; font.pixelSize: 10
                    }
                }
                HoverHandler { onHoveredChanged: if (hovered) list.currentIndex = row.index }
                TapHandler { onTapped: win.activate(row.modelData) }
            }
        }

        // Power controls: each opens the session panel on that action (countdown for the destructive ones)
        Row {
            id: power
            anchors { left: parent.left; right: parent.right; bottom: foot.top; leftMargin: 20; rightMargin: 20; bottomMargin: 10 }
            spacing: 6
            Repeater {
                model: [ { a: "SEAL", b: "Lock", i: 0 }, { a: "STASIS", b: "Sleep", i: 2 }, { a: "RELOCATE", b: "Log out", i: 1 },
                         { a: "RECYCLE", b: "Restart", i: 3 }, { a: "AMPUTATE", b: "Shut down", i: 4 } ]
                delegate: Item {
                    id: pb
                    required property var modelData
                    readonly property color tone: modelData.i === 4 ? Theme.red : Theme.teal
                    width: (power.width - 4 * power.spacing) / 5; height: 40
                    Chamfer { anchors.fill: parent; cut: 6; tr: false; bl: false
                        fillColor: ph.hovered ? Qt.rgba(pb.tone.r, pb.tone.g, pb.tone.b, 0.22) : "transparent"
                        strokeColor: ph.hovered ? pb.tone : Theme.faint }
                    Column {
                        anchors.centerIn: parent
                        spacing: 0
                        Label { anchors.horizontalCenter: parent.horizontalCenter; text: Theme.t(pb.modelData.a, pb.modelData.b); color: ph.hovered ? pb.tone : Theme.text; font.pixelSize: 10 }
                        Label { anchors.horizontalCenter: parent.horizontalCenter; visible: !Theme.stealth; text: pb.modelData.b.toUpperCase(); color: Theme.muted; font.pixelSize: 8 }
                    }
                    HoverHandler { id: ph; cursorShape: Qt.PointingHandCursor; onHoveredChanged: if (hovered) Shell.fx("hover") }
                    TapHandler { onTapped: Shell.sessionRequested(pb.modelData.i) }
                }
            }
        }
        Row {
            id: foot
            anchors { left: parent.left; bottom: parent.bottom; margins: 20 }
            spacing: 14
            Label { text: win.results.length + Theme.t(" RECORDS", " results") }
            Label { text: Theme.t("ENTER  EXECUTE", "Enter to open"); color: Theme.faint }
            Label { text: Theme.t("ESC  DISMISS", "Esc to close"); color: Theme.faint }
        }
    }
}
