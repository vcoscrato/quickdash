pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../theme" as ThemeModule
import "../components" as Components
import "../services" as Services
import "../widgets" as Widgets

Rectangle {
    id: dashboard
    color: ThemeModule.Theme.bg

    property var config: null
    property bool dashboardVisible: true
    property bool dashboardActive: true
    
    property string activePanel: ""

    // ── Default config values ──
    readonly property var defaultTopAnchor: ["clock"]
    readonly property var defaultBottomAnchor: ["systemTray", "calendar"]
    readonly property var defaultMiddle: ["notificationCenter", "batteryStatus"]
    readonly property var defaultSidebar: [
        { "widget": "networkPanel",    "icon": "📶" },
        { "widget": "bluetoothPanel",  "icon": "🔵" },
        { "widget": "audioControl",    "icon": "🔊" },
        { "widget": "audioInputControl", "icon": "🎤" },
        { "widget": "brightnessControl", "icon": "☀" },
        { "widget": "displayControl",  "icon": "🖥" },
        { "widget": "keyboardLayout",  "icon": "⌨" }
    ]

    property var topAnchorWidgets: config && config.topAnchor ? config.topAnchor : defaultTopAnchor
    property var bottomAnchorWidgets: config && config.bottomAnchor ? config.bottomAnchor : defaultBottomAnchor
    property var middleDefaultWidgets: config && config.middleDefault ? config.middleDefault : defaultMiddle
    property var sidebarItems: config && config.sidebar ? config.sidebar : defaultSidebar

    function widgetSource(name) {
        var map = {
            "dailyFocus":         "../widgets/DailyFocus.qml",
            "weatherStrip":       "../widgets/WeatherStrip.qml",
            "countdowns":         "../widgets/Countdowns.qml",
            "randomQuote":        "../widgets/RandomQuote.qml",
            "configPanel":        "../widgets/ConfigPanel.qml",
            "capturePad":         "../widgets/CapturePad.qml",
            "quickCommands":      "../widgets/QuickCommands.qml",
            "systemMonitor":      "../widgets/SystemMonitor.qml",
            "powerMenu":          "../widgets/PowerMenu.qml",
            "clock":              "../widgets/Clock.qml",
            "nowPlaying":         "../widgets/NowPlaying.qml",
            "audioControl":       "../widgets/AudioControl.qml",
            "audioInputControl":  "../widgets/AudioInputControl.qml",
            "brightnessControl":  "../widgets/BrightnessControl.qml",
            "displayControl":     "../widgets/DisplayControl.qml",
            "networkPanel":       "../widgets/NetworkPanel.qml",
            "bluetoothPanel":     "../widgets/BluetoothPanel.qml",
            "notificationCenter": "../widgets/NotificationCenter.qml",
            "keyboardLayout":     "../widgets/KeyboardLayout.qml",
            "calendar":           "../widgets/Calendar.qml",
            "batteryStatus":      "../widgets/BatteryStatus.qml",
            "systemTray":         "../widgets/SystemTray.qml"
        };
        return map[name] || "";
    }

    function isWidgetSupported(name) {
        if (name === "batteryStatus") return Services.FeatureSupport.supportsBattery;
        if (name === "brightnessControl") return Services.FeatureSupport.supportsBrightness;
        if (name === "bluetoothPanel") return Services.FeatureSupport.supportsBluetooth;
        if (name === "displayControl") return Services.FeatureSupport.supportsDisplayControl;
        if (name === "keyboardLayout") {
            return Services.FeatureSupport.supportsHyprland
                && dashboard.config
                && dashboard.config.keyboardLayouts
                && dashboard.config.keyboardLayouts.length > 1;
        }
        return true;
    }

    function getMicroStatus(widget) {
        if (widget === "audioControl") return Services.AudioService.outputVolumePercent;
        if (widget === "audioInputControl") return Services.AudioService.inputVolumePercent;
        if (widget === "networkPanel") return Services.NetworkService.currentConnectedWifi ? "●" : "";
        if (widget === "bluetoothPanel") {
            var n = Services.BluetoothService.connectedRows.length;
            return n > 0 ? n.toString() : "";
        }
        return "";
    }

    function getStatusText(widget) {
        if (widget === "audioControl") return "Volume: " + Services.AudioService.outputVolumePercent + "%";
        if (widget === "audioInputControl") return "Mic: " + Services.AudioService.inputVolumePercent + "%";
        if (widget === "networkPanel") {
            if (Services.NetworkService.currentConnectedWifi) return "WiFi: " + Services.NetworkService.currentConnectedWifi.ssid;
            return "WiFi off / Disconnected";
        }
        if (widget === "bluetoothPanel") return Services.BluetoothService.btOn ? "Bluetooth On" : "Bluetooth Off";
        return "";
    }

    Row {
        anchors.fill: parent
        anchors.margins: ThemeModule.Theme.spacingMedium

        // ── Sidebar Rail ──
        Item {
            width: ThemeModule.Theme.sidebarWidth
            height: parent.height

            Column {
                anchors.top: parent.top
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Repeater {
                    model: dashboard.sidebarItems.filter(function(i) {
                        var wName = typeof i === "string" ? i : i.widget;
                        return wName !== "configPanel"
                            && wName !== "powerMenu"
                            && dashboard.isWidgetSupported(wName);
                    })
                    delegate: Components.SidebarIcon {
                        required property var modelData
                        property string wName: typeof modelData === "string" ? modelData : modelData.widget
                        property string wIcon: typeof modelData === "string" ? "❓" : modelData.icon

                        widgetName: wName
                        iconText: wIcon
                        active: dashboard.activePanel === wName
                        microStatus: dashboard.getMicroStatus(wName)
                        statusText: dashboard.getStatusText(wName)

                        onActivated: function(name) {
                            if (dashboard.activePanel === name) {
                                dashboard.activePanel = "";
                            } else {
                                dashboard.activePanel = name;
                            }
                        }

                        onWheelDelta: function(delta) {
                            if (wName === "audioControl") {
                                var step = 5;
                                var newVol = Services.AudioService.outputVolumePercent + (delta > 0 ? step : -step);
                                Services.AudioService.setOutputVolumePercent(Math.max(0, Math.min(100, newVol)));
                            } else if (wName === "audioInputControl") {
                                var stepIn = 5;
                                var newVolIn = Services.AudioService.inputVolumePercent + (delta > 0 ? stepIn : -stepIn);
                                Services.AudioService.setInputVolumePercent(Math.max(0, Math.min(100, newVolIn)));
                            }
                        }
                    }
                }
            }

            Column {
                anchors.bottom: parent.bottom
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Repeater {
                    model: dashboard.sidebarItems.filter(function(i) {
                        var wName = typeof i === "string" ? i : i.widget;
                        return (wName === "configPanel" || wName === "powerMenu")
                            && dashboard.isWidgetSupported(wName);
                    })
                    delegate: Components.SidebarIcon {
                        required property var modelData
                        property string wName: typeof modelData === "string" ? modelData : modelData.widget
                        property string wIcon: typeof modelData === "string" ? "❓" : modelData.icon

                        widgetName: wName
                        iconText: wIcon
                        active: dashboard.activePanel === wName
                        microStatus: dashboard.getMicroStatus(wName)
                        statusText: dashboard.getStatusText(wName)

                        onActivated: function(name) {
                            if (dashboard.activePanel === name) {
                                dashboard.activePanel = "";
                            } else {
                                dashboard.activePanel = name;
                            }
                        }
                    }
                }
            }
        }

        // ── Separator ──
        Rectangle {
            width: ThemeModule.Theme.separatorThickness
            height: parent.height
            color: ThemeModule.Theme.separator
            anchors.margins: ThemeModule.Theme.spacingSmall
        }

        Item { width: ThemeModule.Theme.spacingSmall; height: 1 }

        // ── Content Column ──
        Column {
            width: parent.width - ThemeModule.Theme.sidebarWidth - ThemeModule.Theme.separatorThickness - ThemeModule.Theme.spacingSmall
            height: parent.height

            // Top Anchor
            Column {
                id: topAnchorColumn
                width: parent.width
                spacing: ThemeModule.Theme.spacingMedium
                Repeater {
                    model: dashboard.topAnchorWidgets
                    delegate: Loader {
                        required property string modelData
                        width: parent.width
                        active: dashboard.widgetSource(modelData) !== "" && dashboard.isWidgetSupported(modelData)
                        source: dashboard.widgetSource(modelData)
                        onLoaded: {
                            if (item && "dashboardActive" in item) {
                                item.dashboardActive = Qt.binding(function() { return dashboard.dashboardActive; });
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: ThemeModule.Theme.spacingMedium }

            // Mini Player (auto-appears if player is active)
            Widgets.MiniPlayer {
                id: miniPlayer
                dashboardActive: dashboard.dashboardActive
                onClicked: {
                    if (dashboard.activePanel === "nowPlaying") dashboard.activePanel = "";
                    else dashboard.activePanel = "nowPlaying";
                }
            }

            Item { width: 1; height: miniPlayer.hasPlayer ? ThemeModule.Theme.spacingMedium : 0; Behavior on height { NumberAnimation { duration: ThemeModule.Theme.animDuration } } }

            // ── Scrollable Middle Zone ──
            Flickable {
                id: middleFlickable
                width: parent.width
                height: parent.height - topAnchorColumn.height - (miniPlayer.hasPlayer ? miniPlayer.height + ThemeModule.Theme.spacingMedium : 0) - bottomAnchorColumn.height - ThemeModule.Theme.spacingMedium * 3
                contentHeight: middleContentColumn.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 3000

                ScrollBar.vertical: ScrollBar {
                    policy: middleFlickable.contentHeight > middleFlickable.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                    contentItem: Rectangle {
                        implicitWidth: 4
                        radius: 2
                        color: ThemeModule.Theme.overlay
                        opacity: 0.5
                    }
                }

                Item {
                    id: middleContentColumn
                    width: middleFlickable.width
                    height: Math.max(defaultMiddleColumn.height, activePanelLoaderContainer.height)

                    // Default content
                    Column {
                        id: defaultMiddleColumn
                        width: parent.width
                        spacing: ThemeModule.Theme.spacingMedium
                        opacity: dashboard.activePanel === "" ? 1.0 : 0.0
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }

                        Repeater {
                            model: dashboard.middleDefaultWidgets
                            delegate: Loader {
                                required property string modelData
                                width: parent.width
                                active: dashboard.widgetSource(modelData) !== "" && dashboard.isWidgetSupported(modelData)
                                source: dashboard.widgetSource(modelData)
                                onLoaded: {
                                    if (item && "dashboardActive" in item) {
                                        item.dashboardActive = Qt.binding(function() { return dashboard.dashboardActive && dashboard.activePanel === ""; });
                                    }
                                }
                            }
                        }
                    }

                    // Active Panel Container
                    Item {
                        id: activePanelLoaderContainer
                        width: parent.width
                        height: activePanelLoader.height
                        
                        // Slide-in animation
                        x: dashboard.activePanel !== "" ? 0 : -20
                        opacity: dashboard.activePanel !== "" ? 1.0 : 0.0
                        visible: opacity > 0
                        
                        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        Loader {
                            id: activePanelLoader
                            width: parent.width
                            active: dashboard.activePanel !== "" && dashboard.isWidgetSupported(dashboard.activePanel)
                            source: dashboard.activePanel !== "" && dashboard.isWidgetSupported(dashboard.activePanel)
                                ? dashboard.widgetSource(dashboard.activePanel)
                                : ""
                            
                            onLoaded: {
                                if (!item) return;
                                
                                if ("dashboardActive" in item) {
                                    item.dashboardActive = Qt.binding(function() { return dashboard.dashboardActive && dashboard.activePanel !== ""; });
                                }
                                if ("collapsible" in item) {
                                    item.collapsible = false;
                                    item.collapsed = false;
                                }
                                
                                
                                // Quick switch arrays for audio
                                if (dashboard.activePanel === "audioControl") item.quickSwitchDevices = dashboard.config.audioQuickSwitch || [];
                                if (dashboard.activePanel === "audioInputControl") item.quickSwitchDevices = dashboard.config.audioInputQuickSwitch || [];
                                if (dashboard.activePanel === "keyboardLayout") item.keyboardLayouts = dashboard.config.keyboardLayouts || ["us"];
                            }
                        }
                    }
                }
            }

            Item { width: 1; height: ThemeModule.Theme.spacingMedium }

            // Bottom Anchor
            Column {
                id: bottomAnchorColumn
                width: parent.width
                spacing: ThemeModule.Theme.spacingMedium
                Repeater {
                    model: dashboard.bottomAnchorWidgets
                    delegate: Loader {
                        required property string modelData
                        width: parent.width
                        active: dashboard.widgetSource(modelData) !== "" && dashboard.isWidgetSupported(modelData)
                        source: dashboard.widgetSource(modelData)
                        onLoaded: {
                            if (item && "dashboardActive" in item) {
                                item.dashboardActive = Qt.binding(function() { return dashboard.dashboardActive; });
                            }
                        }
                    }
                }
            }
        }
    }
}
