pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "theme" as ThemeModule

Rectangle {
    id: dashboard
    color: ThemeModule.Theme.bg

    property var config: null
    property bool dashboardVisible: true
    property bool dashboardActive: true

    // ── Default layout (single-column, backward-compatible) ──
    readonly property var defaultLayout: [
        ["clock"],
        ["notificationCenter", "keyboardLayout"],
        ["nowPlaying"],
        ["audioControl", "audioInputControl"],
        ["brightnessControl"],
        ["networkPanel"],
        ["bluetoothPanel"],
        ["calendar"],
        ["batteryStatus"],
        ["systemTray"]
    ]

    // Widget name → QML file path mapping
    // Names are camelCase versions of the filenames in widgets/
    function widgetSource(name) {
        var map = {
            "clock":              "widgets/Clock.qml",
            "nowPlaying":         "widgets/NowPlaying.qml",
            "audioControl":       "widgets/AudioControl.qml",
            "audioInputControl":  "widgets/AudioInputControl.qml",
            "brightnessControl":  "widgets/BrightnessControl.qml",
            "networkPanel":       "widgets/NetworkPanel.qml",
            "bluetoothPanel":     "widgets/BluetoothPanel.qml",
            "notificationCenter": "widgets/NotificationCenter.qml",
            "keyboardLayout":    "widgets/KeyboardLayout.qml",
            "calendar":           "widgets/Calendar.qml",
            "batteryStatus":      "widgets/BatteryStatus.qml",
            "systemTray":         "widgets/SystemTray.qml"
        };
        return map[name] || "";
    }

    function sanitizeLayout(layout) {
        var sourceLayout = layout || [];
        var clean = [];
        for (var i = 0; i < sourceLayout.length; i++) {
            var row = sourceLayout[i];
            var cleanRow = [];
            for (var j = 0; j < row.length; j++) {
                if (widgetSource(row[j]) !== "") {
                    cleanRow.push(row[j]);
                }
            }
            if (cleanRow.length > 0) {
                clean.push(cleanRow);
            }
        }
        return clean;
    }

    // Use config layout or fall back to default, skipping removed/unknown widgets.
    property var layoutRows: config ? sanitizeLayout((config.layout && config.layout.length > 0) ? config.layout : defaultLayout) : []

    Flickable {
        id: flickable
        anchors.fill: parent
        anchors.margins: ThemeModule.Theme.spacingMedium
        contentHeight: widgetColumn.height
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 3000

        ScrollBar.vertical: ScrollBar {
            policy: flickable.contentHeight > flickable.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: ThemeModule.Theme.overlay
                opacity: 0.5
            }
        }

        Column {
            id: widgetColumn
            width: flickable.width
            spacing: ThemeModule.Theme.spacingMedium

            Repeater {
                model: dashboard.layoutRows

                delegate: Row {
                    id: rowDelegate
                    required property var modelData
                    width: widgetColumn.width
                    spacing: ThemeModule.Theme.spacingMedium

                    property var rowWidgets: rowDelegate.modelData
                    property int widgetCount: rowDelegate.rowWidgets.length

                    Repeater {
                        model: rowDelegate.rowWidgets

                        delegate: Loader {
                            id: widgetLoader
                            required property var modelData
                            property string widgetName: widgetLoader.modelData
                            property int siblings: rowDelegate.widgetCount

                            width: (rowDelegate.width - (siblings - 1) * ThemeModule.Theme.spacingMedium) / siblings
                            active: dashboard.dashboardVisible && dashboard.widgetSource(widgetName) !== ""
                            asynchronous: true
                            source: dashboard.widgetSource(widgetName)

                            onLoaded: {
                                if (!item) return;
                                // Bind width to follow the Loader
                                item.width = Qt.binding(function() { return widgetLoader.width; });
                                if ("dashboardActive" in item) {
                                    item.dashboardActive = Qt.binding(function() { return dashboard.dashboardActive; });
                                }
                            }

                            Binding {
                                target: widgetLoader.item
                                property: "quickSwitchDevices"
                                when: widgetLoader.status === Loader.Ready && widgetLoader.widgetName === "audioControl"
                                value: dashboard.config.audioQuickSwitch || []
                            }

                            Binding {
                                target: widgetLoader.item
                                property: "quickSwitchDevices"
                                when: widgetLoader.status === Loader.Ready && widgetLoader.widgetName === "audioInputControl"
                                value: dashboard.config.audioInputQuickSwitch || []
                            }

                            Binding {
                                target: widgetLoader.item
                                property: "keyboardLayouts"
                                when: widgetLoader.status === Loader.Ready && widgetLoader.widgetName === "keyboardLayout"
                                value: dashboard.config.keyboardLayouts || ["us"]
                            }

                        }
                    }
                }
            }
        }
    }
}
