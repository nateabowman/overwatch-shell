pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Services.Notifications
import QtQuick

// Plays sounds extracted from the user's own Half-Life 2 install (scripts/extract-assets).
// Files are <event>.<n>.wav; one variant is picked at random. Events starting with
// "voice_" or "amb_" only play at sound level 2. Silent when a file is missing.
Singleton {
    id: root
    readonly property string dir: Assets.dir + "sounds/"
    property var have: ({})            // event -> number of variants
    property bool ready: false
    property real lastLight: 0
    property real lastVoice: 0
    property bool warned: false
    readonly property int battery: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) : 100

    function init() { scan.running = true }
    // Blink the keyboard backlight three times, then return to the saved colour (not in stealth)
    function kbdFlash(hex) {
        if (Assets.stealth) return
        var k = Qt.resolvedUrl("../scripts/owkbd").toString().replace("file://", "")
        var s = Quickshell.env("HOME") + "/.local/state/overwatch/kbd"
        Quickshell.execDetached(["sh", "-c", "c=$(cat '" + s + "' 2>/dev/null || echo 5fd7e8); for i in 1 2 3; do '" + k + "' " + hex + "; sleep 0.25; '" + k + "' off; sleep 0.15; done; '" + k + "' \"$c\""])
    }

    function play(name, volume) {
        var level = Assets.soundLevel
        if (Assets.stealth || level <= 0 || !have[name]) return
        var extra = name.startsWith("voice_") || name.startsWith("amb_")
        if (extra && level < 2) return
        var now = Date.now()
        if (name === "hover" || name === "move") {       // no machine-gunning
            if (now - lastLight < 110) return
            lastLight = now
        }
        if (name.startsWith("voice_")) {
            if (now - lastVoice < 45000) return
            lastVoice = now
        }
        var i = Math.floor(Math.random() * have[name])
        Quickshell.execDetached(["pw-play", "--volume", String(volume || 0.45), dir + name + "." + i + ".wav"])
    }

    Process {
        id: scan
        command: ["sh", "-c", "ls " + root.dir + " 2>/dev/null; [ -e \"$XDG_RUNTIME_DIR/overwatch-greeted\" ] && echo __greeted; touch \"$XDG_RUNTIME_DIR/overwatch-greeted\""]
        property bool greeted: false
        property var found: ({})
        stdout: SplitParser {
            onRead: line => {
                if (line === "__greeted") { scan.greeted = true; return }
                var m = line.match(/^(.+)\.\d+\.wav$/)
                if (m) scan.found[m[1]] = (scan.found[m[1]] || 0) + 1
            }
        }
        onRunningChanged: {
            if (running) { found = ({}); greeted = false; return }
            root.have = found
            root.ready = true
            if (!greeted) { root.play("login", 0.5); root.play("voice_login", 0.5) }
        }
    }

    // Forcefield hum while the screen is locked
    Process {
        running: Shell.locked && !Assets.stealth && Assets.soundLevel >= 2 && !!root.have["amb_lock"]
        command: ["sh", "-c", "trap 'kill $p 2>/dev/null; exit 0' TERM INT; while :; do pw-play --volume 0.10 '" + root.dir + "amb_lock.0.wav' & p=$!; wait $p; done"]
    }

    Connections {
        target: Notifs
        function onArrived(n) {
            if (n.urgency === NotificationUrgency.Critical) { root.play("alert", 0.45); root.play("voice_alert", 0.4); root.kbdFlash("ff2a1f") }
            else root.play("notify", 0.45)
        }
    }
    Connections {
        target: Shell
        function onSfx(name) { root.play(name, name === "hover" || name === "move" ? 0.14 : 0.36) }
        function onOpenChanged() {
            if (!root.ready) return
            root.play(Shell.open === "" ? "close" : "open", 0.35)
            if (Shell.open === "launcher") root.play("amb_terminal", 0.22)
        }
        function onFlash() { root.play("scan", 0.6) }
        function onLockRequested() { root.play("lock", 0.5); root.play("voice_lock", 0.4) }
        function onUnlocked() { root.play("unlock", 0.5) }
        function onDenied() { root.play("deny", 0.5) }
    }
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { if (root.ready) root.play("workspace", 0.3) }
    }
    Connections {
        target: UPower
        function onOnBatteryChanged() {
            if (root.ready) root.play(UPower.onBattery ? "unplug" : "plug", 0.4)
            if (!UPower.onBattery) root.warned = false
        }
    }
    onBatteryChanged: {
        if (UPower.onBattery && battery <= 10 && !warned) { warned = true; play("lowpower", 0.5); kbdFlash("ffb347") }
    }
}
