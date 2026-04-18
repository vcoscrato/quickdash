import QtQuick
import "../components" as Components
import "../theme" as ThemeModule
import Quickshell.Io

Components.Card {
    id: root
    title: "Quick Commands"
    icon: "🚀"
    
    property var cmds: dashboard && dashboard.config && dashboard.config.quickCommands ? dashboard.config.quickCommands : []
    
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
                    onClicked: {
                        execProc.command = ["hyprctl", "dispatch", "exec", "--", modelData.cmd];
                        execProc.running = true;
                        dashboard.activePanel = "";
                    }
                }
            }
        }
    }
}
