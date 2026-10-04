pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// "City 17 radio": shuffles the Half-Life soundtrack copied to ~/Music/Half-Life 2.
// Plays through ffplay; nothing is registered with the system. Stops in stealth.
Singleton {
    id: root
    property var tracks: []
    property int index: -1
    property bool playing: false
    readonly property string title: index >= 0 && index < tracks.length
        ? tracks[index].replace(/^.*\//, "").replace(/\.(mp3|wav)$/, "").replace(/_/g, " ") : ""

    function toggle() { playing ? stop() : play() }
    function play() { if (!tracks.length) return; if (index < 0) pick(); playing = true; player.running = true }
    function stop() { playing = false; player.running = false }
    function next() { pick(); if (playing) { player.running = false; restart.start() } }
    function pick() {
        if (tracks.length < 2) { index = tracks.length - 1; return }
        var i = index
        while (i === index) i = Math.floor(Math.random() * tracks.length)
        index = i
    }
    Timer { id: restart; interval: 150; onTriggered: if (root.playing) player.running = true }

    Process {
        id: finder
        running: true
        command: ["sh", "-c", "find \"$HOME/Music/Half-Life 2\" -type f \\( -name '*.mp3' -o -name '*.wav' \\) 2>/dev/null | sort"]
        property var found: []
        stdout: SplitParser { onRead: line => finder.found.push(line) }
        onRunningChanged: if (!running) root.tracks = found
    }
    Process {
        id: player
        command: ["ffplay", "-nodisp", "-autoexit", "-loglevel", "quiet", "-volume", "55", root.index >= 0 ? root.tracks[root.index] : ""]
        onRunningChanged: if (!running && root.playing) { root.pick(); restart.start() }   // track ended: next
    }
    Connections { target: Assets; function onStealthChanged() { if (Assets.stealth) root.stop() } }
}
