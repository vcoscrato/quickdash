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
    property bool hasBacklightDevice: false
    property bool backendCheckComplete: false
    property bool helperAvailable: false
    property bool nightLightOn: false
    property string backlightDeviceName: ""
    property string unavailableReason: ""

    readonly property bool canControlBrightness: root.hasBacklightDevice && root.helperAvailable
    readonly property string brightnessPath: root.backlightDeviceName !== ""
        ? "/sys/class/backlight/" + root.backlightDeviceName + "/brightness"
        : ""
    readonly property string maxBrightnessPath: root.backlightDeviceName !== ""
        ? "/sys/class/backlight/" + root.backlightDeviceName + "/max_brightness"
        : ""

    function updateAvailability() {
        if (!root.hasBacklightDevice) {
            root.unavailableReason = "";
            return;
        }

        if (!root.backendCheckComplete) {
            root.unavailableReason = "Checking brightness backend...";
            return;
        }

        root.unavailableReason = root.canControlBrightness
            ? ""
            : "Install brightnessctl to enable brightness control.";
    }

    function updateBrightnessFromFiles() {
        if (!root.hasBacklightDevice || !brightnessValueFile.loaded || !maxBrightnessValueFile.loaded) {
            return;
        }

        var current = parseInt((brightnessValueFile.text() || "").trim(), 10);
        var max = parseInt((maxBrightnessValueFile.text() || "").trim(), 10);
        if (isNaN(current) || isNaN(max) || max <= 0) {
            return;
        }

        var pct = Math.max(0, Math.min(100, Math.round((current / max) * 100)));
        root.brightnessPercent = pct;
        if (!brightnessSetProc.running && !brightnessSetDebounce.running) {
            root.pendingBrightnessPercent = pct;
        }
    }

    function requestBrightnessRefresh() {
        if (!root.dashboardActive || !root.hasBacklightDevice) {
            return;
        }
        brightnessValueFile.reload();
        maxBrightnessValueFile.reload();
    }

    function commitBrightness() {
        if (!root.canControlBrightness) {
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
        backlightProbeProc.running = true;
        helperCheckProc.running = true;
    }

    FileView {
        id: brightnessValueFile
        path: root.brightnessPath
        printErrors: false
        watchChanges: true
        onLoaded: root.updateBrightnessFromFiles()
        onTextChanged: root.updateBrightnessFromFiles()
        onFileChanged: reload()
    }

    FileView {
        id: maxBrightnessValueFile
        path: root.maxBrightnessPath
        printErrors: false
        watchChanges: true
        onLoaded: root.updateBrightnessFromFiles()
        onTextChanged: root.updateBrightnessFromFiles()
        onFileChanged: reload()
    }

    Process {
        id: backlightProbeProc
        command: ["ls", "-1", "/sys/class/backlight"]
        running: false
        property string detectedDevice: ""
        onRunningChanged: if (running) detectedDevice = ""
        stdout: SplitParser {
            onRead: function(line) {
                var trimmed = (line || "").trim();
                if (trimmed !== "" && backlightProbeProc.detectedDevice === "") {
                    backlightProbeProc.detectedDevice = trimmed;
                }
            }
        }
        onExited: {
            root.backlightDeviceName = backlightProbeProc.detectedDevice;
            root.hasBacklightDevice = root.backlightDeviceName !== "";
            root.updateAvailability();
            if (root.hasBacklightDevice && root.dashboardActive) {
                root.requestBrightnessRefresh();
            }
        }
    }

    Process {
        id: helperCheckProc
        command: ["which", "brightnessctl"]
        running: false
        onExited: function(exitCode) {
            root.helperAvailable = exitCode === 0;
            root.backendCheckComplete = true;
            root.updateAvailability();
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

    // Hide only when there is no backlight device on the system.
    visible: root.hasBacklightDevice

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
                enabled: root.canControlBrightness
                opacity: enabled ? 1.0 : 0.55
                onMoved: {
                    if (!enabled) {
                        return;
                    }
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

        Text {
            visible: root.unavailableReason !== ""
            text: root.unavailableReason
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.subtext
            width: parent.width
            wrapMode: Text.WordWrap
        }
    }
}
