import QtQuick
import QtQuick.Controls
import "../components" as Components
import "../theme" as ThemeModule
import Quickshell.Io

Components.Card {
    id: root
    title: ""
    property bool dashboardActive: true
    
    property string focusText: ""
    property string savedDate: ""

    function getTodayStr() {
        var d = new Date();
        return d.getFullYear() + "-" + (d.getMonth() + 1) + "-" + d.getDate();
    }

    Component.onCompleted: {
        readProc.running = true;
    }

    onDashboardActiveChanged: {
        if (dashboardActive && root.savedDate !== "" && root.savedDate !== root.getTodayStr()) {
            root.focusText = "";
            root.savedDate = root.getTodayStr();
            root.saveFocus();
        }
    }

    function saveFocus() {
        var str = root.savedDate + "|" + root.focusText;
        writeProc.command = ["sh", "-c", "echo '" + str.replace(/'/g, "'\\''") + "' > ~/.config/quickdash/data/focus.txt"];
        writeProc.running = true;
    }

    Process {
        id: readProc
        command: ["cat", "/home/victor/.config/quickdash/data/focus.txt"]
        running: false
        property string buffer: ""
        stdout: SplitParser {
            onRead: function(d) { readProc.buffer += d; }
        }
        onExited: {
            var content = readProc.buffer.trim();
            readProc.buffer = "";
            var parts = content.split("|");
            if (parts.length >= 2) {
                var d = parts[0];
                var t = parts.slice(1).join("|");
                if (d === root.getTodayStr()) {
                    root.savedDate = d;
                    root.focusText = t;
                    focusInput.text = t;
                } else {
                    root.savedDate = root.getTodayStr();
                }
            } else {
                root.savedDate = root.getTodayStr();
            }
        }
    }

    Process {
        id: writeProc
        running: false
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingTiny

        Text {
            text: "🎯 What's your focus today?"
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            font.bold: true
            color: ThemeModule.Theme.accent
        }

        TextField {
            id: focusInput
            width: parent.width
            placeholderText: "Type here and press enter..."
            text: root.focusText
            font.pixelSize: ThemeModule.Theme.fontSizeNormal
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.text
            background: Rectangle { color: "transparent" }
            onAccepted: {
                root.focusText = text;
                root.savedDate = root.getTodayStr();
                root.saveFocus();
                focusInput.focus = false;
            }
        }
    }
}
