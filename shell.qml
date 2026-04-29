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

    function applyConfig(configValue) {
        var normalized = root.normalizeConfig(configValue || {});
        root.config = normalized;
        ThemeModule.Theme.paletteName = normalized.colorScheme || "everforest";
        Services.WeatherService.location = normalized.weatherLocation || "";
    }

    function defaultSidebarIcon(widgetName) {
        var map = {
            "clock": "🕐",
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
            "notificationCenter": "🔔",
            "calendar": "📅",
            "batteryStatus": "🔋",
            "systemMonitor": "📊",
            "systemTray": "▫",
            "todoList": "✓",
            "randomQuote": "💭",
            "nowPlaying": "🎵",
            "powerMenu": "⏻"
        };
        return map[widgetName] || "❓";
    }

    function normalizeWidgetName(name) {
        return typeof name === "string" ? name : "";
    }

    function normalizeWidgetList(list) {
        if (!Array.isArray(list)) {
            return [];
        }

        var output = [];
        var seen = ({});
        for (var i = 0; i < list.length; i++) {
            var item = list[i];

            // Nested array = row group (widgets rendered side-by-side)
            // Use a plain object so QML var/Repeater preserves the type reliably.
            if (Array.isArray(item)) {
                var group = [];
                for (var j = 0; j < item.length; j++) {
                    var gName = root.normalizeWidgetName(item[j]);
                    if (gName && !seen[gName]) {
                        seen[gName] = true;
                        group.push(gName);
                    }
                }
                if (group.length > 0) {
                    output.push({ group: true, items: group });
                }
                continue;
            }

            var widgetName = root.normalizeWidgetName(item);
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

    function shellQuote(s) {
        return "'" + String(s).replace(/'/g, "'\"'\"'") + "'";
    }

    // Strip // line comments and /* */ block comments from a JSON string.
    // Handles strings correctly — comment markers inside strings are ignored.
    // Uses only ES5-compatible String methods (QML V4 JS engine).
    function stripJsonComments(str) {
        var out = "";
        var i = 0;
        var len = str.length;
        var inString = false;
        var inLineComment = false;
        var inBlockComment = false;
        while (i < len) {
            var ch   = str[i];
            var next = (i + 1 < len) ? str[i + 1] : "";
            if (inLineComment) {
                if (ch === "\n") { inLineComment = false; out += ch; }
            } else if (inBlockComment) {
                if (ch === "*" && next === "/") { inBlockComment = false; i++; }
            } else if (inString) {
                out += ch;
                if (ch === "\\") { i++; if (i < len) { out += str[i]; } }
                else if (ch === "\"") { inString = false; }
            } else {
                if      (ch === "/" && next === "/") { inLineComment  = true; i++; }
                else if (ch === "/" && next === "*") { inBlockComment = true; i++; }
                else { if (ch === "\"") { inString = true; } out += ch; }
            }
            i++;
        }
        return out;
    }

    function stripTrailingJsonCommas(str) {
        var out = "";
        var i = 0;
        var len = str.length;
        var inString = false;
        while (i < len) {
            var ch = str[i];
            if (inString) {
                out += ch;
                if (ch === "\\") {
                    i++;
                    if (i < len) {
                        out += str[i];
                    }
                } else if (ch === "\"") {
                    inString = false;
                }
            } else {
                if (ch === "\"") {
                    inString = true;
                    out += ch;
                } else if (ch === ",") {
                    var j = i + 1;
                    while (j < len && /\s/.test(str[j])) {
                        j++;
                    }
                    if (j >= len || (str[j] !== "}" && str[j] !== "]")) {
                        out += ch;
                    }
                } else {
                    out += ch;
                }
            }
            i++;
        }
        return out;
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

    onDashboardVisibleChanged: {
        if (Services.SystemState.debugLogging)
            console.log("[QuickDash][Shell] dashboardVisible=" + root.dashboardVisible);
        Services.SystemState.setDashboardState(root.dashboardVisible, root.dashboardActive)
    }

    onDashboardActiveChanged: {
        if (Services.SystemState.debugLogging)
            console.log("[QuickDash][Shell] dashboardActive=" + root.dashboardActive);
        Services.SystemState.setDashboardState(root.dashboardVisible, root.dashboardActive)
    }

    NotificationServer {
        id: notifServer

        onNotification: function(notification) {
            Services.SystemState.addNotification(notification, root);
            notification.tracked = true;
        }
    }

    // ── JSONC config loading via XDG paths ─────────────────────────────────────
    //
    // A single sh call resolves XDG dirs and reads the config file. Output:
    //   line 1  — config dir   e.g. /home/user/.config/quickdash
    //   line 2  — data dir     e.g. /home/user/.local/share/quickdash
    //   line 3+ — JSONC content (user config if present, bundled example otherwise)
    //
    // Comments are stripped in pure JS (stripJsonComments) before JSON.parse().
    // No external scripts, no Python — just sh, cat, and QML.
    //
    // Quickshell.reload() re-runs everything including this Process, so
    // native hot-reload works exactly as expected.

    readonly property string _bundledExample: Qt.resolvedUrl("config.example.jsonc").toString().replace(/^file:\/\//, "")

    Process {
        id: configLoadProc
        running: false
        stdout: StdioCollector {
            id: configOutput
        }
        onExited: function(exitCode) {
            var text = configOutput.text || "";
            var nl1 = text.indexOf("\n");
            var nl2 = text.indexOf("\n", nl1 + 1);
            if (nl1 === -1 || nl2 === -1) {
                console.warn("[QuickDash] Unexpected config loader output, using defaults");
                root.applyConfig({});
                return;
            }
            var configDir = text.substring(0, nl1);
            var dataDir   = text.substring(nl1 + 1, nl2);
            var jsonc     = text.substring(nl2 + 1);
            Services.SystemState.dataDir    = dataDir;
            Services.SystemState.configPath = configDir + "/config.jsonc";
            if (jsonc.replace(/\s/g, "") === "") {
                console.warn("[QuickDash] Config file empty, using defaults");
                root.applyConfig({});
                return;
            }
            try {
                var parsed = JSON.parse(root.stripTrailingJsonCommas(root.stripJsonComments(jsonc)).trim());
                root.applyConfig(parsed);
            } catch (e) {
                console.warn("[QuickDash] Config parse failed:", e);
                root.applyConfig({});
            }
        }
    }

    Component.onCompleted: {
        if (Services.SystemState.debugLogging)
            console.log("[QuickDash][Shell] component completed dashboardVisible=" + root.dashboardVisible
                + " dashboardActive=" + root.dashboardActive);
        Services.SystemState.setDashboardState(root.dashboardVisible, root.dashboardActive);
        configLoadProc.command = [
            "sh", "-c",
            "printf '%s\\n%s\\n' " +
            "\"${XDG_CONFIG_HOME:-$HOME/.config}/quickdash\" " +
            "\"${XDG_DATA_HOME:-$HOME/.local/share}/quickdash\"; " +
            "cat \"${XDG_CONFIG_HOME:-$HOME/.config}/quickdash/config.jsonc\" 2>/dev/null " +
            "|| cat " + root.shellQuote(root._bundledExample)
        ];
        configLoadProc.running = true;
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
