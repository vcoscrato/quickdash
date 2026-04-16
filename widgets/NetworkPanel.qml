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

    headerActions: Row {
        spacing: ThemeModule.Theme.spacingSmall
        anchors.verticalCenter: parent.verticalCenter

        // WiFi on/off toggle — separate from the view mode slider
        Components.TogglePill {
            visible: Services.NetworkService.networkMode === 0
            iconText: "📡"
            label: "WiFi"
            checked: Services.NetworkService.wifiOn
            activeColor: ThemeModule.Theme.sky
            onToggled: function(state) {
                Services.NetworkService.setWifiEnabled(state);
            }
        }

        // View mode slider — only changes the displayed view, does NOT toggle WiFi radio
        Components.ModeSlider {
            leftLabel: "WiFi"
            rightLabel: "Ethernet"
            selectedIndex: Services.NetworkService.networkMode
            activeColor: ThemeModule.Theme.sky
            onChanged: function(index) {
                Services.NetworkService.networkMode = index;
            }
        }
    }

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
        // ── Connected WiFi row ──────────────────
        Components.DeviceRow {
            visible: Services.NetworkService.networkMode === 0 && Services.NetworkService.currentConnectedWifi !== null
            width: parent.width
            title: Services.NetworkService.currentConnectedWifi ? Services.NetworkService.currentConnectedWifi.ssid : ""
            subtitle: Services.NetworkService.connectedWifiSubtitle(Services.NetworkService.currentConnectedWifi)
            signalLevel: Services.NetworkService.currentConnectedWifi ? Services.NetworkService.currentConnectedWifi.signal : -1
            showLock: Services.NetworkService.currentConnectedWifi ? Services.NetworkService.currentConnectedWifi.secure : false
            leadingIcon: ""
            primaryEnabled: false
            badges: []
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
        Rectangle {
            visible: Services.NetworkService.networkMode === 0
                && Services.NetworkService.connecting
                && Services.NetworkService.currentConnectedWifi === null
            width: parent.width
            height: 36
            radius: ThemeModule.Theme.borderRadiusSmall
            color: Qt.rgba(ThemeModule.Theme.sky.r, ThemeModule.Theme.sky.g, ThemeModule.Theme.sky.b, 0.1)
            border.width: 1
            border.color: Qt.rgba(ThemeModule.Theme.sky.r, ThemeModule.Theme.sky.g, ThemeModule.Theme.sky.b, 0.3)

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
        },

        Text {
            visible: Services.NetworkService.networkMode === 0
                && Services.NetworkService.currentConnectedWifi === null
                && !Services.NetworkService.connecting
                && (!root.collapsed || !Services.NetworkService.wifiOn)
            text: Services.NetworkService.wifiOn ? "WiFi not connected" : "WiFi is off"
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.overlay
            anchors.horizontalCenter: parent.horizontalCenter
        },

        Rectangle {
            visible: Services.NetworkService.networkMode === 0 && root.collapsed && Services.NetworkService.wifiOn && Services.NetworkService.currentConnectedWifi === null && !Services.NetworkService.connecting
            width: parent.width
            height: 30
            radius: ThemeModule.Theme.borderRadiusSmall
            color: collapsedScanMouse.containsMouse ? ThemeModule.Theme.cardHover : ThemeModule.Theme.card
            border.width: 1
            border.color: Qt.rgba(ThemeModule.Theme.sky.r, ThemeModule.Theme.sky.g, ThemeModule.Theme.sky.b, 0.3)

            Text {
                anchors.centerIn: parent
                text: "🔍 Scan for networks"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.sky
            }

            MouseArea {
                id: collapsedScanMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.collapsed = false;
                    Services.NetworkService.startScan();
                }
            }
        },

        Item {
            visible: Services.NetworkService.networkMode === 1
            width: parent.width
            height: 0
        }
    ]

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Components.DeviceSection {
            visible: Services.NetworkService.networkMode === 0 && Services.NetworkService.knownRows.length > 0
            width: parent.width
            title: "Known"
            count: Services.NetworkService.knownRows.length
        }

        Repeater {
            model: Services.NetworkService.networkMode === 0 ? Services.NetworkService.knownRows : []
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
                badges: []
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

                Text {
                    visible: Services.NetworkService.passwordRowSsid === modelData.ssid
                    text: Services.NetworkService.connectErrorSsid === modelData.ssid ? Services.NetworkService.connectError : ""
                    font.pixelSize: 10
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.error
                }

                Behavior on opacity {
                    NumberAnimation { duration: ThemeModule.Theme.animDuration }
                }
            }
        }

        Components.DeviceSection {
            visible: Services.NetworkService.networkMode === 0 && Services.NetworkService.availableRows.length > 0
            width: parent.width
            title: "Available"
            count: Services.NetworkService.availableRows.length
        }

        Repeater {
            model: Services.NetworkService.networkMode === 0 ? Services.NetworkService.availableRows : []
            delegate: Components.DeviceRow {
                id: availableDelegate
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
                badges: []
                expanded: Services.NetworkService.passwordRowSsid === modelData.ssid
                primaryEnabled: !Services.NetworkService.connecting
                opacity: Services.NetworkService.connecting && Services.NetworkService.connectingSsid !== modelData.ssid ? 0.5 : 1.0
                onPrimaryTriggered: Services.NetworkService.onRowPrimary(modelData)

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

                        // Auto-focus when password field becomes visible
                        Component.onCompleted: {
                            if (Services.NetworkService.passwordRowSsid === modelData.ssid)
                                passwordInput.forceActiveFocus();
                        }
                    }

                    // Watch for visibility changes to auto-focus
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
            visible: Services.NetworkService.networkMode === 0 && Services.NetworkService.availableRows.length === 0 && Services.NetworkService.knownRows.length === 0 && Services.NetworkService.wifiOn
            text: "No known or scanned WiFi networks yet"
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.overlay
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // ── Scan button with proper disabled styling ──
        Rectangle {
            visible: Services.NetworkService.networkMode === 0
            width: parent.width
            height: 32
            radius: ThemeModule.Theme.borderRadiusSmall
            color: scanMouse.containsMouse && scanMouse.enabled ? ThemeModule.Theme.cardHover : ThemeModule.Theme.card
            border.width: 1
            border.color: Qt.rgba(ThemeModule.Theme.sky.r, ThemeModule.Theme.sky.g, ThemeModule.Theme.sky.b, 0.3)
            opacity: (Services.NetworkService.wifiOn && !Services.NetworkService.scanning) ? 1.0 : 0.5

            Behavior on opacity {
                NumberAnimation { duration: ThemeModule.Theme.animDuration }
            }

            Text {
                anchors.centerIn: parent
                text: Services.NetworkService.scanning ? "⏳ Scanning..." : "🔍 Scan for networks"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: Services.NetworkService.wifiOn ? ThemeModule.Theme.sky : ThemeModule.Theme.overlay
            }

            MouseArea {
                id: scanMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                enabled: Services.NetworkService.wifiOn && !Services.NetworkService.scanning
                onClicked: {
                    Services.NetworkService.startScan();
                }
            }
        }

        Rectangle {
            visible: Services.NetworkService.networkMode === 1
            width: parent.width
            radius: ThemeModule.Theme.borderRadiusSmall
            color: Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.18)
            border.width: ThemeModule.Theme.borderWidth
            border.color: Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.18)
            implicitHeight: ethernetInfoColumn.implicitHeight + ThemeModule.Theme.spacingSmall * 2

            Column {
                id: ethernetInfoColumn
                anchors.fill: parent
                anchors.margins: ThemeModule.Theme.spacingSmall
                spacing: ThemeModule.Theme.spacingTiny

                Text {
                    text: "Connection: " + (Services.NetworkService.wiredConnectionName || "None")
                    font.pixelSize: 10
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.subtext
                }

                Text {
                    text: "IP: " + (Services.NetworkService.wiredIp && Services.NetworkService.wiredIp !== "" ? Services.NetworkService.wiredIp : "N/A")
                    font.pixelSize: 10
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.subtext
                }

                Text {
                    text: "State: " + (Services.NetworkService.wiredConnected ? "Connected" : "Disconnected")
                    font.pixelSize: 10
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.subtext
                }
            }
        }
    }
}
