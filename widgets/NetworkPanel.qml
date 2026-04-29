import QtQuick
import Quickshell.Io
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Network"
    icon: "📶"
    collapsible: true
    property bool dashboardActive: true


    onDashboardActiveChanged: {
        if (root.dashboardActive) {
            Services.NetworkService.refreshAll(true);
        }
    }

    onCollapsedChanged: {
        if (!root.collapsed && root.dashboardActive)
            Services.NetworkService.refreshAll(true);
    }

    Connections {
        target: Services.NetworkService
        function onNetworkModeChanged() {
            if (root.dashboardActive)
                Services.NetworkService.refreshAll(!root.collapsed);
        }
    }

    pinnedContent: [
        Text {
            visible: Services.NetworkService.statusMessage !== ""
            width: parent.width
            wrapMode: Text.WordWrap
            text: Services.NetworkService.statusMessage
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.warning
        },

        // Ethernet Section
        Components.DeviceRow {
            visible: Services.NetworkService.statusMessage === "" && Services.NetworkService.wiredConnected
            width: parent.width
            title: Services.NetworkService.wiredConnectionName || "Ethernet"
            subtitle: Services.NetworkService.wiredIp || "Connected"
            leadingIcon: "🔌"
            primaryEnabled: false
        },

        // Wi-Fi Header / Controls
        Item {
            width: parent.width
            height: 36

            Text {
                id: wifiLabel
                text: "Wi-Fi"
                font.pixelSize: ThemeModule.Theme.fontSizeNormal
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
                color: ThemeModule.Theme.text
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                id: wifiControls
                spacing: ThemeModule.Theme.spacingSmall
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right

                Components.ScanButton {
                    visible: Services.NetworkService.statusMessage === "" && Services.NetworkService.wifiOn
                    scanning: Services.NetworkService.scanning
                    text: "Scanning..."
                    onClicked: Services.NetworkService.startScan()
                }

                Components.TogglePill {
                    visible: Services.NetworkService.statusMessage === ""
                    height: 32
                    label: Services.NetworkService.wifiOn ? "On" : "Off"
                    checked: Services.NetworkService.wifiOn
                    activeColor: ThemeModule.Theme.sky
                    onToggled: function(state) {
                        Services.NetworkService.setWifiEnabled(state)
                    }
                }
            }
        },

        // ── Connected WiFi row ──────────────────
        Components.DeviceRow {
            visible: Services.NetworkService.statusMessage === "" && Services.NetworkService.currentConnectedWifi !== null
            width: parent.width
            title: Services.NetworkService.currentConnectedWifi ? Services.NetworkService.currentConnectedWifi.ssid : ""
            subtitle: Services.NetworkService.connectedWifiSubtitle(Services.NetworkService.currentConnectedWifi)
            signalLevel: Services.NetworkService.currentConnectedWifi ? Services.NetworkService.currentConnectedWifi.signal : -1
            showLock: Services.NetworkService.currentConnectedWifi ? Services.NetworkService.currentConnectedWifi.secure : false
            leadingIcon: ""
            primaryEnabled: false
            badges: [{ text: "Connected", tone: "success" }]
            actionChips: Services.NetworkService.currentConnectedWifi ? [
                Services.NetworkService.autoconnectChipForRow(Services.NetworkService.currentConnectedWifi),
                { text: "Disconnect", tone: "error", actionId: "disconnect" }
            ] : []
            onActionTriggered: function(actionId) {
                if (!Services.NetworkService.currentConnectedWifi) return;
                if (actionId === "autoconnect") Services.NetworkService.onToggleAutoconnect(Services.NetworkService.currentConnectedWifi);
                if (actionId === "disconnect") Services.NetworkService.requestDisconnectWifi(Services.NetworkService.currentConnectedWifi);
            }
        },

        // ── Connecting indicator ────────────────
        Item {
            visible: Services.NetworkService.statusMessage === "" && Services.NetworkService.connecting
                && Services.NetworkService.currentConnectedWifi === null
            width: parent.width
            height: 36

            Row {
                anchors.centerIn: parent
                spacing: ThemeModule.Theme.spacingSmall

                Text {
                    text: "⟳"
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    color: ThemeModule.Theme.sky
                    anchors.verticalCenter: parent.verticalCenter

                    RotationAnimator on rotation {
                        from: 0
                        to: 360
                        duration: 1200
                        loops: Animation.Infinite
                        running: Services.NetworkService.connecting
                    }
                }

                Text {
                    text: "Connecting to " + Services.NetworkService.connectingSsid + "..."
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.sky
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    ]

    content: [
        Column {
            visible: Services.NetworkService.statusMessage === "" && Services.NetworkService.wifiOn
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Components.DeviceSection {
            visible: Services.NetworkService.otherWifiRows.length > 0
            width: parent.width
            title: "Nearby Networks"
            count: Services.NetworkService.otherWifiRows.length
        }

        Repeater {
            model: Services.NetworkService.otherWifiRows
            delegate: Components.DeviceRow {
                width: parent.width
                title: modelData.ssid
                subtitle: {
                    if (Services.NetworkService.connecting && Services.NetworkService.connectingSsid === modelData.ssid)
                        return "Connecting...";
                    return modelData.signal + "%";
                }
                signalLevel: modelData.signal
                showLock: modelData.secure
                leadingIcon: ""
                badges: modelData.known ? [{ text: "Known", tone: "neutral" }] : []
                expanded: Services.NetworkService.passwordRowSsid === modelData.ssid
                primaryEnabled: !Services.NetworkService.connecting
                opacity: Services.NetworkService.connecting && Services.NetworkService.connectingSsid !== modelData.ssid ? 0.5 : 1.0
                actionChips: [
                    Services.NetworkService.autoconnectChipForRow(modelData),
                    {
                        text: Services.NetworkService.forgetArmedSsid === modelData.ssid ? "Confirm" : "Forget",
                        tone: Services.NetworkService.forgetArmedSsid === modelData.ssid ? "error" : "warning",
                        armed: Services.NetworkService.forgetArmedSsid === modelData.ssid,
                        actionId: "forget"
                    }
                ]

                onPrimaryTriggered: Services.NetworkService.onRowPrimary(modelData)
                onActionTriggered: function(actionId) {
                    if (actionId === "autoconnect") Services.NetworkService.onToggleAutoconnect(modelData);
                    if (actionId === "forget") Services.NetworkService.onForgetClicked(modelData.ssid);
                }

                Rectangle {
                    visible: Services.NetworkService.passwordRowSsid === modelData.ssid
                    width: parent.width
                    height: 32
                    radius: ThemeModule.Theme.borderRadiusSmall
                    color: ThemeModule.Theme.card
                    border.width: ThemeModule.Theme.borderWidth
                    border.color: Qt.rgba(ThemeModule.Theme.sky.r, ThemeModule.Theme.sky.g, ThemeModule.Theme.sky.b, 0.5)

                    TextInput {
                        id: passwordInput
                        anchors.fill: parent
                        anchors.margins: ThemeModule.Theme.spacingSmall
                        text: Services.NetworkService.passwordText
                        echoMode: TextInput.Password
                        color: ThemeModule.Theme.text
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        onTextChanged: Services.NetworkService.passwordText = text
                        onAccepted: Services.NetworkService.requestConnect(modelData, Services.NetworkService.passwordText)
                        Keys.onReturnPressed: Services.NetworkService.requestConnect(modelData, Services.NetworkService.passwordText)
                        Keys.onEnterPressed: Services.NetworkService.requestConnect(modelData, Services.NetworkService.passwordText)

                        Component.onCompleted: {
                            if (Services.NetworkService.passwordRowSsid === modelData.ssid)
                                passwordInput.forceActiveFocus();
                        }
                    }

                    onVisibleChanged: {
                        if (visible)
                            passwordInput.forceActiveFocus();
                    }
                }

                Row {
                    visible: Services.NetworkService.passwordRowSsid === modelData.ssid
                    spacing: ThemeModule.Theme.spacingSmall

                    Components.InlineActionChip {
                        text: "Connect"
                        tone: "success"
                        onActivated: Services.NetworkService.requestConnect(modelData, Services.NetworkService.passwordText)
                    }

                    Components.InlineActionChip {
                        text: "Cancel"
                        tone: "neutral"
                        onActivated: Services.NetworkService.cancelPasswordPrompt()
                    }
                }

                Text {
                    visible: Services.NetworkService.passwordRowSsid === modelData.ssid && Services.NetworkService.connectErrorSsid === modelData.ssid
                    text: Services.NetworkService.connectError
                    font.pixelSize: 10
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.error
                }

                Behavior on opacity {
                    NumberAnimation { duration: ThemeModule.Theme.animDuration }
                }
            }
        }

        Text {
            visible: Services.NetworkService.otherWifiRows.length === 0 && Services.NetworkService.wifiOn && !Services.NetworkService.scanning
            text: "No networks found"
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.overlay
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
    ]
}
