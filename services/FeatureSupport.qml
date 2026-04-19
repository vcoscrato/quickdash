pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import "." as LocalServices

Singleton {
    id: root

    property bool hasBacklightDevice: false
    property bool brightnessHelperAvailable: false
    property bool hyprctlAvailable: false
    property bool bluetoothControllerAvailable: false

    readonly property var battery: UPower.displayDevice
    readonly property bool supportsBattery: root.battery !== null
        && root.battery.ready
        && root.battery.isLaptopBattery
        && root.battery.isPresent
    readonly property bool supportsBrightness: root.hasBacklightDevice && root.brightnessHelperAvailable
    readonly property bool supportsHyprland: root.hyprctlAvailable
    readonly property bool supportsBluetooth: root.bluetoothControllerAvailable
    readonly property bool supportsDisplayControl: root.supportsHyprland && LocalServices.DisplayService.hasMultipleMonitors

    Component.onCompleted: {
        backlightProbeProc.running = true;
        brightnessctlProc.running = true;
        hyprctlProc.running = true;
        bluetoothProbeProc.running = true;
    }

    Process {
        id: backlightProbeProc
        command: ["ls", "-1", "/sys/class/backlight"]
        running: false
        property bool foundDevice: false
        onRunningChanged: if (running) foundDevice = false
        stdout: SplitParser {
            onRead: function(line) {
                if ((line || "").trim() !== "") {
                    backlightProbeProc.foundDevice = true;
                }
            }
        }
        onExited: root.hasBacklightDevice = backlightProbeProc.foundDevice
    }

    Process {
        id: brightnessctlProc
        command: ["which", "brightnessctl"]
        running: false
        onExited: function(exitCode) {
            root.brightnessHelperAvailable = exitCode === 0;
        }
    }

    Process {
        id: hyprctlProc
        command: ["which", "hyprctl"]
        running: false
        onExited: function(exitCode) {
            root.hyprctlAvailable = exitCode === 0;
        }
    }

    Process {
        id: bluetoothProbeProc
        command: ["sh", "-lc", "command -v bluetoothctl >/dev/null 2>&1 && bluetoothctl list || true"]
        running: false
        property bool foundController: false
        onRunningChanged: if (running) foundController = false
        stdout: SplitParser {
            onRead: function(line) {
                if ((line || "").indexOf("Controller ") === 0) {
                    bluetoothProbeProc.foundController = true;
                }
            }
        }
        onExited: root.bluetoothControllerAvailable = bluetoothProbeProc.foundController
    }
}