pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property var history: []
    property bool panelVisible: false
    property bool loading: false
    property bool available: true
    property int maxItems: 40
    property int burstRemaining: 0
    property string feedbackText: ""
    property string feedbackTone: "neutral"
    property string lastCopiedId: ""
    property string pendingCopyId: ""

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    function currentInterval() {
        if (root.burstRemaining > 0) {
            return 400;
        }
        return root.panelVisible ? 1600 : 12000;
    }

    function ensurePolling() {
        pollTimer.interval = root.currentInterval();
        if (root.panelVisible || root.burstRemaining > 0) {
            if (!pollTimer.running) {
                pollTimer.start();
            }
        } else if (pollTimer.running) {
            pollTimer.stop();
        }
    }

    function requestBurst(cycles) {
        root.burstRemaining = Math.max(root.burstRemaining, cycles || 8);
        root.ensurePolling();
    }

    function setPanelVisible(visible) {
        root.panelVisible = visible;
        if (visible) {
            root.requestBurst(8);
            root.refresh();
        } else {
            root.ensurePolling();
        }
    }

    Timer {
        id: pollTimer
        interval: root.currentInterval()
        running: false
        repeat: true
        onTriggered: {
            root.refresh();
            if (root.burstRemaining > 0) {
                root.burstRemaining--;
            }
            root.ensurePolling();
        }
    }

    function refresh() {
        if (!cliphistListProc.running) {
            root.loading = true;
            cliphistListProc.running = true;
        }
    }

    Process {
        id: cliphistListProc
        command: ["sh", "-lc", "cliphist list | head -n " + root.maxItems]
        running: false
        
        property string buffer: ""
        
        stdout: SplitParser {
            onRead: function(data) {
                cliphistListProc.buffer += data + "\n";
            }
        }

        onExited: function(exitCode) {
            root.loading = false;
            root.available = exitCode === 0;

            if (exitCode !== 0) {
                root.history = [];
                if (root.panelVisible) {
                    root.feedbackText = "Clipboard history is unavailable.";
                    root.feedbackTone = "warning";
                }
                cliphistListProc.buffer = "";
                return;
            }

            var lines = cliphistListProc.buffer.split("\n");
            cliphistListProc.buffer = "";
            var newHistory = [];
            
            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line === "") continue;

                var tabIndex = line.indexOf("\t");
                if (tabIndex > 0) {
                    newHistory.push({
                        "id": line.substring(0, tabIndex),
                        "preview": line.substring(tabIndex + 1),
                        "raw": line
                    });
                }
            }
            root.history = newHistory;
        }
    }

    function copyEntry(entry) {
        if (!entry || !entry.id || copyProc.running) {
            return;
        }

        // cliphist decode expects the full "id\tpreview" line, not just the id
        var fullLine = entry.raw || (entry.id + "\t" + (entry.preview || ""));

        root.pendingCopyId = entry.id;
        root.feedbackText = "Copying…";
        root.feedbackTone = "info";
        root.requestBurst(8);
        copyProc.command = [
            "sh",
            "-lc",
            "printf '%s\\n' " + root.shellQuote(fullLine) + " | cliphist decode | wl-copy"
        ];
        copyProc.running = true;
    }

    function decodeAndCopy(id) {
        // Find the full entry in history to get the raw line
        for (var i = 0; i < root.history.length; i++) {
            if (root.history[i].id === id) {
                root.copyEntry(root.history[i]);
                return;
            }
        }
        // Fallback: try with id only (may not decode correctly without preview)
        root.copyEntry({ id: id, preview: "", raw: id });
    }

    Process {
        id: copyProc
        running: false
        onExited: function(exitCode) {
            if (exitCode === 0) {
                root.lastCopiedId = root.pendingCopyId;
                root.feedbackText = "Copied back to the clipboard.";
                root.feedbackTone = "success";
                root.refresh();
                root.requestBurst(8);
            } else {
                root.feedbackText = "Copy failed.";
                root.feedbackTone = "error";
            }
            root.pendingCopyId = "";
        }
    }
}
