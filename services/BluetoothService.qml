pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── State ──────────────────────────────────────────────
    property bool btOn: true
    property bool scanning: false

    property var pairedDevices: []
    property var discoveredDevices: []
    property var connectedMacs: ({})

    property var connectedRows: []
    property var knownRows: []
    property var discoveredRows: []

    // ── Helpers ────────────────────────────────────────────
    function startProcess(proc) {
        if (proc && !proc.running)
            proc.running = true;
    }

    function scheduleRebuild() {
        if (!rebuildTimer.running)
            rebuildTimer.start();
    }

    function guessDeviceIcon(name) {
        var lower = (name || "").toLowerCase();
        if (lower.indexOf("headphone") !== -1 || lower.indexOf("airpod") !== -1 || lower.indexOf("buds") !== -1 || lower.indexOf("wh-") !== -1 || lower.indexOf("wf-") !== -1)
            return "🎧";
        if (lower.indexOf("keyboard") !== -1 || lower.indexOf("keychron") !== -1)
            return "⌨";
        if (lower.indexOf("mouse") !== -1 || lower.indexOf("mx ") !== -1)
            return "🖱";
        if (lower.indexOf("speaker") !== -1)
            return "🔈";
        if (lower.indexOf("phone") !== -1)
            return "📱";
        if (lower.indexOf("controller") !== -1 || lower.indexOf("gamepad") !== -1)
            return "🎮";
        return "📟";
    }

    // ── Refresh ────────────────────────────────────────────
    function refreshSummary() {
        root.startProcess(powerStatusProc);
        root.startProcess(connectedProc);
    }

    function refreshAll(forcePairedRefresh) {
        root.refreshSummary();
        if (forcePairedRefresh || root.pairedDevices.length === 0)
            root.startProcess(pairedProc);
    }

    // ── Row building ───────────────────────────────────────
    function rebuildRows() {
        var merged = {};
        var i;

        for (i = 0; i < pairedDevices.length; i++) {
            var p = pairedDevices[i];
            merged[p.mac] = {
                mac: p.mac,
                name: p.name,
                icon: p.icon,
                paired: true,
                connected: !!connectedMacs[p.mac]
            };
        }

        for (i = 0; i < discoveredDevices.length; i++) {
            var d = discoveredDevices[i];
            if (merged[d.mac]) {
                merged[d.mac].connected = merged[d.mac].connected || !!connectedMacs[d.mac];
            } else {
                merged[d.mac] = {
                    mac: d.mac,
                    name: d.name,
                    icon: d.icon,
                    paired: false,
                    connected: !!connectedMacs[d.mac]
                };
            }
        }

        var connected = [];
        var known = [];
        var discovered = [];

        var macs = Object.keys(merged);
        for (i = 0; i < macs.length; i++) {
            var row = merged[macs[i]];
            if (row.connected) connected.push(row);
            else if (row.paired) known.push(row);
            else discovered.push(row);
        }

        function byName(a, b) {
            return (a.name || "").localeCompare(b.name || "");
        }
        connected.sort(byName);
        known.sort(byName);
        discovered.sort(byName);

        connectedRows = connected;
        knownRows = known;
        discoveredRows = discovered;
    }

    // ── Actions ────────────────────────────────────────────
    function onRowPrimary(row) {
        if (!btOn) return;

        if (row.connected) {
            disconnectProc.command = ["bluetoothctl", "disconnect", row.mac];
            disconnectProc.running = true;
        } else {
            connectProc.command = ["bluetoothctl", "connect", row.mac];
            connectProc.running = true;
        }
    }

    function startScan() {
        if (!btOn || scanning) return;
        discoveredDevices = [];
        scanning = true;
        scanProc.running = true;
    }

    function togglePower(state) {
        btOn = state;
        if (!state && scanning) {
            scanProc.running = false;
            scanning = false;
        }
        if (!state) {
            discoveredDevices = [];
            root.scheduleRebuild();
        }
        powerToggleProc.command = ["bluetoothctl", "power", state ? "on" : "off"];
        powerToggleProc.running = true;
    }

    // ── Lifecycle ──────────────────────────────────────────
    Component.onCompleted: root.refreshAll(true)

    // ── Timer ──────────────────────────────────────────────
    Timer {
        id: rebuildTimer
        interval: 0
        running: false
        repeat: false
        onTriggered: root.rebuildRows()
    }

    // ── Processes ──────────────────────────────────────────
    Process {
        id: powerStatusProc
        command: ["bluetoothctl", "show"]
        running: false
        stdout: SplitParser {
            onRead: function(line) {
                var lower = (line || "").toLowerCase();
                if (lower.indexOf("powered: yes") !== -1) btOn = true;
                if (lower.indexOf("powered: no") !== -1) btOn = false;
            }
        }
    }

    Process {
        id: powerToggleProc
        command: ["bluetoothctl", "power", "on"]
        running: false
        onExited: root.refreshAll(true)
    }

    Process {
        id: pairedProc
        command: ["bluetoothctl", "devices"]
        running: false
        property var results: []
        onRunningChanged: {
            if (running) results = [];
        }
        onExited: {
            pairedDevices = pairedProc.results;
            pairedProc.results = [];
            root.scheduleRebuild();
        }
        stdout: SplitParser {
            onRead: function(line) {
                var match = (line || "").match(/Device\s+([0-9A-Fa-f:]+)\s+(.+)/);
                if (!match) return;
                pairedProc.results.push({
                    mac: match[1],
                    name: match[2],
                    icon: root.guessDeviceIcon(match[2])
                });
            }
        }
    }

    Process {
        id: connectedProc
        command: ["bluetoothctl", "devices", "Connected"]
        running: false
        property var macMap: ({})
        onRunningChanged: {
            if (running) macMap = ({})
        }
        onExited: {
            connectedMacs = macMap;
            root.scheduleRebuild();
        }
        stdout: SplitParser {
            onRead: function(line) {
                var match = (line || "").match(/Device\s+([0-9A-Fa-f:]+)\s+(.+)/);
                if (!match) return;
                connectedProc.macMap[match[1]] = true;
            }
        }
    }

    Process {
        id: scanProc
        command: ["bluetoothctl", "--timeout", "12", "scan", "on"]
        running: false
        property var results: []
        onRunningChanged: {
            if (running) results = [];
        }
        onExited: {
            scanning = false;
            discoveredDevices = scanProc.results;
            scanProc.results = [];
            root.startProcess(pairedProc);
            root.startProcess(connectedProc);
            root.scheduleRebuild();
        }
        stdout: SplitParser {
            onRead: function(line) {
                var match = (line || "").match(/Device\s+([0-9A-Fa-f:]+)\s+(.+)/);
                if (!match) return;
                var mac = match[1];
                for (var i = 0; i < scanProc.results.length; i++) {
                    if (scanProc.results[i].mac === mac) return;
                }
                scanProc.results.push({
                    mac: mac,
                    name: match[2],
                    icon: root.guessDeviceIcon(match[2])
                });
            }
        }
    }

    Process {
        id: connectProc
        command: ["bluetoothctl", "connect", ""]
        running: false
        onExited: root.refreshAll(true)
    }

    Process {
        id: disconnectProc
        command: ["bluetoothctl", "disconnect", ""]
        running: false
        onExited: root.refreshAll(true)
    }
}
