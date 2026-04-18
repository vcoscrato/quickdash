pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var history: []
    property bool active: true

    Timer {
        id: pollTimer
        interval: 5000 // Poll every 5s if active
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!cliphistListProc.running) {
                cliphistListProc.running = true;
            }
        }
    }

    function refresh() {
        if (!cliphistListProc.running) {
            cliphistListProc.running = true;
        }
    }

    Process {
        id: cliphistListProc
        // List top 20 items
        command: ["sh", "-c", "cliphist list | head -n 20"]
        running: false
        
        property string buffer: ""
        
        stdout: SplitParser {
            onRead: function(data) {
                cliphistListProc.buffer += data;
            }
        }

        onExited: {
            var lines = cliphistListProc.buffer.split("\n");
            cliphistListProc.buffer = "";
            var newHistory = [];
            
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line === "") continue;
                
                var parts = line.split("\t");
                if (parts.length >= 2) {
                    newHistory.push({
                        "id": parts[0],
                        "preview": parts[1]
                    });
                }
            }
            root.history = newHistory;
        }
    }

    function decodeAndCopy(id) {
        copyProc.command = ["sh", "-c", "echo '" + id + "' | cliphist decode | wl-copy"];
        copyProc.running = true;
    }

    Process {
        id: copyProc
        running: false
    }
}
