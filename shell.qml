//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import "services" as Services
import "theme" as ThemeModule

ShellRoot {
    id: root

    // ── Config loading ──────────────────────────────────
    property var config: null
    readonly property bool dashboardVisible: dashWindow.backingWindowVisible && !dashWindow.minimized
    readonly property bool dashboardActive: root.dashboardVisible && (("active" in dashWindow) ? dashWindow.active : true)

    onDashboardVisibleChanged: Services.SystemState.setDashboardState(root.dashboardVisible, root.dashboardActive)
    onDashboardActiveChanged: Services.SystemState.setDashboardState(root.dashboardVisible, root.dashboardActive)

    NotificationServer {
        id: notifServer

        onNotification: function(notification) {
            Services.SystemState.addNotification(notification, root);
            notification.tracked = true;
        }
    }

    FileView {
        id: configFile
        path: Qt.resolvedUrl("config.json")
        blockLoading: true
    }

    FileView {
        id: fallbackConfigFile
        path: Qt.resolvedUrl("config.example.json")
        blockLoading: true
    }

    // Parse config from file
    Component.onCompleted: {
        Services.SystemState.setDashboardState(root.dashboardVisible, root.dashboardActive);
        try {
            var configText = configFile.text();
            if (!configText || configText.trim() === "") {
                configText = fallbackConfigFile.text();
            }
            root.config = JSON.parse(configText);
            ThemeModule.Theme.paletteName = root.config.colorScheme || "catppuccin-mocha";
        } catch (e) {
            console.warn("[QuickDash] Failed to parse config JSON:", e);
            root.config = {};
        }
    }

    // ── Dashboard Window ────────────────────────────────
    FloatingWindow {
        id: dashWindow
        visible: true
        title: "QuickDash"

        implicitWidth: root.config && root.config.windowWidth ? root.config.windowWidth : 480
        implicitHeight: root.config && root.config.windowHeight ? root.config.windowHeight : 900

        color: ThemeModule.Theme.bg
        onClosed: Qt.quit()

        Dashboard {
            anchors.fill: parent
            config: root.config
            dashboardVisible: root.dashboardVisible
            dashboardActive: root.dashboardActive
        }
    }

    // ── Notification Toasts ─────────────────────────────
    NotificationToastWindow {}
}
