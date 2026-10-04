//@ pragma UseQApplication
import QtQuick
import Quickshell
import "bar"
import "wallpaper"
import "panels"
import "overlay"
import "lock"
import "taskbar"
import qs.services

ShellRoot {
    Component.onCompleted: Sounds.init()

    Variants {
        model: Quickshell.screens
        Scope {
            id: perScreen
            required property var modelData
            Wallpaper { screen: perScreen.modelData }
            Bar { screen: perScreen.modelData }
            DetailCard { screen: perScreen.modelData }
            Taskbar { screen: perScreen.modelData }
            Overlay { screen: perScreen.modelData }
        }
    }
    Launcher { }
    Directives { }
    Osd { }
    NotifPopups { }
    NotifHistory { }
    Control { }
    Switcher { }
    Idle { }
    Lock { }
}
