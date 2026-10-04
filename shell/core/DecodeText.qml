import QtQuick
import qs.core

// Text that resolves left to right out of scrambled glyphs whenever `target` changes.
Text {
    id: root
    property string target: ""
    property int stepMs: 22
    property int charsPerStep: 2
    property int _shown: 0
    readonly property string _glyphs: "#/\\<>[]{}=+-_|:;01XKZV"

    color: Theme.text
    font.family: Theme.mono
    font.pixelSize: 13
    textFormat: Text.PlainText

    function _render() {
        if (Theme.stealth) { text = target; return }
        var out = target.substring(0, _shown)
        var n = Math.min(target.length - _shown, 6)
        for (var i = 0; i < n; i++) {
            var c = target.charAt(_shown + i)
            out += c === " " ? " " : _glyphs.charAt(Math.floor(Math.random() * _glyphs.length))
        }
        text = out
    }

    onTargetChanged: { _shown = 0; _render(); tick.restart() }
    Component.onCompleted: { _shown = 0; _render(); tick.restart() }

    Timer {
        id: tick
        interval: root.stepMs
        repeat: true
        onTriggered: {
            root._shown = Math.min(root.target.length, root._shown + root.charsPerStep)
            root._render()
            if (root._shown >= root.target.length) stop()
        }
    }
}
