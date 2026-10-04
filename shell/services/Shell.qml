pragma Singleton
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.Mpris
import QtQuick

// Shell-wide state and the IPC surface used by the Hyprland keybinds:
//   qs -c overwatch ipc call shell <function> [args]
Singleton {
    id: root

    property string open: ""          // which panel is showing; only one at a time
    property string osdLabel: ""
    property real osdValue: 0
    property bool osdMuted: false
    property bool osdVisible: false
    property bool scanlines: true
    property bool locked: false
    property string detail: ""        // which hover card the bar is showing: cpu | mem | gpu
    property real detailX: 0
    property string tipText: ""
    // Plain-text hover explanation under the bar: tip("line1\nline2", item) / untip(text)
    function tip(text, item) { tipText = text; detailX = item.mapToItem(null, 0, 0).x; detail = "tip" }
    function untip(text) { if (detail === "tip" && tipText === text) detail = "" }
    Connections { target: Assets; function onStealthChanged() { root.detail = ""; root.close() } }   // no stale wording across a mode switch
    signal sessionRequested(int index)      // 0 lock, 1 log out, 2 suspend, 3 reboot, 4 shut down
    property bool caffeine: false      // true = never dim, lock or sleep on idle
    property bool idleDim: false       // set by Idle while the pre-lock broadcast shows
    property real brightness: 0.5
    function setVolume(v) { if (sink && sink.audio) { sink.audio.muted = false; sink.audio.volume = Math.max(0, Math.min(1, v)) } }
    function setBrightness(v) {
        brightness = Math.max(0.02, Math.min(1, v))
        Quickshell.execDetached(["brightnessctl", "-q", "set", Math.round(brightness * 100) + "%"])
    }
    signal sfx(string name)
    function fx(name) { sfx(name) }
    signal lockRequested()
    signal lockTestRequested()
    signal denyPreviewRequested()     // shows the rejection on a trial lock without asking PAM
    signal unlocked()
    signal denied()
    signal flash()

    function toggle(name) { open = (open === name) ? "" : name }
    function close() { open = "" }

    function showOsd(label, value, isMuted) {
        osdLabel = label; osdValue = value; osdMuted = isMuted
        osdVisible = true
        osdTimer.restart()
    }
    Timer { id: osdTimer; interval: 1500; onTriggered: root.osdVisible = false }

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    PwObjectTracker { objects: [root.sink, root.source] }

    function volumeStep(delta) {
        if (!sink || !sink.audio) return
        sink.audio.muted = false
        sink.audio.volume = Math.max(0, Math.min(1, sink.audio.volume + delta))
        showOsd(Assets.stealth ? "Volume" : "AUDIO", sink.audio.volume, false)
        fx("step")
    }
    function volumeMute() {
        if (!sink || !sink.audio) return
        sink.audio.muted = !sink.audio.muted
        showOsd(Assets.stealth ? "Volume" : "AUDIO", sink.audio.volume, sink.audio.muted)
    }
    function micMute() {
        if (!source || !source.audio) return
        source.audio.muted = !source.audio.muted
        showOsd(Assets.stealth ? "Mic" : "VOCODER", source.audio.volume, source.audio.muted)
    }

    Process {
        id: bright
        stdout: SplitParser {
            onRead: line => {
                var m = line.match(/,(\d+)%,/)
                if (m) { root.brightness = parseInt(m[1]) / 100; root.showOsd(Assets.stealth ? "Brightness" : "LUMINANCE", root.brightness, false); root.fx("step") }
            }
        }
    }
    function brightnessStep(arg) {
        bright.command = ["brightnessctl", "-m", "set", arg]
        bright.running = true
    }

    Process { id: runner }
    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]) }

    function screenshot(region) {
        var name = "swash --stdin --name \"swash-$(date +'%Y-%m-%d_%H:%M:%S').png\""
        if (region) {
            run("g=$(slurp) && grim -g \"$g\" - | " + name)
        } else {
            flash()
            run("sleep 0.35; grim - | " + name)
        }
    }

    function media(action) {
        var list = Mpris.players.values
        if (!list.length) return
        var p = list[0]
        for (var i = 0; i < list.length; i++) if (list[i].isPlaying) { p = list[i]; break }
        if (action === "toggle") p.togglePlaying()
        else if (action === "next") p.next()
        else if (action === "previous") p.previous()
    }

    function wallpaperStep(d) {
        var n = Assets.wallpapers.length
        if (!n) return
        Assets.backdropMode = "fixed"
        Assets.wallpaper = ((Math.max(1, Assets.wallpaper) - 1 + d + n) % n) + 1
        showOsd("BACKDROP " + Assets.wallpaper, Assets.wallpaper / n, false)
    }

    IpcHandler {
        target: "shell"
        function toggle(name: string): void { root.toggle(name) }
        function close(): void { root.close() }
        function volumeUp(): void { root.volumeStep(0.05) }
        function volumeDown(): void { root.volumeStep(-0.05) }
        function volumeMute(): void { root.volumeMute() }
        function micMute(): void { root.micMute() }
        function brightnessUp(): void { root.brightnessStep("5%+") }
        function brightnessDown(): void { root.brightnessStep("5%-") }
        function media(action: string): void { root.media(action) }
        function screenshotRegion(): void { root.screenshot(true) }
        function screenshotFull(): void { root.screenshot(false) }
        function lock(): void { root.lockRequested() }
        function lockTest(): void { root.lockTestRequested() }
        function scanlines(): void { root.scanlines = !root.scanlines; root.showOsd("SCANLINES", root.scanlines ? 1 : 0, !root.scanlines) }
        function sounds(): void {
            Assets.soundLevel = (Assets.soundLevel + 2) % 3       // all -> effects only -> silent
            root.showOsd(["FX SILENT", "FX ONLY", "FX + VOICE"][Assets.soundLevel], Assets.soundLevel / 2, Assets.soundLevel === 0)
        }
        function sfx(name: string): void { root.fx(name) }
        function detail(name: string): void { root.detailX = 900; root.detail = name }
        function stealth(on: bool): void { root.close(); Assets.stealth = on }
        function caffeine(): void { root.caffeine = !root.caffeine; root.showOsd(Assets.stealth ? "Stay awake" : "VIGILANCE", root.caffeine ? 1 : 0, !root.caffeine) }
        function wallpaperNext(): void { root.wallpaperStep(1) }
        function wallpaperPrev(): void { root.wallpaperStep(-1) }
        function clearNotifications(): void { Notifs.clearAll() }
        function radio(action: string): void { if (action === "next") Radio.next(); else if (action === "stop") Radio.stop(); else Radio.toggle() }
        function dnd(on: bool): void { Notifs.dnd = on }
        function idlePreview(on: bool): void { root.idleDim = on && !root.locked }
        function backdrop(index: int, mode: string): void {
            if (mode !== "") Assets.backdropMode = mode
            Assets.wallpaper = Math.max(1, Math.min(Assets.wallpapers.length, index))
        }
        function lockDenyPreview(): void { root.denyPreviewRequested() }
        function flash(): void { root.flash() }
        function state(): string {
            return JSON.stringify({ wallpaper: Assets.wallpaper, backdropMode: Assets.backdropMode, soundLevel: Assets.soundLevel,
                stealth: Assets.stealth, scanlines: root.scanlines, caffeine: root.caffeine, dnd: Notifs.dnd, radio: Radio.playing })
        }
        function reloadSounds(): void { Sounds.init() }
    }
}
