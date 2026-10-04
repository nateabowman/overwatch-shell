pragma Singleton
import Quickshell
import Quickshell.Io
import QtQuick

// Wi-Fi, Bluetooth and power-profile state for the control panel. Polled only
// while `active` is true (the panel is open); every change is a one-shot command.
Singleton {
    id: root
    property bool active: false
    property bool wifiOn: false
    property var networks: []       // { ssid, signal, secure, inUse }
    property bool btOn: false
    property var devices: []        // { mac, name, connected }
    property string profile: "balanced"

    function run(cmd) { Quickshell.execDetached(["sh", "-c", cmd]); soon.restart() }
    function setWifi(on) { wifiOn = on; run("nmcli radio wifi " + (on ? "on" : "off")) }
    function setBt(on) { btOn = on; run("bluetoothctl power " + (on ? "on" : "off")) }
    function setProfile(p) { profile = p; run("powerprofilesctl set " + p) }
    function connect(ssid) { run("nmcli device wifi connect '" + ssid.replace(/'/g, "'\\''") + "' || kitty -e nmtui-connect '" + ssid.replace(/'/g, "'\\''") + "'") }
    function toggleDevice(d) { run("bluetoothctl " + (d.connected ? "disconnect " : "connect ") + d.mac) }
    function rescan() { run("nmcli device wifi rescan") }

    onActiveChanged: if (active) poll.running = true
    Timer { interval: 5000; repeat: true; running: root.active; onTriggered: if (!poll.running) poll.running = true }
    Timer { id: soon; interval: 900; onTriggered: if (!poll.running) poll.running = true }

    Process {
        id: poll
        command: ["sh", "-c", "echo \"WIFI $(nmcli -t -f WIFI g 2>/dev/null)\"; nmcli -t -e no -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan no 2>/dev/null | head -14 | sed 's/^/NET /'; echo \"BT $(bluetoothctl show 2>/dev/null | awk '/Powered/{print $2}')\"; bluetoothctl devices Paired 2>/dev/null | while read -r _ mac name; do echo \"DEV $mac $(bluetoothctl info $mac | awk '/Connected/{print $2}') $name\"; done; echo \"PROF $(powerprofilesctl get 2>/dev/null)\"; echo \"BRI $(brightnessctl -m 2>/dev/null | cut -d, -f4)\""]
        property var nets: []
        property var devs: []
        stdout: SplitParser {
            onRead: line => {
                var sp = line.indexOf(" ")
                var tag = sp < 0 ? line : line.substring(0, sp), rest = sp < 0 ? "" : line.substring(sp + 1)
                if (tag === "WIFI") root.wifiOn = rest === "enabled"
                else if (tag === "BT") root.btOn = rest === "yes"
                else if (tag === "PROF") { if (rest.length) root.profile = rest }
                else if (tag === "BRI") { var b = parseInt(rest); if (!isNaN(b)) Shell.brightness = b / 100 }
                else if (tag === "NET") {
                    var p = rest.split(":")
                    if (p.length >= 4 && p[3].length) {
                        var ssid = p.slice(3).join(":")
                        if (!poll.nets.some(n => n.ssid === ssid))
                            poll.nets.push({ ssid: ssid, signal: parseInt(p[1]) || 0, secure: p[2].length > 0 && p[2] !== "--", inUse: p[0].trim() === "*" })
                    }
                } else if (tag === "DEV") {
                    var d = rest.split(" ")
                    poll.devs.push({ mac: d[0], connected: d[1] === "yes", name: d.slice(2).join(" ") })
                }
            }
        }
        onRunningChanged: {
            if (running) { nets = []; devs = []; return }
            nets.sort((a, b) => (b.inUse - a.inUse) || (b.signal - a.signal))
            root.networks = nets.slice(0, 6)
            root.devices = devs
        }
    }
}
