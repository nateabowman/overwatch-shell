import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.UPower
import qs.services

// Idle sequence: broadcast screen (dim) -> lock -> screen off -> suspend on battery.
// Apps that inhibit idle (video, games) are respected; caffeine switches it all off.
Scope {
    id: root
    property int dimAfter: 240
    property int lockAfter: 300
    property int offAfter: 360
    property int sleepAfter: 1200
    readonly property bool armed: !Shell.caffeine

    IdleMonitor {
        enabled: root.armed; timeout: root.dimAfter; respectInhibitors: true
        onIsIdleChanged: Shell.idleDim = isIdle && !Shell.locked
    }
    IdleMonitor {
        enabled: root.armed; timeout: root.lockAfter; respectInhibitors: true
        onIsIdleChanged: if (isIdle && !Shell.locked) Shell.lockRequested()
    }
    IdleMonitor {
        enabled: root.armed; timeout: root.offAfter; respectInhibitors: true
        onIsIdleChanged: Quickshell.execDetached(["hyprctl", "dispatch", "hl.dsp.dpms({ action = \"" + (isIdle ? "off" : "on") + "\" })"])
    }
    IdleMonitor {
        enabled: root.armed && UPower.onBattery; timeout: root.sleepAfter; respectInhibitors: true
        onIsIdleChanged: if (isIdle) Quickshell.execDetached(["systemctl", "suspend"])
    }
    Connections { target: Shell; function onLockedChanged() { if (Shell.locked) Shell.idleDim = false } }
}
