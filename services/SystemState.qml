pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool dashboardVisible: true
    property bool dashboardActive: true
    property bool debugLogging: false
    property bool dndEnabled: false
    // Populated by the config loader — XDG-resolved paths for data files
    // and the user's config file. Widgets read these instead of hardcoding.
    property string dataDir: ""
    property string configPath: ""
    property var notificationHistory: []
    property var activePopups: []
    property int popupCounter: 0

    // Map of popupId → Timer object for proper cleanup on manual dismiss
    property var popupTimers: ({})

    // Incremented periodically to force re-evaluation of time-ago strings
    property int refreshTick: 0

    Timer {
        id: refreshTickTimer
        interval: 30000 // 30 seconds
        running: root.dashboardVisible
        repeat: true
        onTriggered: root.refreshTick++
    }

    function debugLog(message) {
        if (!root.debugLogging)
            return;
        console.log("[QuickDash][SystemState] " + message);
    }

    function setDashboardState(visible, active) {
        root.dashboardVisible = !!visible;
        root.dashboardActive = !!active;
        root.debugLog("dashboard state visible=" + root.dashboardVisible + " active=" + root.dashboardActive);
    }

    function dismissPopup(popupId) {
        root.debugLog("dismissPopup(" + popupId + ") beforeCount=" + root.activePopups.length);
        var current = root.activePopups.slice();
        for (var i = 0; i < current.length; i++) {
            if (current[i].popupId === popupId) {
                current.splice(i, 1);
                break;
            }
        }
        root.activePopups = current;

        // Clean up the associated timer
        var timers = root.popupTimers;
        if (timers[popupId]) {
            timers[popupId].stop();
            timers[popupId].destroy();
            delete timers[popupId];
            root.popupTimers = timers;
        }

        root.debugLog("dismissPopup(" + popupId + ") afterCount=" + root.activePopups.length);
    }

    function clearHistory() {
        root.notificationHistory = [];
    }

    function removeHistoryAt(index) {
        var current = root.notificationHistory.slice();
        if (index >= 0 && index < current.length) {
            current.splice(index, 1);
            root.notificationHistory = current;
        }
    }

    function timeoutForUrgency(urgency) {
        // NotificationUrgency: Low=0, Normal=1, Critical=2
        if (urgency === 2) return 10000; // Critical: 10s
        if (urgency === 0) return 3000;  // Low: 3s
        return 5000;                      // Normal: 5s
    }

    function addNotification(notification, timerParent) {
        if (!notification)
            return;

        root.debugLog("notification received app='" + (notification.appName || "")
            + "' summary='" + (notification.summary || "")
            + "' urgency=" + notification.urgency
            + " dnd=" + root.dndEnabled);

        if (!root.dndEnabled) {
            var popupId = root.popupCounter++;
            var popupObj = {
                popupId: popupId,
                id: notification.id,
                appName: notification.appName,
                summary: notification.summary,
                body: notification.body,
                urgency: notification.urgency,
                time: new Date()
            };

            var currentPopups = root.activePopups.slice();
            currentPopups.push(popupObj);
            if (currentPopups.length > 5)
                currentPopups.shift();
            root.activePopups = currentPopups;
            root.debugLog("activePopups count=" + root.activePopups.length);

            var parentObj = timerParent || root;
            var timer = Qt.createQmlObject("import QtQml; Timer {}", parentObj);
            timer.interval = root.timeoutForUrgency(notification.urgency);
            timer.repeat = false;
            timer.triggered.connect(function() {
                root.debugLog("popup timer fired popupId=" + popupId);
                root.dismissPopup(popupId);
            });
            timer.start();

            // Store reference for cleanup on manual dismiss
            var timers = root.popupTimers;
            timers[popupId] = timer;
            root.popupTimers = timers;
        }

        var history = root.notificationHistory.slice();
        history.unshift({
            id: notification.id,
            appName: notification.appName,
            summary: notification.summary,
            body: notification.body,
            urgency: notification.urgency,
            time: new Date()
        });
        if (history.length > 50)
            history = history.slice(0, 50);
        root.notificationHistory = history;
        root.debugLog("notificationHistory count=" + root.notificationHistory.length);
    }
}
