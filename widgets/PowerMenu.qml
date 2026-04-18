import QtQuick
import "../components" as Components
import "../theme" as ThemeModule
import Quickshell.Io

Components.Card {
    id: root
    title: "Power Menu"
    icon: "⏻"

    Process { id: pwrProc; running: false }
    
    property string confirmAction: ""
    property string confirmCmd: ""

    Timer {
        id: resetTimer
        interval: 3000
        onTriggered: {
            root.confirmAction = "";
            root.confirmCmd = "";
        }
    }

    function doAction(action, cmd, needsConfirm) {
        if (needsConfirm && root.confirmAction !== action) {
            root.confirmAction = action;
            root.confirmCmd = cmd;
            resetTimer.restart();
        } else {
            pwrProc.command = ["sh", "-c", cmd];
            pwrProc.running = true;
            root.confirmAction = "";
        }
    }

    Flow {
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium

        property var actions: [
            { id: "lock", label: "Lock", icon: "🔒", cmd: "loginctl lock-session", confirm: false, color: ThemeModule.Theme.text },
            { id: "suspend", label: "Sleep", icon: "💤", cmd: "systemctl suspend", confirm: false, color: ThemeModule.Theme.text },
            { id: "logout", label: "Log Out", icon: "🚪", cmd: "hyprctl dispatch exit", confirm: true, color: ThemeModule.Theme.warning },
            { id: "reboot", label: "Restart", icon: "🔄", cmd: "systemctl reboot", confirm: true, color: ThemeModule.Theme.peach },
            { id: "shutdown", label: "Power Off", icon: "⏻", cmd: "systemctl poweroff", confirm: true, color: ThemeModule.Theme.error }
        ]

        Repeater {
            model: parent.actions
            delegate: Rectangle {
                width: parent.width / 2 - ThemeModule.Theme.spacingMedium / 2
                height: 60
                radius: ThemeModule.Theme.borderRadiusSmall
                color: btnMouse.containsMouse ? ThemeModule.Theme.cardHover : ThemeModule.Theme.surface2
                border.width: root.confirmAction === modelData.id ? 2 : 0
                border.color: modelData.color

                Column {
                    anchors.centerIn: parent
                    spacing: 2
                    Text {
                        text: modelData.icon
                        font.pixelSize: ThemeModule.Theme.fontSizeLarge
                        color: root.confirmAction === modelData.id ? modelData.color : ThemeModule.Theme.text
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: root.confirmAction === modelData.id ? "Sure?" : modelData.label
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        color: root.confirmAction === modelData.id ? modelData.color : ThemeModule.Theme.subtext
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    id: btnMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.doAction(modelData.id, modelData.cmd, modelData.confirm)
                }
            }
        }
    }
}
