pragma Singleton
import Quickshell
import Quickshell.Services.Notifications
import QtQuick

// Notification daemon. `popups` are the cards currently on screen;
// `server.trackedNotifications` is the full history until dismissed.
Singleton {
    id: root
    property var popups: []
    property bool dnd: false
    readonly property var history: server.trackedNotifications
    signal arrived(var n)

    function drop(n) { popups = popups.filter(p => p !== n) }
    function clearAll() {
        var all = server.trackedNotifications.values.slice()
        popups = []
        for (var i = 0; i < all.length; i++) all[i].dismiss()
    }

    NotificationServer {
        id: server
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        imageSupported: true
        keepOnReload: true
        onNotification: n => {
            n.tracked = true
            n.closed.connect(() => root.drop(n))
            if (!root.dnd || n.urgency === NotificationUrgency.Critical) {
                root.popups = root.popups.concat([n]).slice(-5)
                root.arrived(n)
            }
        }
    }
}
