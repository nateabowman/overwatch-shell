import QtQuick
import qs.core

// Line graph of the last N samples (0..100).
Canvas {
    id: root
    property var samples: []
    property color color: Theme.teal
    implicitWidth: 44
    implicitHeight: 14
    onSamplesChanged: requestPaint()
    onPaint: {
        var ctx = getContext("2d")
        ctx.reset()
        var n = samples.length
        if (n < 2) return
        var step = width / 29
        var x0 = width - (n - 1) * step
        ctx.strokeStyle = root.color
        ctx.lineWidth = 1.2
        ctx.beginPath()
        for (var i = 0; i < n; i++) {
            var y = height - 1 - (Math.min(100, samples[i]) / 100) * (height - 2)
            if (i === 0) ctx.moveTo(x0, y); else ctx.lineTo(x0 + i * step, y)
        }
        ctx.stroke()
        ctx.lineTo(width, height); ctx.lineTo(x0, height); ctx.closePath()
        ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.16)
        ctx.fill()
    }
}
