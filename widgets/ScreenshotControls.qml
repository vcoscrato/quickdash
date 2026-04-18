import QtQuick
import QtQuick.Controls
import "../components" as Components
import "../theme" as ThemeModule
import Quickshell.Io

Components.Card {
    id: root
    title: "Screenshot"
    icon: "📸"
    
    Process {
        id: shotProc
        running: false
    }

    function takeShot(type) {
        dashboard.activePanel = ""; // Hide dash to take clean shot
        // Wait a tiny bit for the dashboard to hide
        var cmd = "";
        if (type === "region") {
            cmd = "sleep 0.2 && grim -g \"$(slurp)\" - | wl-copy && notify-send 'Screenshot' 'Region copied to clipboard'";
        } else if (type === "window") {
            cmd = "sleep 0.2 && grim -g \"$(hyprctl activewindow -j | jq -r '.at[0], \",\", .at[1], \" \", .size[0], \"x\", .size[1]' | tr -d '\n')\" - | wl-copy && notify-send 'Screenshot' 'Window copied to clipboard'";
        } else {
            cmd = "sleep 0.2 && grim - | wl-copy && notify-send 'Screenshot' 'Screen copied to clipboard'";
        }
        shotProc.command = ["sh", "-c", cmd];
        shotProc.running = true;
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: ThemeModule.Theme.spacingMedium

            Components.IconButton {
                iconText: "⚄"
                ToolTip.text: "Region"
                ToolTip.visible: containsMouse
                size: 48
                iconSize: 24
                onClicked: root.takeShot("region")
            }
            Components.IconButton {
                iconText: "🪟"
                ToolTip.text: "Window"
                ToolTip.visible: containsMouse
                size: 48
                iconSize: 24
                onClicked: root.takeShot("window")
            }
            Components.IconButton {
                iconText: "🖥"
                ToolTip.text: "Fullscreen"
                ToolTip.visible: containsMouse
                size: 48
                iconSize: 24
                onClicked: root.takeShot("screen")
            }
        }
    }
}
