import QtQuick
import qs.core

// Small "LABEL value" pair used across the bar.
Row {
    id: root
    property string label: ""
    property string value: ""
    property color valueColor: Theme.text
    spacing: 5
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.label
        color: Theme.muted
        font.family: Theme.label
        font.pixelSize: 11
        font.weight: Font.DemiBold
        font.letterSpacing: Theme.spacing
    }
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.value
        color: root.valueColor
        font.family: Theme.mono
        font.pixelSize: 13
    }
}
