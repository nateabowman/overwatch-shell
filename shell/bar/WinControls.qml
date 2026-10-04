import QtQuick
import qs.core
import qs.services

// Minimize / maximize / close for the focused window.
Row {
    id: root
    spacing: 3
    Repeater {
        model: [
            { glyph: "–", cmd: "minimize", tone: Theme.teal },
            { glyph: "□", cmd: "maximize", tone: Theme.teal },
            { glyph: "✕", cmd: "close",    tone: Theme.red }
        ]
        delegate: Item {
            id: btn
            required property var modelData
            width: 24; height: 18
            Chamfer {
                anchors.fill: parent
                cut: 4; tr: false; bl: false
                fillColor: h.hovered ? Qt.rgba(btn.modelData.tone.r, btn.modelData.tone.g, btn.modelData.tone.b, 0.25) : "transparent"
                strokeColor: h.hovered ? btn.modelData.tone : Theme.faint
            }
            Text {
                anchors.centerIn: parent
                text: btn.modelData.glyph
                color: h.hovered ? btn.modelData.tone : Theme.text
                font.family: Theme.mono; font.pixelSize: 11
            }
            HoverHandler { id: h; onHoveredChanged: if (hovered) Shell.fx("hover") }
            TapHandler { onTapped: { Shell.fx("click"); if (Windows.active) Windows.act(btn.modelData.cmd, Windows.active.address) } }
        }
    }
}
