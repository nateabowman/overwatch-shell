import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core
import qs.services

// Session menu. Each directive shows the Overwatch verb and the plain action.
PanelWindow {
    id: win
    readonly property bool shown: Shell.open === "session"
    property int current: 0
    property int pending: -1      // index counting down, or -1
    property int remaining: 0

    readonly property var actions: [
        { verb: "SEAL SECTOR", plain: "Lock",      wait: 0, danger: false, cmd: "" },
        { verb: "RELOCATE",    plain: "Log out",   wait: 0, danger: false, cmd: "uwsm check is-active && uwsm stop || hyprctl dispatch \"hl.dsp.exit()\"" },
        { verb: "STASIS",      plain: "Suspend",   wait: 3, danger: false, cmd: "systemctl suspend" },
        { verb: "RECYCLE",     plain: "Reboot",    wait: 3, danger: false, cmd: "systemctl reboot" },
        { verb: "AMPUTATE",    plain: "Shut down", wait: 3, danger: true,  cmd: "systemctl poweroff" }
    ]

    visible: shown
    anchors { top: true; bottom: true; left: true; right: true }
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "overwatch-panel"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    function execute(i) {
        var a = actions[i]
        Shell.close()
        if (i === 0 || i === 2) Shell.lockRequested()
        if (a.cmd.length) Shell.run((i === 2 ? "sleep 1; " : "") + a.cmd)
    }
    onCurrentChanged: if (shown) Shell.fx("move")
    function choose(i) {
        if (pending >= 0) return
        Shell.fx("select")
        current = i
        if (actions[i].wait > 0) { pending = i; remaining = actions[i].wait; countdown.restart() }
        else execute(i)
    }
    function cancel() {
        if (pending >= 0) { countdown.stop(); pending = -1 } else Shell.close()
    }
    onShownChanged: { countdown.stop(); pending = -1; current = 0; if (shown) { keys.forceActiveFocus(); pop.restart(); burst.fire() } }

    // Asked for from the launcher's power row: open on that action and start it
    Connections {
        target: Shell
        function onSessionRequested(index) { Shell.open = "session"; win.choose(index) }
    }
    Timer {
        id: countdown
        interval: 1000; repeat: true
        onTriggered: {
            win.remaining -= 1
            if (win.remaining <= 0) { stop(); var i = win.pending; win.pending = -1; win.execute(i) }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.03, 0.04, 0.55)
        TapHandler { onTapped: point => { var p = point.position; if (p.x < keys.x || p.x > keys.x + keys.width || p.y < keys.y || p.y > keys.y + keys.height) win.cancel() } }
    }

    Item {
        id: keys
        anchors.centerIn: parent
        width: 460
        height: body.implicitHeight + 44
        focus: true
        NumberAnimation { id: pop; target: keys; property: "scale"; from: 0.94; to: 1; duration: 140; easing.type: Easing.OutCubic }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) win.cancel()
            else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) { if (win.pending < 0) win.current = (win.current + 1) % win.actions.length }
            else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) { if (win.pending < 0) win.current = (win.current + win.actions.length - 1) % win.actions.length }
            else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) win.choose(win.current)
            else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_5) win.choose(event.key - Qt.Key_1)
            event.accepted = true
        }

        Chamfer { anchors.fill: parent; cut: 16; tr: false; bl: false; fillColor: Theme.panelSolid }
        Backdrop { role: "panel_session"; strength: 0.22; anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1; leftMargin: 17 } height: 120 }
        Image {
            id: core
            property int frame: 0
            anchors { right: parent.right; top: parent.top; rightMargin: 22; topMargin: 18 }
            width: 44; height: 44
            source: Assets.ui("core_" + frame)
            opacity: 0.85
            visible: status === Image.Ready && !Theme.stealth
            Timer { interval: 260; repeat: true; running: win.shown; onTriggered: core.frame = (core.frame + 1) % 4 }
        }
        Image {
            anchors.centerIn: parent
            width: parent.width - 60; height: width / 2
            source: Assets.ui("transmission_end")
            fillMode: Image.PreserveAspectFit
            opacity: !Theme.stealth && win.pending >= 0 && win.actions[win.pending].cmd.indexOf("systemctl") === 0 ? 0.20 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 300 } }
        }
        StaticBurst { id: burst; anchors.fill: parent; anchors.margins: 1 }
        TapHandler { }

        Column {
            id: body
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 22 }
            spacing: 6

            Row {
                spacing: 10
                Emblem { implicitWidth: 22; implicitHeight: 22; anchors.verticalCenter: parent.verticalCenter }
                Column {
                    spacing: 1
                    Text {
                        text: Theme.t("OVERWATCH DIRECTIVES", "Session")
                        color: Theme.white
                        font.family: Theme.label; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: 2
                    }
                    DecodeText { target: Theme.t("SELECT DIRECTIVE FOR THIS UNIT", "Choose an action"); color: Theme.muted; font.pixelSize: 10 }
                }
            }
            Item { width: 1; height: 6 }

            Repeater {
                model: win.actions
                delegate: Item {
                    id: row
                    required property var modelData
                    required property int index
                    readonly property bool current: win.current === index
                    readonly property bool counting: win.pending === index
                    readonly property color tone: modelData.danger ? Theme.red : Theme.teal
                    width: body.width
                    height: 44
                    opacity: win.pending >= 0 && !counting ? 0.35 : 1

                    Chamfer {
                        anchors.fill: parent
                        cut: 7; tl: false; br: false
                        fillColor: row.counting ? Qt.rgba(row.tone.r, row.tone.g, row.tone.b, 0.28) : (row.current ? Theme.fill : "transparent")
                        strokeColor: row.current ? row.tone : Theme.faint
                    }
                    Text {
                        id: key
                        anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter }
                        text: "0" + (row.index + 1)
                        color: row.current ? row.tone : Theme.muted
                        font.family: Theme.mono; font.pixelSize: 13
                    }
                    Text {
                        anchors { left: key.right; leftMargin: 16; verticalCenter: parent.verticalCenter }
                        text: Theme.t(row.modelData.verb, row.modelData.plain)
                        color: row.modelData.danger ? Theme.red : Theme.white
                        font.family: Theme.label; font.pixelSize: 17; font.weight: Theme.stealth ? Font.Medium : Font.Bold; font.letterSpacing: Theme.stealth ? 0 : 2
                    }
                    Text {
                        anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                        text: row.counting ? Theme.t("IN " + win.remaining + "  //  ESC TO ABORT", "in " + win.remaining + "s, Esc to cancel") : Theme.t(row.modelData.plain.toUpperCase(), "")
                        color: row.counting ? row.tone : Theme.muted
                        font.family: Theme.mono; font.pixelSize: 12
                    }
                    HoverHandler { onHoveredChanged: if (hovered && win.pending < 0) win.current = row.index }
                    TapHandler { onTapped: win.choose(row.index) }
                }
            }
        }
    }
}
