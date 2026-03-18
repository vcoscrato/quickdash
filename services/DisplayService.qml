pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── State ──────────────────────────────────────────────
    property var monitors: []
    property bool hasMultipleMonitors: monitors.length > 1
    property bool isMirrored: false
    property string primaryMonitor: ""
    property string secondaryMonitor: ""

    // ── Actions ────────────────────────────────────────────
    function refresh() {
        if (!monitorsProc.running) {
            monitorsProc.running = true;
        }
    }

    function setMirrorMode(mirrored) {
        if (root.monitors.length < 2) return;
        
        // Assuming first monitor is primary, second is secondary
        var primaryId = root.primaryMonitor;
        var secondaryId = root.secondaryMonitor;
        
        if (mirrored) {
            mirrorProc.command = ["hyprctl", "keyword", "monitor", secondaryId + ",preferred,auto,1,mirror," + primaryId];
        } else {
            mirrorProc.command = ["hyprctl", "keyword", "monitor", secondaryId + ",preferred,auto,1"];
        }
        mirrorProc.running = true;
    }

    // ── Processes ──────────────────────────────────────────
    Process {
        id: monitorsProc
        command: ["hyprctl", "monitors", "all", "-j"]
        running: false
        property string outputData: ""
        
        onRunningChanged: {
            if (running) outputData = "";
        }
        
        stdout: SplitParser {
            onRead: function(line) {
                monitorsProc.outputData += line + " ";
            }
        }
        
        onExited: {
            try {
                var json = JSON.parse(monitorsProc.outputData);
                if (Array.isArray(json)) {
                    // Sort by id to have consistent primary/secondary
                    json.sort(function(a, b) { return a.id - b.id; });
                    root.monitors = json;
                    
                    if (json.length >= 2) {
                        root.primaryMonitor = json[0].name;
                        root.secondaryMonitor = json[1].name;
                        
                        // Check if any monitor is mirroring another
                        var mirrored = false;
                        for (var i = 0; i < json.length; i++) {
                            if (json[i].mirrorOf && json[i].mirrorOf !== "none" && json[i].mirrorOf !== "") {
                                mirrored = true;
                                break;
                            }
                        }
                        root.isMirrored = mirrored;
                    } else if (json.length === 1) {
                        root.primaryMonitor = json[0].name;
                        root.secondaryMonitor = "";
                        root.isMirrored = false;
                    } else {
                        root.primaryMonitor = "";
                        root.secondaryMonitor = "";
                        root.isMirrored = false;
                    }
                }
            } catch(e) {
                console.warn("[QuickDash] Failed to parse hyprctl monitors output:", e);
            }
        }
    }

    Process {
        id: mirrorProc
        command: ["hyprctl", "keyword", "monitor", ""]
        running: false
        onExited: {
            root.refresh();
        }
    }

    Component.onCompleted: {
        root.refresh();
    }
}
