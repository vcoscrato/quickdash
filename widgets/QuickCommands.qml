import QtQuick
import QtQuick.Controls
import "../components" as Components
import "../theme" as ThemeModule
import Quickshell.Io

Components.Card {
    id: root
    title: "Quick Launcher"
    icon: "🚀"
    
    property var cmds: dashboard && dashboard.config && dashboard.config.quickCommands ? dashboard.config.quickCommands : []

    function commandForItem(item) {
        if (!item) {
            return [];
        }
        if (item.mode === "command") {
            return item.command || [];
        }
        if (item.mode === "shell") {
            return ["sh", "-lc", item.shell || ""];
        }
        if (item.mode === "desktop") {
            return ["gtk-launch", (item.desktop || "").replace(/\.desktop$/, "")];
        }
        return [];
    }

    function launch(item) {
        var command = root.commandForItem(item);
        if (command.length === 0) {
            return;
        }

        execProc.command = command;
        execProc.environment = item.environment || ({});
        execProc.clearEnvironment = !!item.clearEnvironment;
        execProc.workingDirectory = item.workingDirectory || "";
        execProc.startDetached();

        if (item.closeOnLaunch !== false) {
            dashboard.activePanel = "";
        }
    }
    
    Process {
        id: execProc
        running: false
    }

    Flow {
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium

        Repeater {
            model: root.cmds
            delegate: Rectangle {
                width: parent.width / 2 - ThemeModule.Theme.spacingMedium / 2
                height: 40
                radius: ThemeModule.Theme.borderRadiusSmall
                color: cmdMouse.containsMouse ? ThemeModule.Theme.cardHover : ThemeModule.Theme.surface2

                Row {
                    anchors.centerIn: parent
                    spacing: ThemeModule.Theme.spacingSmall
                    Text {
                        text: modelData.icon || "🚀"
                        font.pixelSize: ThemeModule.Theme.fontSizeNormal
                        color: ThemeModule.Theme.accent
                    }
                    Text {
                        text: modelData.label
                        font.pixelSize: ThemeModule.Theme.fontSizeNormal
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.text
                    }
                }

                MouseArea {
                    id: cmdMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.launch(modelData)
                }
            }
        }

        Text {
            width: parent.width
            visible: root.cmds.length === 0
            wrapMode: Text.WordWrap
            text: "Add launcher entries with command arrays, shell strings, or desktop ids in config.json."
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.subtext
        }
    }
}
