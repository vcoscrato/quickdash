pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Io
import Quickshell.Hyprland
import "../components" as Components
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Keyboard"
    icon: "⌨"
    visible: root.keyboardLayouts && root.keyboardLayouts.length > 1

    property var keyboardLayouts: ["us"]
    property int currentLayoutIndex: 0
    property bool layoutRefreshQueued: false

    Process {
        id: kbSelectProc
        command: ["hyprctl", "switchxkblayout", "all", "0"]
        running: false
    }

    function selectLayout(index) {
        if (!root.keyboardLayouts || root.keyboardLayouts.length === 0) {
            root.keyboardLayouts = ["us"];
        }
        var safeIndex = Math.max(0, Math.min(index, root.keyboardLayouts.length - 1));
        root.currentLayoutIndex = safeIndex;
        kbSelectProc.command = ["hyprctl", "switchxkblayout", "all", safeIndex.toString()];
        kbSelectProc.running = true;
    }

    function updateLayout() {
        layoutRefreshTimer.restart();
    }

    Component.onCompleted: {
        updateLayout();
    }

    Connections {
        target: typeof Hyprland !== "undefined" ? Hyprland : null
        function onRawEvent(event) {
            if (event.name === "activelayout") {
                updateLayout();
            }
        }
    }

    Process {
        id: kbCurrentProc
        command: ["hyprctl", "-j", "devices"]
        running: false
        onExited: {
            if (root.layoutRefreshQueued) {
                root.layoutRefreshQueued = false;
                layoutRefreshTimer.restart();
            }
        }
        stdout: StdioCollector {
            id: jsonCollector
            onStreamFinished: {
                var textToParse = "";
                try {
                    textToParse = jsonCollector.text;
                } catch (e) {
                    return;
                }
                
                try {
                    var data = JSON.parse(textToParse);
                    if (data && data.keyboards) {
                        var mainKeyboard = null;
                        for (var i = 0; i < data.keyboards.length; i++) {
                            if (data.keyboards[i].main) {
                                mainKeyboard = data.keyboards[i];
                                break;
                            }
                        }
                        if (!mainKeyboard && data.keyboards.length > 0) {
                            mainKeyboard = data.keyboards[0];
                        }

                        if (mainKeyboard && mainKeyboard.active_layout_index !== undefined) {
                            var idx = mainKeyboard.active_layout_index;
                            if (idx >= 0 && idx < root.keyboardLayouts.length) {
                                root.currentLayoutIndex = idx;
                            }
                        }
                    }
                } catch (e) {
                    console.warn("[QuickDash] Error parsing hyprctl devices output:", e);
                }
            }
        }
    }

    Timer {
        id: layoutRefreshTimer
        interval: 100
        running: false
        repeat: false
        onTriggered: {
            if (kbCurrentProc.running) {
                root.layoutRefreshQueued = true;
                return;
            }
            kbCurrentProc.running = true;
        }
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Repeater {
            model: root.keyboardLayouts

            delegate: Rectangle {
                id: layoutDelegate
                required property int index
                required property var modelData

                width: parent.width
                height: 32
                radius: ThemeModule.Theme.borderRadiusSmall
                color: kbMouse.containsMouse ? ThemeModule.Theme.cardHover : "transparent"

                Behavior on color {
                    ColorAnimation { duration: ThemeModule.Theme.animDuration }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: ThemeModule.Theme.spacingSmall
                    spacing: ThemeModule.Theme.spacingSmall

                    Rectangle {
                        width: 14
                        height: 14
                        radius: 7
                        anchors.verticalCenter: parent.verticalCenter
                        border.width: 2
                        border.color: ThemeModule.Theme.teal
                        color: layoutDelegate.index === root.currentLayoutIndex ? ThemeModule.Theme.teal : "transparent"

                        Behavior on color {
                            ColorAnimation { duration: ThemeModule.Theme.animDuration }
                        }
                    }

                    Text {
                        text: (layoutDelegate.modelData || "").toString().toUpperCase()
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.text
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    id: kbMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        root.selectLayout(layoutDelegate.index);
                    }
                }
            }
        }
    }
}
