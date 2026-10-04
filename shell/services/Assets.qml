pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Paths to art extracted from the user's own game installs (scripts/extract-assets),
// plus the few settings that persist across restarts. Every consumer must cope
// with a missing file: images simply do not show.
Singleton {
    id: root
    readonly property string dir: Quickshell.env("HOME") + "/.local/share/overwatch/"
    property var wallpapers: []
    property alias wallpaper: saved.wallpaper     // wallpapers[n - 1]; anything out of range shows the Citadel image
    property alias soundLevel: saved.soundLevel   // 2 = all, 1 = effects only, 0 = silent
    property alias stealth: saved.stealth         // plain, silent work look (SUPER+B)
    property alias backdropMode: saved.backdropMode   // "random" (new one each start), "rotate" (also every 30 min), "fixed"

    // A backdrop other than the current one.
    function shuffle() {
        var n = wallpapers.length
        if (n < 2) { wallpaper = n; return }
        var pick = wallpaper
        while (pick === wallpaper) pick = 1 + Math.floor(Math.random() * n)
        wallpaper = pick
    }
    // The Citadel over City 17 (game chapter art): the fallback when nothing else is chosen.
    readonly property string citadel: {
        for (var i = 0; i < wallpapers.length; i++) if (wallpapers[i].indexOf("episodic_chapter4") >= 0) return wallpapers[i]
        return wallpapers.length ? wallpapers[0] : ""
    }
    Timer {
        interval: 30 * 60 * 1000; repeat: true
        running: root.backdropMode === "rotate" && !root.stealth
        onTriggered: root.shuffle()
    }

    function ui(name) { return "file://" + dir + "ui/" + name + ".png" }
    readonly property string wallpaperSource: wallpaper > 0 && wallpaper <= wallpapers.length ? "file://" + wallpapers[wallpaper - 1]
        : (citadel !== "" ? "file://" + citadel : "")

    FileView {
        path: root.dir + "wallpapers.txt"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            root.wallpapers = text().split("\n").filter(l => l.length > 0)
            if (root.backdropMode !== "fixed") root.shuffle()
        }
    }
    FileView {
        id: store
        path: Quickshell.env("HOME") + "/.local/state/overwatch/state.json"
        blockLoading: true
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter() }
        JsonAdapter {
            id: saved
            property int wallpaper: 0
            property int soundLevel: 2
            property bool stealth: false
            property string backdropMode: "random"
        }
    }
}
