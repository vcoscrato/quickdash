import QtQuick
import Quickshell.Io
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Bluetooth"
    icon: "🔵"
    collapsible: true
    property bool dashboardActive: true

    headerActions: Components.ModeSlider {
        leftLabel: "Off"
        rightLabel: "On"
        selectedIndex: Services.BluetoothService.btOn ? 1 : 0
        activeColor: ThemeModule.Theme.blue
        onChanged: function(index) {
            Services.BluetoothService.togglePower(index === 1);
        }
    }

    onDashboardActiveChanged: {
        if (root.dashboardActive)
            Services.BluetoothService.refreshAll(true);
    }

    onCollapsedChanged: {
        if (!root.collapsed && root.dashboardActive)
            Services.BluetoothService.refreshAll(true);
    }

    // Helper to build subtitle with connecting/disconnecting status
    function deviceSubtitle(row) {
        if (Services.BluetoothService.connectingMac === row.mac) return "Connecting...";
        if (Services.BluetoothService.disconnectingMac === row.mac) return "Disconnecting...";
        return "";
    }

    function deviceOpacity(row) {
        var busy = Services.BluetoothService.connectingMac !== "" || Services.BluetoothService.disconnectingMac !== "";
        if (!busy) return 1.0;
        if (Services.BluetoothService.connectingMac === row.mac || Services.BluetoothService.disconnectingMac === row.mac) return 1.0;
        return 0.5;
    }

    pinnedContent: [
        Components.DeviceSection {
            visible: Services.BluetoothService.btOn && Services.BluetoothService.connectedRows.length > 0
            width: parent.width
            title: "Connected"
            count: Services.BluetoothService.connectedRows.length
        },

        Repeater {
            model: Services.BluetoothService.btOn ? Services.BluetoothService.connectedRows : []
            delegate: Components.DeviceRow {
                width: parent.width
                title: modelData.name
                subtitle: root.deviceSubtitle(modelData)
                leadingIcon: modelData.icon
                badges: []
                primaryEnabled: Services.BluetoothService.disconnectingMac === "" && Services.BluetoothService.connectingMac === ""
                opacity: root.deviceOpacity(modelData)
                onPrimaryTriggered: Services.BluetoothService.onRowPrimary(modelData)

                Behavior on opacity {
                    NumberAnimation { duration: ThemeModule.Theme.animDuration }
                }
            }
        },

        Text {
            visible: !Services.BluetoothService.btOn
            text: "Bluetooth is off"
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.overlay
            anchors.horizontalCenter: parent.horizontalCenter
        },

        Text {
            visible: Services.BluetoothService.btOn && Services.BluetoothService.connectedRows.length === 0 && !root.collapsed
            text: "No connected devices"
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.overlay
            anchors.horizontalCenter: parent.horizontalCenter
        },

        Rectangle {
            visible: Services.BluetoothService.btOn && Services.BluetoothService.connectedRows.length === 0 && root.collapsed
            width: parent.width
            height: 30
            radius: ThemeModule.Theme.borderRadiusSmall
            color: collapsedScanMouse.containsMouse ? ThemeModule.Theme.cardHover : ThemeModule.Theme.card
            border.width: 1
            border.color: Qt.rgba(ThemeModule.Theme.blue.r, ThemeModule.Theme.blue.g, ThemeModule.Theme.blue.b, 0.3)

            Text {
                anchors.centerIn: parent
                text: "🔍 Scan for devices"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.blue
            }

            MouseArea {
                id: collapsedScanMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.collapsed = false;
                    Services.BluetoothService.startScan();
                }
            }
        }
    ]

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Components.DeviceSection {
            visible: Services.BluetoothService.btOn && Services.BluetoothService.knownRows.length > 0
            width: parent.width
            title: "Known"
            count: Services.BluetoothService.knownRows.length
        }

        Repeater {
            model: Services.BluetoothService.btOn ? Services.BluetoothService.knownRows : []
            delegate: Components.DeviceRow {
                width: parent.width
                title: modelData.name
                subtitle: root.deviceSubtitle(modelData)
                leadingIcon: modelData.icon
                badges: []
                primaryEnabled: Services.BluetoothService.disconnectingMac === "" && Services.BluetoothService.connectingMac === ""
                opacity: root.deviceOpacity(modelData)
                onPrimaryTriggered: Services.BluetoothService.onRowPrimary(modelData)

                Behavior on opacity {
                    NumberAnimation { duration: ThemeModule.Theme.animDuration }
                }
            }
        }

        Components.DeviceSection {
            visible: Services.BluetoothService.btOn && Services.BluetoothService.discoveredRows.length > 0
            width: parent.width
            title: "Discovered"
            count: Services.BluetoothService.discoveredRows.length
        }

        Repeater {
            model: Services.BluetoothService.btOn ? Services.BluetoothService.discoveredRows : []
            delegate: Components.DeviceRow {
                width: parent.width
                title: modelData.name
                subtitle: root.deviceSubtitle(modelData)
                leadingIcon: modelData.icon
                badges: []
                primaryEnabled: Services.BluetoothService.disconnectingMac === "" && Services.BluetoothService.connectingMac === ""
                opacity: root.deviceOpacity(modelData)
                onPrimaryTriggered: Services.BluetoothService.onRowPrimary(modelData)

                Behavior on opacity {
                    NumberAnimation { duration: ThemeModule.Theme.animDuration }
                }
            }
        }

        Text {
            visible: Services.BluetoothService.btOn && Services.BluetoothService.connectedRows.length === 0 && Services.BluetoothService.knownRows.length === 0 && Services.BluetoothService.discoveredRows.length === 0
            text: "No devices found. Run a scan."
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.overlay
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // ── Scan button with countdown ──────────
        Rectangle {
            visible: Services.BluetoothService.btOn
            width: parent.width
            height: 32
            radius: ThemeModule.Theme.borderRadiusSmall
            color: scanMouse.containsMouse && scanMouse.enabled ? ThemeModule.Theme.cardHover : ThemeModule.Theme.card
            border.width: 1
            border.color: Qt.rgba(ThemeModule.Theme.blue.r, ThemeModule.Theme.blue.g, ThemeModule.Theme.blue.b, 0.3)
            opacity: (Services.BluetoothService.btOn && !Services.BluetoothService.scanning) ? 1.0 : (Services.BluetoothService.scanning ? 0.8 : 0.5)

            Behavior on opacity {
                NumberAnimation { duration: ThemeModule.Theme.animDuration }
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: {
                        if (!Services.BluetoothService.scanning)
                            return "🔍 Scan for devices";
                        var remaining = Services.BluetoothService.scanTimeout - Services.BluetoothService.scanElapsed;
                        if (remaining < 0) remaining = 0;
                        return "⏳ Scanning... (" + remaining + "s)";
                    }
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: Services.BluetoothService.btOn ? ThemeModule.Theme.blue : ThemeModule.Theme.overlay
                }

                // Progress bar for scan
                Rectangle {
                    visible: Services.BluetoothService.scanning
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 100
                    height: 3
                    radius: 1.5
                    color: Qt.rgba(ThemeModule.Theme.blue.r, ThemeModule.Theme.blue.g, ThemeModule.Theme.blue.b, 0.2)

                    Rectangle {
                        width: Services.BluetoothService.scanTimeout > 0
                            ? (Services.BluetoothService.scanElapsed / Services.BluetoothService.scanTimeout) * parent.width
                            : 0
                        height: parent.height
                        radius: 1.5
                        color: ThemeModule.Theme.blue

                        Behavior on width {
                            NumberAnimation { duration: 900 }
                        }
                    }
                }
            }

            MouseArea {
                id: scanMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: Services.BluetoothService.btOn && !Services.BluetoothService.scanning
                onClicked: Services.BluetoothService.startScan()
            }
        }
    }
}
