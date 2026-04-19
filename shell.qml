//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Notifications
import QtQuick
import "services" as Services
import "theme" as ThemeModule
import "core" as Core

ShellRoot {
    id: root

    function defaultSidebarIcon(widgetName) {
        var map = {
            "capturePad": "🗂",
            "quickCommands": "🚀",
            "configPanel": "⚙",
            "networkPanel": "📶",
            "bluetoothPanel": "🔵",
            "audioControl": "🔊",
            "audioInputControl": "🎤",
            "brightnessControl": "☀",
            "displayControl": "🖥",
            "keyboardLayout": "⌨",
            "systemMonitor": "📊",
            "powerMenu": "⏻"
        };
        return map[widgetName] || "❓";
    }

    function normalizeWidgetName(name) {
        switch (name) {
        case "clipboardHistory":
        case "scratchpad":
            return "capturePad";
        case "quickTimer":
        case "screenshotControls":
            return "";
        default:
            return typeof name === "string" ? name : "";
        }
    }

    function normalizeWidgetList(list) {
        if (!Array.isArray(list)) {
            return [];
        }

        var output = [];
        var seen = ({});
        for (var i = 0; i < list.length; i++) {
            var widgetName = root.normalizeWidgetName(list[i]);
            if (!widgetName || seen[widgetName]) {
                continue;
            }
            seen[widgetName] = true;
            output.push(widgetName);
        }
        return output;
    }

    function normalizeSidebarItems(items) {
        if (!Array.isArray(items)) {
            return [];
        }

        var output = [];
        var seen = ({});
        for (var i = 0; i < items.length; i++) {
            var item = items[i];
            var rawWidget = typeof item === "string" ? item : item.widget;
            var widgetName = root.normalizeWidgetName(rawWidget);
            if (!widgetName || seen[widgetName]) {
                continue;
            }

            seen[widgetName] = true;
            var iconText = typeof item === "object" && item && item.icon ? item.icon : root.defaultSidebarIcon(widgetName);
            if (widgetName !== rawWidget) {
                iconText = root.defaultSidebarIcon(widgetName);
            }

            output.push({
                widget: widgetName,
                icon: iconText
            });
        }

        return output;
    }

    function normalizeEnvironment(env) {
        var normalized = ({});
        if (!env || typeof env !== "object" || Array.isArray(env)) {
            return normalized;
        }

        var keys = Object.keys(env);
        for (var i = 0; i < keys.length; i++) {
            var key = keys[i];
            var value = env[key];
            if (value === null) {
                normalized[key] = null;
            } else if (value !== undefined) {
                normalized[key] = String(value);
            }
        }

        return normalized;
    }

    function normalizeCommandList(commandValue, argsValue) {
        if (Array.isArray(commandValue)) {
            return commandValue.filter(function(part) {
                return typeof part === "string" && part.trim() !== "";
            }).map(function(part) {
                return part.trim();
            });
        }

        if (typeof commandValue !== "string" || commandValue.trim() === "") {
            return [];
        }

        var command = [commandValue.trim()];
        if (Array.isArray(argsValue)) {
            for (var i = 0; i < argsValue.length; i++) {
                if (typeof argsValue[i] === "string" && argsValue[i].trim() !== "") {
                    command.push(argsValue[i].trim());
                }
            }
        }
        return command;
    }

    function normalizeLauncherItem(item, index) {
        if (!item || typeof item !== "object") {
            return null;
        }

        var normalized = {
            label: item.label || item.name || ("Item " + (index + 1)),
            icon: item.icon || "🚀",
            mode: "",
            command: [],
            shell: "",
            desktop: "",
            workingDirectory: typeof item.workingDirectory === "string" ? item.workingDirectory : "",
            environment: root.normalizeEnvironment(item.environment),
            clearEnvironment: !!item.clearEnvironment,
            closeOnLaunch: item.closeOnLaunch !== false
        };

        var commandList = root.normalizeCommandList(item.command, item.args);
        if (commandList.length > 0) {
            normalized.mode = "command";
            normalized.command = commandList;
            return normalized;
        }

        if (typeof item.shell === "string" && item.shell.trim() !== "") {
            normalized.mode = "shell";
            normalized.shell = item.shell.trim();
            return normalized;
        }

        if (typeof item.desktop === "string" && item.desktop.trim() !== "") {
            normalized.mode = "desktop";
            normalized.desktop = item.desktop.trim();
            return normalized;
        }

        if (typeof item.cmd === "string" && item.cmd.trim() !== "") {
            normalized.mode = "shell";
            normalized.shell = item.cmd.trim();
            return normalized;
        }

        return null;
    }

    function normalizeLauncherItems(items) {
        if (!Array.isArray(items)) {
            return [];
        }

        var output = [];
        for (var i = 0; i < items.length; i++) {
            var normalized = root.normalizeLauncherItem(items[i], i);
            if (normalized) {
                output.push(normalized);
            }
        }
        return output;
    }

    function normalizeConfig(config) {
        var input = config && typeof config === "object" ? config : ({});
        var normalized = ({});

        var keys = Object.keys(input);
        for (var i = 0; i < keys.length; i++) {
            normalized[keys[i]] = input[keys[i]];
        }

        normalized.quickCommands = root.normalizeLauncherItems(input.quickCommands || []);

        if ("topAnchor" in input) {
            normalized.topAnchor = root.normalizeWidgetList(input.topAnchor);
        }
        if ("bottomAnchor" in input) {
            normalized.bottomAnchor = root.normalizeWidgetList(input.bottomAnchor);
        }
        if ("middleDefault" in input) {
            normalized.middleDefault = root.normalizeWidgetList(input.middleDefault);
        }
        if ("sidebar" in input) {
            normalized.sidebar = root.normalizeSidebarItems(input.sidebar);
        }

        return normalized;
    }

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
        printErrors: false
    }

    FileView {
        id: fallbackConfigFile
        path: Qt.resolvedUrl("config.example.json")
        blockLoading: true
        printErrors: false
    }

    // Parse config from file
    Component.onCompleted: {
        Services.SystemState.setDashboardState(root.dashboardVisible, root.dashboardActive);
        try {
            var configText = configFile.text();
            if (!configText || configText.trim() === "") {
                configText = fallbackConfigFile.text();
            }
            root.config = root.normalizeConfig(JSON.parse(configText));
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

        implicitWidth: root.config && root.config.windowWidth ? root.config.windowWidth : 420
        implicitHeight: root.config && root.config.windowHeight ? root.config.windowHeight : 900

        color: ThemeModule.Theme.bg
        onClosed: Qt.quit()

        Core.Dashboard {
            anchors.fill: parent
            config: root.config
            dashboardVisible: root.dashboardVisible
            dashboardActive: root.dashboardActive
        }
    }

    // ── Notification Toasts ─────────────────────────────
    Core.NotificationToastWindow {}
}
