import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam
import qs.core
import qs.services

// Session lock. Password is checked through PAM (the "login" service).
Scope {
    id: root
    property string state: "idle"     // idle | checking | denied
    property string secret: ""
    property int testSeconds: 0        // > 0 while a self-unlocking trial lock is running

    function engage() {
        Shell.close()
        root.state = "idle"
        root.secret = ""
        lock.locked = true
        Shell.locked = true
    }
    function release() {
        lock.locked = false
        Shell.locked = false
        Shell.unlocked()
        root.secret = ""
        root.testSeconds = 0
    }
    function submit(text) {
        if (root.state === "checking" || !text.length) return
        root.secret = text
        root.state = "checking"
        pam.start()
    }

    Connections {
        target: Shell
        function onLockRequested() { root.engage() }
        function onLockTestRequested() { root.testUntil = Date.now() + 30000; root.testSeconds = 30; root.engage() }
        function onDenyPreviewRequested() { if (root.testSeconds > 0 && lock.locked) { root.state = "idle"; root.state = "denied"; Shell.denied() } }
    }

    // Trial-lock countdown. Driven by the wall clock: a QML Timer does not tick while the
    // session is locked, which left a trial lock stuck at 30 seconds.
    property double testUntil: 0
    SystemClock {
        precision: SystemClock.Seconds
        enabled: root.testSeconds > 0
        onDateChanged: {
            if (root.testSeconds <= 0 || !lock.locked) return
            var left = Math.ceil((root.testUntil - Date.now()) / 1000)
            if (left <= 0) root.release(); else root.testSeconds = left
        }
    }

    PamContext {
        id: pam
        onPamMessage: if (responseRequired) respond(root.secret)
        onCompleted: result => {
            root.secret = ""
            if (result === PamResult.Success) root.release()
            else { root.state = "denied"; Shell.denied() }
        }
        onError: { root.secret = ""; root.state = "denied" }
    }

    WlSessionLock {
        id: lock
        WlSessionLockSurface {
            id: surface
            color: Theme.base

            SystemClock { id: clock; precision: SystemClock.Seconds }

            Image {
                anchors.fill: parent
                source: Assets.wallpaperSource
                fillMode: Image.PreserveAspectCrop
                visible: Assets.wallpaperSource !== "" && status === Image.Ready && !Theme.stealth
            }
            Rectangle { anchors.fill: parent; color: Theme.stealth ? "#1f242b" : Qt.rgba(0.02, 0.03, 0.045, 0.62) }
            // Access sign, drawn at full resolution (the game texture is only 256px)
            Item {
                id: sign
                visible: !Theme.stealth
                anchors { right: parent.right; rightMargin: parent.width * 0.09; verticalCenter: parent.verticalCenter }
                width: Math.min(400, parent.width * 0.27); height: width * 0.92
                opacity: 0.94
                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.86; duration: 2600 }
                    NumberAnimation { to: 0.96; duration: 80 }
                    NumberAnimation { to: 0.80; duration: 60 }
                    NumberAnimation { to: 0.94; duration: 1900 }
                }
                Chamfer { anchors.fill: parent; cut: 26; tl: false; br: false; fillColor: Qt.rgba(0.05, 0.16, 0.22, 0.86); strokeColor: Theme.teal; strokeWidth: 2 }
                Chamfer { anchors.fill: parent; anchors.margins: 9; cut: 20; tl: false; br: false; fillColor: "transparent"; strokeColor: Theme.tealDim }
                Column {
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 26 }
                    spacing: 2
                    Text {
                        text: "PRECINCT"
                        color: Theme.teal
                        font.family: Theme.label; font.pixelSize: sign.width * 0.135; font.weight: Font.Black; font.letterSpacing: sign.width * 0.012
                    }
                    Row {
                        width: parent.width; spacing: 12
                        Column {
                            anchors.bottom: parent.bottom; anchors.bottomMargin: sign.width * 0.06
                            spacing: 5
                            Repeater { model: 5; Rectangle { required property int index; width: sign.width * (0.30 - index * 0.035); height: 3; color: Theme.tealDim } }
                            Text { text: "0017 // C17 // 2B-7"; color: Theme.tealDim; font.family: Theme.mono; font.pixelSize: 11 }
                        }
                        Item { width: 1; height: 1 }
                    }
                    Text {
                        anchors.right: parent.right
                        text: "17"
                        color: Theme.white
                        font.family: Theme.label; font.pixelSize: sign.width * 0.36; font.weight: Font.Black
                        lineHeight: 0.8
                    }
                }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 26 }
                    height: sign.width * 0.25
                    color: Theme.teal
                    Column {
                        anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                        spacing: -4
                        Text { text: "ACCESS"; color: Theme.base; font.family: Theme.label; font.pixelSize: sign.width * 0.095; font.weight: Font.Black; font.letterSpacing: 3 }
                        Text { text: "REQUIRED"; color: Theme.base; font.family: Theme.label; font.pixelSize: sign.width * 0.095; font.weight: Font.Black; font.letterSpacing: 3 }
                    }
                    // claw and CMB, paired as on the city's posters
                    Column {
                        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                        spacing: 3
                        Emblem { anchors.right: parent.right; color: Theme.base; implicitWidth: sign.width * 0.11; implicitHeight: sign.width * 0.11 }
                        Text { anchors.right: parent.right; visible: Theme.glyphs !== ""; text: "CMB"; color: Theme.base; font.family: Theme.glyphs; font.pixelSize: sign.width * 0.045 }
                    }
                }
            }
            StaticBurst { id: burst; anchors.fill: parent; Component.onCompleted: fire() }
            ShaderEffect {
                anchors.fill: parent
                visible: !Theme.stealth
                property real time: 0
                property real lines: height / 2
                fragmentShader: Qt.resolvedUrl("../overlay/scan.frag.qsb")
                Timer { interval: 50; repeat: true; running: lock.locked; onTriggered: parent.time += 0.05 }
            }

            // Denial flash
            Rectangle {
                id: deny
                anchors.fill: parent
                color: Theme.red
                opacity: 0
                NumberAnimation { id: denyAnim; target: deny; property: "opacity"; from: 0.35; to: 0; duration: 500 }
            }
            Connections {
                target: root
                function onStateChanged() {
                    if (root.state === "denied") { denyAnim.restart(); field.text = ""; shake.restart() }
                }
            }

            Column {
                anchors { left: parent.left; leftMargin: parent.width * 0.09; verticalCenter: parent.verticalCenter }
                spacing: 4

                Row {
                    spacing: 14
                    Emblem { implicitWidth: 46; implicitHeight: 46; anchors.verticalCenter: parent.verticalCenter }
                    Column {
                        spacing: -4
                        Text {
                            text: Theme.t("SECTOR SEALED", "Locked")
                            color: Theme.white
                            font.family: Theme.label; font.pixelSize: 34; font.weight: Theme.stealth ? Font.Medium : Font.Bold; font.letterSpacing: Theme.stealth ? 0 : 6
                        }
                        Label { text: Theme.t("RESTRICTED  //  CITIZEN IDENTIFICATION REQUIRED", "Enter your password to unlock"); color: Theme.teal; font.pixelSize: 13 }
                    }
                }
                Text {
                    visible: Theme.glyphs !== ""
                    topPadding: 8
                    text: "sector sealed by order of the universal union"
                    color: Theme.tealDim
                    font.family: Theme.glyphs; font.pixelSize: 16
                }
                Item { width: 1; height: 26 }
                Text {
                    text: Qt.formatDateTime(clock.date, "HH:mm:ss")
                    color: Theme.white
                    font.family: Theme.mono; font.pixelSize: 84
                }
                Text {
                    text: Qt.formatDateTime(clock.date, "dddd dd MMMM yyyy").toUpperCase()
                    color: Theme.muted
                    font.family: Theme.mono; font.pixelSize: 15
                }
                Item { width: 1; height: 30 }

                Item {
                    id: box
                    width: 420; height: 46
                    SequentialAnimation {
                        id: shake
                        NumberAnimation { target: box; property: "x"; to: 10; duration: 40 }
                        NumberAnimation { target: box; property: "x"; to: -8; duration: 60 }
                        NumberAnimation { target: box; property: "x"; to: 5; duration: 50 }
                        NumberAnimation { target: box; property: "x"; to: 0; duration: 40 }
                    }
                    Chamfer {
                        anchors.fill: parent
                        cut: 8; tr: false; bl: false
                        fillColor: Theme.panelSolid
                        strokeColor: root.state === "denied" ? Theme.red : Theme.teal
                    }
                    Label { id: cap; text: Theme.t("CREDENTIAL", "Password"); color: Theme.teal; anchors { left: parent.left; leftMargin: 14; verticalCenter: parent.verticalCenter } }
                    Row {
                        anchors { left: cap.right; leftMargin: 14; verticalCenter: parent.verticalCenter }
                        spacing: 4
                        Repeater {
                            model: Math.min(field.text.length, 30)
                            Rectangle { width: 7; height: 14; color: Theme.white }
                        }
                        Rectangle {
                            width: 7; height: 14; color: Theme.teal
                            visible: root.state !== "checking"
                            SequentialAnimation on opacity {
                                loops: Animation.Infinite
                                NumberAnimation { to: 0.1; duration: 500 }
                                NumberAnimation { to: 1; duration: 500 }
                            }
                        }
                    }
                    TextInput {
                        id: field
                        width: 1; height: 1; opacity: 0
                        focus: true
                        echoMode: TextInput.Password
                        enabled: root.state !== "checking"
                        onTextChanged: if (text.length && root.state === "denied") root.state = "idle"
                        onAccepted: { var t = text; text = ""; root.submit(t) }
                        Keys.onEscapePressed: text = ""
                        Component.onCompleted: forceActiveFocus()
                    }
                }
                Item { width: 1; height: 4 }
                DecodeText {
                    target: root.state === "checking" ? Theme.t("VERIFYING IDENTITY...", "Checking...")
                        : root.state === "denied" ? Theme.t("IDENTITY REJECTED  //  NONCOMPLIANCE LOGGED", "Wrong password")
                        : Theme.t("AWAITING CREDENTIAL  //  ENTER TO SUBMIT", "Press Enter to unlock")
                    color: root.state === "denied" ? Theme.red : Theme.muted
                    font.pixelSize: 12
                }
                Label {
                    visible: root.testSeconds > 0
                    topPadding: 10
                    text: Theme.t("TRIAL LOCK  //  RELEASES AUTOMATICALLY IN " + root.testSeconds + "S", "Trial lock, unlocks by itself in " + root.testSeconds + "s")
                    color: Theme.amber
                }
            }
        }
    }
}
