import QtQuick
import Quickshell.Io
import "../components" as Components
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Brightness"
    icon: "☀"
    property bool dashboardActive: true
    headerActions: Components.TogglePill {
        iconText: "🌙"
        label: "Night Light"
        checked: root.nightLightOn
        activeColor: ThemeModule.Theme.yellow
        onToggled: function(state) {
            root.nightLightOn = state;
            if (state) {
                nightLightOnProc.running = true;
            } else {
                nightLightOffProc.running = true;
            }
        }
    }

    property int brightnessPercent: 0
    property int pendingBrightnessPercent: 0
    property bool brightnessCommitQueued: false
    property bool available: false
    property bool nightLightOn: false

    function requestBrightnessRefresh() {
        if (!root.dashboardActive || brightnessGetProc.running) {
            return;
        }
        brightnessGetProc.running = true;
    }

    function commitBrightness() {
        if (!root.available) {
            return;
        }
        if (brightnessSetProc.running) {
            root.brightnessCommitQueued = true;
            return;
        }
        root.brightnessCommitQueued = false;
        brightnessSetProc.command = ["brightnessctl", "set", root.pendingBrightnessPercent + "%"];
        brightnessSetProc.running = true;
    }

    // ── Read current brightness on load ──────
    Component.onCompleted: {
        if (root.dashboardActive) {
            root.requestBrightnessRefresh();
        }
    }

    Process {
        id: brightnessGetProc
        command: ["brightnessctl", "info", "-m"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                // brightnessctl -m format: device,class,current,percent%,max
                var parts = line.split(",");
                if (parts.length >= 5) {
                    var pctStr = (parts[3] || "").replace("%", "").trim();
                    var pct = parseInt(pctStr);
                    if (!isNaN(pct) && pct >= 0 && pct <= 100) {
                        root.brightnessPercent = pct;
                        if (!brightnessSetProc.running && !brightnessSetDebounce.running) {
                            root.pendingBrightnessPercent = root.brightnessPercent;
                        }
                        root.available = true;
                    } else {
                        console.warn("[QuickDash] Unexpected brightnessctl output — could not parse percent from field 4:", parts[3]);
                        root.available = true;
                        root.brightnessPercent = 50; // fallback
                    }
                } else {
                    console.warn("[QuickDash] Unexpected brightnessctl -m output format (" + parts.length + " fields, expected 5):", line);
                }
            }
        }
    }

    Process {
        id: brightnessSetProc
        command: ["brightnessctl", "set", root.brightnessPercent + "%"]
        running: false
        onExited: {
            if (root.brightnessCommitQueued) {
                root.commitBrightness();
                return;
            }
            root.requestBrightnessRefresh();
        }
    }

    Process {
        id: nightLightOnProc
        command: ["hyprctl", "dispatch", "exec", "hyprsunset -t 4500"]
        running: false
    }

    Process {
        id: nightLightOffProc
        command: ["pkill", "hyprsunset"]
        running: false
    }

    Timer {
        id: brightnessSetDebounce
        interval: 120
        running: false
        repeat: false
        onTriggered: root.commitBrightness()
    }

    onDashboardActiveChanged: {
        if (root.dashboardActive) {
            root.requestBrightnessRefresh();
        }
    }

    // Hide if brightnessctl is not available
    visible: root.available

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium

        Row {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            Components.IconButton {
                iconText: root.brightnessPercent <= 30 ? "🔅" : "🔆"
                size: 32
                anchors.verticalCenter: parent.verticalCenter
            }

            Components.StyledSlider {
                width: parent.width - 80
                anchors.verticalCenter: parent.verticalCenter
                value: root.brightnessPercent
                onMoved: {
                    root.pendingBrightnessPercent = Math.round(value);
                    root.brightnessPercent = root.pendingBrightnessPercent;
                    brightnessSetDebounce.restart();
                }
                onPressedChanged: if (!pressed && brightnessSetDebounce.running) {
                    brightnessSetDebounce.stop();
                    root.commitBrightness();
                }
            }

            Text {
                text: root.brightnessPercent + "%"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
                width: 36
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}
