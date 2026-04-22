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
    visible: Services.FeatureSupport.supportsBluetooth
    property bool dashboardActive: true

    headerActions: Row {
        spacing: ThemeModule.Theme.spacingSmall

        Components.ScanButton {
            visible: Services.BluetoothService.btOn
            scanning: Services.BluetoothService.scanning
            text: {
                var remaining = Services.BluetoothService.scanTimeout - Services.BluetoothService.scanElapsed;
                if (remaining < 0) remaining = 0;
                return "Scanning... (" + remaining + "s)";
            }
            onClicked: Services.BluetoothService.startScan()
        }

        Components.TogglePill {
            height: 32
            label: Services.BluetoothService.btOn ? "On" : "Off"
            checked: Services.BluetoothService.btOn
            activeColor: ThemeModule.Theme.blue
            onToggled: function(state) {
                Services.BluetoothService.togglePower(state);
            }
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


    }
}
