pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    property bool dashboardVisible: true
    property bool dashboardActive: true
    property bool dndEnabled: false

    property var notificationHistory: []
    property var activePopups: []
    property int popupCounter: 0

    function setDashboardState(visible, active) {
        root.dashboardVisible = !!visible;
        root.dashboardActive = !!active;
    }

    function dismissPopup(popupId) {
        var current = root.activePopups.slice();
        for (var i = 0; i < current.length; i++) {
            if (current[i].popupId === popupId) {
                current.splice(i, 1);
                break;
            }
        }
        root.activePopups = current;
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

    function addNotification(notification, timerParent) {
        if (!notification)
            return;

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

            var parentObj = timerParent || root;
            var timer = Qt.createQmlObject("import QtQml; Timer {}", parentObj);
            timer.interval = 5000;
            timer.repeat = false;
            timer.triggered.connect(function() {
                root.dismissPopup(popupId);
                timer.destroy();
            });
            timer.start();
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
    }
}
