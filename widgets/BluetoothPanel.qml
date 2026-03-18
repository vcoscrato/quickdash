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
                subtitle: ""
                leadingIcon: modelData.icon
                badges: []
                onPrimaryTriggered: Services.BluetoothService.onRowPrimary(modelData)
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
                subtitle: ""
                leadingIcon: modelData.icon
                badges: []
                onPrimaryTriggered: Services.BluetoothService.onRowPrimary(modelData)
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
                subtitle: ""
                leadingIcon: modelData.icon
                badges: []
                onPrimaryTriggered: Services.BluetoothService.onRowPrimary(modelData)
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

        Rectangle {
            visible: Services.BluetoothService.btOn
            width: parent.width
            height: 32
            radius: ThemeModule.Theme.borderRadiusSmall
            color: scanMouse.containsMouse ? ThemeModule.Theme.cardHover : ThemeModule.Theme.card
            border.width: 1
            border.color: Qt.rgba(ThemeModule.Theme.blue.r, ThemeModule.Theme.blue.g, ThemeModule.Theme.blue.b, 0.3)

            Text {
                anchors.centerIn: parent
                text: Services.BluetoothService.scanning ? "⏳ Scanning..." : "🔍 Scan for devices"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: Services.BluetoothService.btOn ? ThemeModule.Theme.blue : ThemeModule.Theme.overlay
            }

            MouseArea {
                id: scanMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: Services.BluetoothService.btOn && !Services.BluetoothService.scanning
                onClicked: Services.BluetoothService.startScan()
            }
        }
    }
}
