import QtQuick
import QtQuick.Controls
import "../components" as Components
import "../theme" as ThemeModule
import Quickshell.Io

Components.Card {
    id: root
    title: "Scratchpad"
    icon: "📝"
    property bool dashboardActive: true
    
    property string textContent: ""
    property bool isLoaded: false

    Component.onCompleted: readProc.running = true

    onDashboardActiveChanged: {
        if (!dashboardActive && isLoaded && textContent !== scratchInput.text) {
            textContent = scratchInput.text;
            saveContent();
        }
    }

    function saveContent() {
        var t = scratchInput.text.replace(/'/g, "'\\''");
        writeProc.command = ["sh", "-c", "echo '" + t + "' > ~/.config/quickdash/data/scratchpad.txt"];
        writeProc.running = true;
    }

    Process {
        id: readProc
        command: ["cat", "/home/victor/.config/quickdash/data/scratchpad.txt"]
        running: false
        property string buffer: ""
        stdout: SplitParser {
            onRead: function(d) { readProc.buffer += d; }
        }
        onExited: {
            root.textContent = readProc.buffer;
            scratchInput.text = readProc.buffer;
            readProc.buffer = "";
            root.isLoaded = true;
        }
    }

    Process { id: writeProc; running: false }

    Rectangle {
        width: parent.width
        height: 200
        radius: ThemeModule.Theme.borderRadiusSmall
        color: ThemeModule.Theme.surface2
        border.width: 1
        border.color: scratchInput.activeFocus ? ThemeModule.Theme.accent : ThemeModule.Theme.overlay

        Flickable {
            anchors.fill: parent
            anchors.margins: ThemeModule.Theme.spacingSmall
            contentWidth: width
            contentHeight: scratchInput.height
            clip: true

            TextArea {
                id: scratchInput
                width: parent.width
                height: Math.max(implicitHeight, 180)
                wrapMode: TextEdit.Wrap
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.text
                background: null
                placeholderText: "Jot down some notes..."
                onTextChanged: {
                    if (root.isLoaded && root.dashboardActive && root.textContent !== text) {
                        saveTimer.restart();
                    }
                }
            }
        }
    }

    Timer {
        id: saveTimer
        interval: 1000
        onTriggered: {
            root.textContent = scratchInput.text;
            root.saveContent();
        }
    }
}
