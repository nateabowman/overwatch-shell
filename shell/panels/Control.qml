import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.core
import qs.services

// Quick settings, sliding in from the right (SUPER+X).
PanelWindow {
    id: win
    readonly property bool shown: Shell.open === "control"
    readonly property int pct: UPower.displayDevice ? Math.round(UPower.displayDevice.percentage * 100) : 0
    visible: shown
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "overwatch-panel"
    WlrLayershell.keyboardFocus: shown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    onShownChanged: { Net.active = shown; if (shown) { slide.restart(); burst.fire(); panel.forceActiveFocus() } }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0.02, 0.03, 0.04, 0.28)
        TapHandler { onTapped: point => { var p = point.position; if (p.x < panel.x || p.x > panel.x + panel.width || p.y < panel.y || p.y > panel.y + panel.height) Shell.close() } }
    }

    Item {
        id: panel
        width: 440
        // pinned to the right edge; the slide-in only offsets it, so it can never rest in the wrong place
        anchors { top: parent.top; bottom: parent.bottom; right: parent.right; topMargin: 10; bottomMargin: 10; rightMargin: 10 }
        transform: Translate { id: shift; x: 0 }
        focus: true
        Keys.onEscapePressed: Shell.close()
        NumberAnimation { id: slide; target: shift; property: "x"; from: panel.width + 20; to: 0; duration: 170; easing.type: Easing.OutCubic }

        Chamfer { anchors.fill: parent; cut: 14; tr: false; br: false; fillColor: Theme.panelSolid }
        Backdrop { role: "panel_session"; strength: 0.26; anchors { left: parent.left; right: parent.right; top: parent.top; margins: 1; leftMargin: 15 } height: 150 }
        StaticBurst { id: burst; anchors.fill: parent; anchors.margins: 1; anchors.leftMargin: 15 }
        TapHandler { }

        Flickable {
            anchors { fill: parent; margins: 20 }
            contentHeight: col.implicitHeight
            clip: true
            Column {
                id: col
                width: parent.width
                spacing: 14

                Row {
                    spacing: 10
                    Emblem { implicitWidth: 22; implicitHeight: 22; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        spacing: 1
                        Text {
                            text: Theme.t("CONTROL INTERFACE", "Quick settings")
                            color: Theme.white
                            font.family: Theme.label; font.pixelSize: 16; font.weight: Font.Bold; font.letterSpacing: Theme.stealth ? 0 : 2
                        }
                        DecodeText {
                            target: Theme.t("STABILITY " + win.pct + "%  //  " + (UPower.onBattery ? "ON RESERVE" : "EXTERNAL FEED"),
                                            "Battery " + win.pct + "%, " + (UPower.onBattery ? "on battery" : "plugged in"))
                            color: Theme.muted; font.pixelSize: 10
                        }
                    }
                }

                // Sliders
                Column {
                    width: parent.width; spacing: 8
                    Row {
                        width: parent.width; spacing: 10
                        Label { width: 84; text: Theme.t("AUDIO", "Volume"); anchors.verticalCenter: parent.verticalCenter }
                        Slider {
                            width: parent.width - 84 - 44 - 20; anchors.verticalCenter: parent.verticalCenter
                            value: Shell.sink && Shell.sink.audio ? Shell.sink.audio.volume : 0
                            tone: Shell.sink && Shell.sink.audio && Shell.sink.audio.muted ? Theme.amber : Theme.teal
                            onMoved: v => Shell.setVolume(v)
                        }
                        Text { width: 44; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter
                            text: Shell.sink && Shell.sink.audio ? Math.round(Shell.sink.audio.volume * 100) + "%" : "--"
                            color: Theme.white; font.family: Theme.mono; font.pixelSize: 12 }
                    }
                    Row {
                        width: parent.width; spacing: 10
                        Label { width: 84; text: Theme.t("LUMINANCE", "Brightness"); anchors.verticalCenter: parent.verticalCenter }
                        Slider {
                            width: parent.width - 84 - 44 - 20; anchors.verticalCenter: parent.verticalCenter
                            value: Shell.brightness
                            onMoved: v => Shell.setBrightness(v)
                        }
                        Text { width: 44; horizontalAlignment: Text.AlignRight; anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(Shell.brightness * 100) + "%"
                            color: Theme.white; font.family: Theme.mono; font.pixelSize: 12 }
                    }
                }

                // Toggles
                Grid {
                    width: parent.width; columns: 2; spacing: 8
                    readonly property real cw: (width - spacing) / 2
                    Chip { width: parent.cw; title: Theme.t("UPLINK", "Wi-Fi"); on: Net.wifiOn
                        state: Net.wifiOn ? (Sys.netType === "wifi" ? Sys.shownNet : Theme.t("STANDBY", "on")) : Theme.t("SEVERED", "off")
                        onTapped: Net.setWifi(!Net.wifiOn) }
                    Chip { width: parent.cw; title: Theme.t("SHORT RANGE", "Bluetooth"); on: Net.btOn
                        state: Net.btOn ? Theme.t("ACTIVE", "on") : Theme.t("DORMANT", "off")
                        onTapped: Net.setBt(!Net.btOn) }
                    Chip { width: parent.cw; title: Theme.t("SILENCE", "Do not disturb"); on: Notifs.dnd; tone: Theme.amber
                        state: Notifs.dnd ? Theme.t("DISPATCH HELD", "on") : Theme.t("DISPATCH OPEN", "off")
                        onTapped: Notifs.dnd = !Notifs.dnd }
                    Chip { width: parent.cw; title: Theme.t("VIGILANCE", "Stay awake"); on: Shell.caffeine; tone: Theme.amber
                        state: Shell.caffeine ? Theme.t("NO REST CYCLE", "screen stays on") : Theme.t("REST AFTER 5 MIN", "locks after 5 min")
                        onTapped: Shell.caffeine = !Shell.caffeine }
                    Chip { width: parent.cw; title: Theme.t("VOCODER", "Microphone"); tone: Theme.red
                        on: Shell.source && Shell.source.audio ? Shell.source.audio.muted : false
                        state: on ? Theme.t("MUTED", "muted") : Theme.t("LIVE", "live")
                        onTapped: Shell.micMute() }
                    Chip { width: parent.cw; title: Theme.t("SHELL FX", "Sounds"); on: Assets.soundLevel > 0 && !Assets.stealth
                        state: Assets.stealth ? "off" : ["SILENT", "EFFECTS", "FX + VOICE"][Assets.soundLevel]
                        onTapped: Assets.soundLevel = (Assets.soundLevel + 2) % 3 }
                    Chip { width: parent.cw; title: Theme.t("BACKDROP", "Wallpaper"); on: Assets.backdropMode !== "fixed"
                        state: Theme.t(Assets.backdropMode.toUpperCase(), Assets.backdropMode)
                        onTapped: Assets.backdropMode = { random: "rotate", rotate: "fixed", fixed: "random" }[Assets.backdropMode] || "random" }
                    Chip { width: parent.cw; title: Theme.t("SCANLINES", "Scanlines"); visible: !Theme.stealth; on: Shell.scanlines
                        state: Shell.scanlines ? "ON" : "OFF"
                        onTapped: Shell.scanlines = !Shell.scanlines }
                }

                // Power profile
                Column {
                    width: parent.width; spacing: 6
                    Label { text: Theme.t("OUTPUT REGIME", "Power profile") }
                    Row {
                        width: parent.width; spacing: 8
                        Repeater {
                            model: [ { id: "power-saver", a: "CONSERVE", b: "Saver" }, { id: "balanced", a: "NOMINAL", b: "Balanced" }, { id: "performance", a: "OVERDRIVE", b: "Performance" } ]
                            delegate: Chip {
                                required property var modelData
                                width: (col.width - 16) / 3; implicitHeight: 34
                                title: Theme.t(modelData.a, modelData.b); state: ""
                                on: Net.profile === modelData.id
                                tone: modelData.id === "performance" ? Theme.amber : Theme.teal
                                onTapped: Net.setProfile(modelData.id)
                            }
                        }
                    }
                }

                // Networks
                Column {
                    width: parent.width; spacing: 4
                    visible: Net.wifiOn
                    Item { width: parent.width; height: 16
                        Label { text: Theme.t("UPLINK NODES", "Networks") }
                        Label { anchors.right: parent.right; text: Theme.t("RESCAN", "Rescan"); color: Theme.teal
                            TapHandler { onTapped: { Shell.fx("click"); Net.rescan() } } }
                    }
                    Repeater {
                        model: Net.networks
                        delegate: Item {
                            id: net
                            required property var modelData
                            required property int index
                            width: col.width; height: 28
                            Rectangle { anchors.fill: parent; color: nh.hovered ? Theme.fill : "transparent" }
                            Rectangle { width: 2; height: parent.height; color: net.modelData.inUse ? Theme.teal : "transparent" }
                            Text { anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                width: parent.width - 120; elide: Text.ElideRight
                                text: net.modelData.inUse ? Sys.alias("C17-UPLINK", net.modelData.ssid, 0) : Sys.alias("C17-NODE", net.modelData.ssid, net.index); color: net.modelData.inUse ? Theme.white : Theme.text
                                font.family: Theme.label; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Text { anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                text: (net.modelData.secure ? Theme.t("SECURED  ", "locked  ") : "") + net.modelData.signal + "%"
                                color: Theme.muted; font.family: Theme.mono; font.pixelSize: 11 }
                            HoverHandler { id: nh; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: if (!net.modelData.inUse) { Shell.fx("select"); Net.connect(net.modelData.ssid) } }
                        }
                    }
                }

                // Bluetooth devices
                Column {
                    width: parent.width; spacing: 4
                    visible: Net.btOn && Net.devices.length > 0
                    Label { text: Theme.t("PAIRED UNITS", "Bluetooth devices") }
                    Repeater {
                        model: Net.devices
                        delegate: Item {
                            id: dev
                            required property var modelData
                            required property int index
                            width: col.width; height: 28
                            Rectangle { anchors.fill: parent; color: dh.hovered ? Theme.fill : "transparent" }
                            Rectangle { width: 2; height: parent.height; color: dev.modelData.connected ? Theme.teal : "transparent" }
                            Text { anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                                text: Sys.alias("UNIT", dev.modelData.name, dev.index); color: dev.modelData.connected ? Theme.white : Theme.text
                                font.family: Theme.label; font.pixelSize: 13; font.weight: Font.DemiBold }
                            Text { anchors { right: parent.right; rightMargin: 8; verticalCenter: parent.verticalCenter }
                                text: dev.modelData.connected ? Theme.t("LINKED", "connected") : Theme.t("IDLE", "not connected")
                                color: Theme.muted; font.family: Theme.mono; font.pixelSize: 11 }
                            HoverHandler { id: dh; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: { Shell.fx("select"); Net.toggleDevice(dev.modelData) } }
                        }
                    }
                }

                Loader { width: parent.width; source: Qt.resolvedUrl("RadioCard.qml"); onStatusChanged: if (status === Loader.Error) visible = false }
            }
        }
    }
}
