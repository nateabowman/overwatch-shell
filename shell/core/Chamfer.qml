import QtQuick
import QtQuick.Shapes
import qs.core

// Panel with cut corners. Set a corner's flag to false to keep it square.
Shape {
    id: root
    property real cut: Theme.cut
    property color fillColor: Theme.panel
    property color strokeColor: Theme.line
    property real strokeWidth: 1
    property bool tl: true
    property bool tr: true
    property bool br: true
    property bool bl: true

    readonly property real _cut: Theme.stealth ? 0 : cut
    readonly property real _tl: tl ? _cut : 0
    readonly property real _tr: tr ? _cut : 0
    readonly property real _br: br ? _cut : 0
    readonly property real _bl: bl ? _cut : 0
    readonly property real _o: strokeWidth / 2

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: root.fillColor
        strokeColor: root.strokeWidth > 0 ? root.strokeColor : "transparent"
        strokeWidth: root.strokeWidth
        joinStyle: ShapePath.MiterJoin
        startX: root._tl + root._o; startY: root._o
        PathLine { x: root.width - root._tr - root._o; y: root._o }
        PathLine { x: root.width - root._o; y: root._tr + root._o }
        PathLine { x: root.width - root._o; y: root.height - root._br - root._o }
        PathLine { x: root.width - root._br - root._o; y: root.height - root._o }
        PathLine { x: root._bl + root._o; y: root.height - root._o }
        PathLine { x: root._o; y: root.height - root._bl - root._o }
        PathLine { x: root._o; y: root._tl + root._o }
        PathLine { x: root._tl + root._o; y: root._o }
    }
}
