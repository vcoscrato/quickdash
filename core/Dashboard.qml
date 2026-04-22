pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
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
    readonly property bool sidebarShowSystemTray: config ? (config.sidebarSystemTray !== undefined ? config.sidebarSystemTray : true) : true

    onActivePanelChanged: {
        middleFlickable.contentY = 0;
        scrollResetTimer.restart();
    }

    Timer {
        id: scrollResetTimer
        interval: ThemeModule.Theme.animDuration + 50
        repeat: false
        onTriggered: middleFlickable.contentY = 0
    }

    // ── Default config values ──
    readonly property var defaultTopAnchor: ["clock"]
    readonly property var defaultBottomAnchor: ["systemTray", "calendar"]
    readonly property var defaultMiddle: ["notificationCenter", "batteryStatus"]
    readonly property var defaultSidebar: [
        { "widget": "capturePad",      "icon": "🗂" },
        { "widget": "quickCommands",   "icon": "🚀" },
        { "widget": "networkPanel",    "icon": "📶" },
        { "widget": "bluetoothPanel",  "icon": "🔵" },
        { "widget": "audioControl",    "icon": "🔊" },
        { "widget": "audioInputControl", "icon": "🎤" },
        { "widget": "brightnessControl", "icon": "☀" },
        { "widget": "displayControl",  "icon": "🖥" },
        { "widget": "keyboardLayout",  "icon": "⌨" },
        { "widget": "systemMonitor",   "icon": "📊" },
        { "widget": "configPanel",     "icon": "⚙" },
        { "widget": "powerMenu",       "icon": "⏻" }
    ]

    function filterSidebarSystemTrayWidgets(list) {
        if (!dashboard.sidebarShowSystemTray || !list || !Array.isArray(list)) {
            return list;
        }

        var filtered = [];
        for (var i = 0; i < list.length; i++) {
            var item = list[i];

            if (typeof item === "string") {
                if (item !== "systemTray") {
                    filtered.push(item);
                }
                continue;
            }

            if (item && typeof item === "object" && item.group === true && Array.isArray(item.items)) {
                var groupItems = [];
                for (var j = 0; j < item.items.length; j++) {
                    if (item.items[j] !== "systemTray") {
                        groupItems.push(item.items[j]);
                    }
                }

                if (groupItems.length === 1) {
                    filtered.push(groupItems[0]);
                } else if (groupItems.length > 1) {
                    filtered.push({ group: true, items: groupItems });
                }
                continue;
            }

            filtered.push(item);
        }

        return filtered;
    }

    property var topAnchorWidgets: filterSidebarSystemTrayWidgets(config && config.topAnchor ? config.topAnchor : defaultTopAnchor)
    property var bottomAnchorWidgets: filterSidebarSystemTrayWidgets(config && config.bottomAnchor ? config.bottomAnchor : defaultBottomAnchor)
    property var middleDefaultWidgets: filterSidebarSystemTrayWidgets(config && config.middleDefault ? config.middleDefault : defaultMiddle)
    property var sidebarItems: config && config.sidebar ? config.sidebar : defaultSidebar

    function widgetSource(name) {
        var map = {
            "todoList":           "../widgets/TodoList.qml",
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
        if (widget === "audioControl") return Services.AudioService.outputVolumePercent + "%";
        if (widget === "audioInputControl") return Services.AudioService.inputVolumePercent + "%";
        if (widget === "networkPanel") return "";
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

    Item {
        anchors.fill: parent

        // ── Sidebar Rail ──
        Item {
            id: sidebarRail
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: ThemeModule.Theme.sidebarWidth

            Column {
                id: sidebarTopCol
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
                id: sidebarBottomCol
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

            // ── System Tray (centered in the free zone between top and bottom icons) ──
            Item {
                id: sidebarTrayZone
                anchors.top: sidebarTopCol.bottom
                anchors.bottom: sidebarBottomCol.top
                anchors.left: parent.left
                anchors.right: parent.right
                visible: dashboard.sidebarShowSystemTray && sidebarTrayRepeater.count > 0

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: ThemeModule.Theme.spacingTiny

                    Repeater {
                        id: sidebarTrayRepeater
                        model: SystemTray.items
                        delegate: Item {
                            id: sidebarTrayDelegate
                            required property var modelData
                            width: ThemeModule.Theme.sidebarIconSize
                            height: ThemeModule.Theme.sidebarIconSize

                            Rectangle {
                                id: trayIconRect
                                anchors.fill: parent
                                color: sidebarTrayMouse.containsMouse ? ThemeModule.Theme.cardHover : "transparent"

                                Image {
                                    id: sidebarTrayImg
                                    anchors.centerIn: parent
                                    width: 18
                                    height: 18
                                    property string iconPath: {
                                        var icon = sidebarTrayDelegate.modelData.icon;
                                        if (!icon) return "";
                                        var s = icon.toString();
                                        var pi = s.indexOf("?path=");
                                        return pi !== -1 ? s.substring(0, pi) : s;
                                    }
                                    visible: iconPath !== ""
                                    source: iconPath
                                    sourceSize: Qt.size(18, 18)
                                    fillMode: Image.PreserveAspectFit
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: "●"
                                    font.pixelSize: 10
                                    color: ThemeModule.Theme.subtext
                                    visible: !sidebarTrayImg.visible
                                }

                                ToolTip {
                                    visible: sidebarTrayMouse.containsMouse
                                    text: sidebarTrayDelegate.modelData.tooltipTitle || sidebarTrayDelegate.modelData.title || sidebarTrayDelegate.modelData.id || ""
                                    delay: 150
                                }

                                QsMenuAnchor {
                                    id: sidebarTrayMenu
                                    menu: sidebarTrayDelegate.modelData.menu
                                    anchor.item: trayIconRect
                                    anchor.edges: Edges.Right
                                    anchor.gravity: Edges.Right
                                }

                                MouseArea {
                                    id: sidebarTrayMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: function(mouse) {
                                        if (mouse.button === Qt.LeftButton) {
                                            if (sidebarTrayDelegate.modelData.onlyMenu && sidebarTrayDelegate.modelData.hasMenu) {
                                                sidebarTrayMenu.open();
                                            } else {
                                                sidebarTrayDelegate.modelData.activate();
                                            }
                                        } else if (mouse.button === Qt.RightButton) {
                                            if (sidebarTrayDelegate.modelData.hasMenu) {
                                                sidebarTrayMenu.open();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ── Separator ──
        Rectangle {
            id: mainSeparator
            anchors.left: sidebarRail.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: ThemeModule.Theme.separatorThickness
            color: ThemeModule.Theme.separator
        }

        // ── Content Area ──
        Item {
            id: contentArea
            anchors.left: mainSeparator.right
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.topMargin: ThemeModule.Theme.spacingMedium
            anchors.rightMargin: ThemeModule.Theme.spacingMedium
            anchors.leftMargin: ThemeModule.Theme.spacingMedium
            anchors.bottomMargin: ThemeModule.Theme.spacingMedium

            // Top block: topAnchor + spacer + miniPlayer
            Column {
                id: topBlock
                anchors.top: parent.top
                width: parent.width
                spacing: 0

                // Top Anchor
                Column {
                    id: topAnchorColumn
                    width: parent.width
                    spacing: ThemeModule.Theme.spacingXL
                    Repeater {
                        model: dashboard.topAnchorWidgets
                        delegate: Item {
                            id: topAnchorSlot
                            required property var modelData
                            readonly property bool isGroup: typeof topAnchorSlot.modelData === "object" && topAnchorSlot.modelData !== null && topAnchorSlot.modelData.group === true
                            width: parent.width
                            height: topAnchorSlot.isGroup ? topGroupRow.implicitHeight : topSingleLoader.height

                            Loader {
                                id: topSingleLoader
                                width: parent.width
                                visible: !topAnchorSlot.isGroup
                                active: !topAnchorSlot.isGroup
                                    && dashboard.widgetSource(topAnchorSlot.modelData) !== ""
                                    && dashboard.isWidgetSupported(topAnchorSlot.modelData)
                                source: active ? dashboard.widgetSource(topAnchorSlot.modelData) : ""
                                onLoaded: {
                                    if (item && "dashboardActive" in item) {
                                        item.dashboardActive = Qt.binding(function() { return dashboard.dashboardActive; });
                                    }
                                }
                            }

                            Row {
                                id: topGroupRow
                                width: parent.width
                                visible: topAnchorSlot.isGroup
                                spacing: ThemeModule.Theme.spacingSmall
                                property int groupCount: topAnchorSlot.isGroup ? topAnchorSlot.modelData.items.length : 1
                                Repeater {
                                    model: topAnchorSlot.isGroup ? topAnchorSlot.modelData.items : []
                                    delegate: Loader {
                                        required property var modelData
                                        width: (parent.width - ThemeModule.Theme.spacingSmall * (parent.groupCount - 1)) / parent.groupCount
                                        active: dashboard.widgetSource(modelData) !== "" && dashboard.isWidgetSupported(modelData)
                                        source: active ? dashboard.widgetSource(modelData) : ""
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

                Item { width: 1; height: ThemeModule.Theme.spacingXL }

                // Mini Player (auto-appears if player is active)
                Widgets.MiniPlayer {
                    id: miniPlayer
                    width: parent.width
                    dashboardActive: dashboard.dashboardActive
                    onClicked: {
                        if (dashboard.activePanel === "nowPlaying") dashboard.activePanel = "";
                        else dashboard.activePanel = "nowPlaying";
                    }
                }

                Item {
                    width: 1
                    height: miniPlayer.hasPlayer ? ThemeModule.Theme.spacingXL : 0
                    Behavior on height { NumberAnimation { duration: ThemeModule.Theme.animDuration } }
                }
            }

            // Bottom block: spacer + bottomAnchor
            Column {
                id: bottomBlock
                anchors.bottom: parent.bottom
                width: parent.width
                spacing: 0

                Item { width: 1; height: ThemeModule.Theme.spacingXL }

                Column {
                    id: bottomAnchorColumn
                    width: parent.width
                    spacing: ThemeModule.Theme.spacingXL
                    Repeater {
                        model: dashboard.bottomAnchorWidgets
                        delegate: Item {
                            id: bottomAnchorSlot
                            required property var modelData
                            readonly property bool isGroup: typeof bottomAnchorSlot.modelData === "object" && bottomAnchorSlot.modelData !== null && bottomAnchorSlot.modelData.group === true
                            width: parent.width
                            height: bottomAnchorSlot.isGroup ? bottomGroupRow.implicitHeight : bottomSingleLoader.height

                            Loader {
                                id: bottomSingleLoader
                                width: parent.width
                                visible: !bottomAnchorSlot.isGroup
                                active: !bottomAnchorSlot.isGroup
                                    && dashboard.widgetSource(bottomAnchorSlot.modelData) !== ""
                                    && dashboard.isWidgetSupported(bottomAnchorSlot.modelData)
                                source: active ? dashboard.widgetSource(bottomAnchorSlot.modelData) : ""
                                onLoaded: {
                                    if (item && "dashboardActive" in item) {
                                        item.dashboardActive = Qt.binding(function() { return dashboard.dashboardActive; });
                                    }
                                }
                            }

                            Row {
                                id: bottomGroupRow
                                width: parent.width
                                visible: bottomAnchorSlot.isGroup
                                spacing: ThemeModule.Theme.spacingSmall
                                property int groupCount: bottomAnchorSlot.isGroup ? bottomAnchorSlot.modelData.items.length : 1
                                Repeater {
                                    model: bottomAnchorSlot.isGroup ? bottomAnchorSlot.modelData.items : []
                                    delegate: Loader {
                                        required property var modelData
                                        width: (parent.width - ThemeModule.Theme.spacingSmall * (parent.groupCount - 1)) / parent.groupCount
                                        active: dashboard.widgetSource(modelData) !== "" && dashboard.isWidgetSupported(modelData)
                                        source: active ? dashboard.widgetSource(modelData) : ""
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
            }

            // ── Scrollable Middle Zone ── (anchored between topBlock and bottomBlock)
            Flickable {
                id: middleFlickable
                anchors.top: topBlock.bottom
                anchors.bottom: bottomBlock.top
                width: parent.width
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
                    height: dashboard.activePanel !== ""
                        ? activePanelLoaderContainer.height
                        : defaultMiddleColumn.height

                    // Default content
                    Column {
                        id: defaultMiddleColumn
                        width: parent.width
                        spacing: ThemeModule.Theme.spacingXL
                        opacity: dashboard.activePanel === "" ? 1.0 : 0.0
                        visible: opacity > 0

                        Behavior on opacity {
                            NumberAnimation { duration: 150 }
                        }

                        Repeater {
                            model: dashboard.middleDefaultWidgets
                            delegate: Item {
                                id: middleSlot
                                required property var modelData
                                readonly property bool isGroup: typeof middleSlot.modelData === "object" && middleSlot.modelData !== null && middleSlot.modelData.group === true
                                width: parent.width
                                height: middleSlot.isGroup ? middleGroupRow.implicitHeight : middleSingleLoader.height

                                Loader {
                                    id: middleSingleLoader
                                    width: parent.width
                                    visible: !middleSlot.isGroup
                                    active: !middleSlot.isGroup
                                        && dashboard.widgetSource(middleSlot.modelData) !== ""
                                        && dashboard.isWidgetSupported(middleSlot.modelData)
                                    source: active ? dashboard.widgetSource(middleSlot.modelData) : ""
                                    onLoaded: {
                                        if (item && "dashboardActive" in item) {
                                            item.dashboardActive = Qt.binding(function() { return dashboard.dashboardActive && dashboard.activePanel === ""; });
                                        }
                                    }
                                }

                                Row {
                                    id: middleGroupRow
                                    width: parent.width
                                    visible: middleSlot.isGroup
                                    spacing: ThemeModule.Theme.spacingSmall
                                    property int groupCount: middleSlot.isGroup ? middleSlot.modelData.items.length : 1
                                    Repeater {
                                        model: middleSlot.isGroup ? middleSlot.modelData.items : []
                                        delegate: Loader {
                                            required property var modelData
                                            width: (parent.width - ThemeModule.Theme.spacingSmall * (parent.groupCount - 1)) / parent.groupCount
                                            active: dashboard.widgetSource(modelData) !== "" && dashboard.isWidgetSupported(modelData)
                                            source: active ? dashboard.widgetSource(modelData) : ""
                                            onLoaded: {
                                                if (item && "dashboardActive" in item) {
                                                    item.dashboardActive = Qt.binding(function() { return dashboard.dashboardActive && dashboard.activePanel === ""; });
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Active Panel Container
                    Item {
                        id: activePanelLoaderContainer
                        width: parent.width
                        height: dashboard.activePanel !== "" ? activePanelLoader.height : 0

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
        }
    }
}
