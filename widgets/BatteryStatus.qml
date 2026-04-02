import QtQuick
import Quickshell.Services.UPower
import "../components" as Components
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: ""

    visible: root.batteryReady && root.battery.isLaptopBattery && root.battery.isPresent

    readonly property var battery: UPower.displayDevice
    readonly property bool batteryReady: root.battery !== null && root.battery.ready
    readonly property real batteryPercent: root.batteryReady ? root.battery.percentage * 100 : 0
    readonly property bool isCharging: root.batteryReady && (
        root.battery.state === UPowerDeviceState.Charging
        || root.battery.state === UPowerDeviceState.PendingCharge
    )

    function getBatteryIcon(percentage, charging) {
        if (charging) return "🔌";
        if (percentage > 60) return "🔋";
        if (percentage > 10) return "🪫";
        return "🪫";
    }

    function formatTimeRemaining(seconds) {
        if (!seconds || seconds <= 0) return "";
        var hours = Math.floor(seconds / 3600);
        var mins = Math.floor((seconds % 3600) / 60);
        if (hours > 0) return hours + "h " + mins + "m remaining";
        return mins + "m remaining";
    }

    Row {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Text {
            text: root.batteryReady ? root.getBatteryIcon(root.batteryPercent, root.isCharging) : "🔋"
            font.pixelSize: ThemeModule.Theme.fontSizeLarge
            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Row {
                spacing: ThemeModule.Theme.spacingSmall

                Text {
                    text: "Battery"
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    font.family: ThemeModule.Theme.fontFamily
                    font.bold: true
                    color: ThemeModule.Theme.text
                }

                Text {
                    text: root.batteryReady ? Math.round(root.batteryPercent) + "%" : "—"
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    font.family: ThemeModule.Theme.fontFamily
                    color: {
                        if (!root.batteryReady) return ThemeModule.Theme.subtext;
                        var pct = root.batteryPercent;
                        if (pct > 30) return ThemeModule.Theme.success;
                        if (pct > 10) return ThemeModule.Theme.warning;
                        return ThemeModule.Theme.error;
                    }
                }
            }

            Text {
                text: {
                    if (!root.batteryReady) return "";
                    if (root.isCharging) {
                        var timeToFull = root.formatTimeRemaining(root.battery.timeToFull);
                        return timeToFull ? ("⚡ " + timeToFull + " until full") : "⚡ Charging";
                    }
                    return root.formatTimeRemaining(root.battery.timeToEmpty);
                }
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
                visible: text !== ""
            }
        }

        Item { width: 10; height: 1 }

        Rectangle {
            width: 60
            height: 20
            radius: 4
            color: ThemeModule.Theme.surface2
            anchors.verticalCenter: parent.verticalCenter
            border.width: 1
            border.color: ThemeModule.Theme.overlay

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 2
                width: root.batteryReady ? (root.batteryPercent / 100) * (parent.width - 4) : 0
                radius: 2
                color: {
                    if (!root.batteryReady) return ThemeModule.Theme.subtext;
                    var pct = root.batteryPercent;
                    if (pct > 30) return ThemeModule.Theme.success;
                    if (pct > 10) return ThemeModule.Theme.warning;
                    return ThemeModule.Theme.error;
                }

                Behavior on width {
                    NumberAnimation { duration: ThemeModule.Theme.animDurationSlow }
                }
                Behavior on color {
                    ColorAnimation { duration: ThemeModule.Theme.animDurationSlow }
                }
            }

            Rectangle {
                anchors.left: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 3
                height: 8
                radius: 1
                color: ThemeModule.Theme.overlay
            }
        }
    }
}
