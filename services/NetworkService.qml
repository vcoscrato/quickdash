pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── State ──────────────────────────────────────────────
    property bool wifiOn: true
    property bool scanning: false
    property string currentSSID: ""

    property bool realWiredConnected: false
    property string realWiredConnectionName: ""
    property string realWiredConnectionUuid: ""
    property string realWiredIp: ""

    readonly property bool wiredConnected: realWiredConnected
    readonly property string wiredConnectionName: realWiredConnectionName
    readonly property string wiredConnectionUuid: realWiredConnectionUuid
    readonly property string wiredIp: realWiredIp

    property var rawNetworks: []
    property var savedWifiProfiles: [] // [{name, uuid, autoconnect}]
    property var activeWifiByName: ({}) // {ssid: {uuid, name, ip}}

    property var connectedRows: []
    property var otherWifiRows: []

    readonly property var currentConnectedWifi: connectedRows.length > 0 ? connectedRows[0] : null

    property string passwordRowSsid: ""
    property string passwordText: ""
    property string connectError: ""
    property string connectErrorSsid: ""

    property bool connecting: false
    property string connectingSsid: ""

    property string forgetArmedSsid: ""
    property bool toolAvailable: true
    property string statusMessage: ""

    function setStatusMessage(message) {
        root.statusMessage = message || "";
    }

    function clearStatusMessage() {
        root.setStatusMessage("");
    }

    // ── Process helpers ────────────────────────────────────
    function startProcess(proc) {
        if (proc && !proc.running)
            proc.running = true;
    }

    function stopProcess(proc) {
        if (proc && proc.running)
            proc.running = false;
    }

    // ── Monitor management ─────────────────────────────────
    // The network monitor watches for nmcli events (connectivity changes).
    // NOTE: Scanning is NEVER triggered automatically — only by explicit
    // user action (clicking "Scan"). This is intentional because network
    // scanning causes heavy system stutter on some hardware.
    function setMonitorRunning(shouldRun) {
        if (shouldRun) {
            if (SystemState.dashboardVisible && !root.scanning) {
                networkMonitorRestartTimer.stop();
                root.startProcess(networkMonitorProc);
            }
            return;
        }

        root.stopProcess(networkMonitorProc);
        networkMonitorRestartTimer.stop();
    }

    function scheduleRebuild() {
        if (!rebuildTimer.running)
            rebuildTimer.start();
    }

    function scheduleMonitorRefresh(forceDetails) {
        if (root.scanning) {
            return;
        }
        monitorRefreshTimer.forceDetails = !!forceDetails;
        monitorRefreshTimer.restart();
    }

    // ── Scan ───────────────────────────────────────────────
    // Scanning is user-initiated only. Never called automatically.
    function startScan() {
        if (!root.wifiOn || root.scanning)
            return;
        if (!root.toolAvailable) {
            root.setStatusMessage("nmcli is not available");
            return;
        }

        monitorRefreshTimer.stop();
        root.setMonitorRunning(false);
        root.scanning = true;
        scanProc.running = true;
    }

    function finishScan() {
        root.scanning = false;
        root.scheduleRebuild();
        root.setMonitorRunning(true);
        root.refreshSummary();
        if (root.savedWifiProfiles.length === 0)
            root.refreshDetails();
    }

    // ── Refresh ────────────────────────────────────────────
    function refreshSummary() {
        if (!root.toolAvailable)
            return;
        root.startProcess(activeConnectionsProc);
        root.startProcess(wifiStatusProc);
        root.startProcess(activeSsidProc);
    }

    function refreshDetails() {
        if (!root.toolAvailable)
            return;
        root.startProcess(savedProfilesProc);
    }

    function refreshAll(forceDetails) {
        root.refreshSummary();

        if (forceDetails || root.savedWifiProfiles.length === 0)
            root.refreshDetails();
    }

    // ── Parsing helpers ────────────────────────────────────
    function parseNmcliFields(line, expectedParts) {
        var out = [];
        var cur = "";
        var escaped = false;
        for (var i = 0; i < line.length; i++) {
            var ch = line[i];
            if (escaped) {
                cur += ch;
                escaped = false;
                continue;
            }
            if (ch === "\\") {
                escaped = true;
                continue;
            }
            if (ch === ":" && out.length < expectedParts - 1) {
                out.push(cur);
                cur = "";
                continue;
            }
            cur += ch;
        }
        out.push(cur);
        return out;
    }

    function isSecure(security) {
        var sec = (security || "").trim().toUpperCase();
        return !(sec === "" || sec === "--" || sec === "NONE");
    }

    function parseAutoconnect(v) {
        var lower = (v || "").trim().toLowerCase();
        return lower === "yes" || lower === "true" || lower === "on" || lower === "1";
    }

    function savedProfile(ssid) {
        for (var i = 0; i < savedWifiProfiles.length; i++) {
            if (savedWifiProfiles[i].name === ssid)
                return savedWifiProfiles[i];
        }
        return null;
    }

    function savedProfileUuid(ssid) {
        var profile = savedProfile(ssid);
        return profile ? profile.uuid : "";
    }

    function autoconnectChipForRow(row) {
        if (row.autoconnect === null) {
            return {
                text: "Auto: ?",
                tone: "neutral",
                enabled: false,
                actionId: "autoconnect"
            };
        }
        return {
            text: row.autoconnect ? "Auto: On" : "Auto: Off",
            tone: row.autoconnect ? "success" : "neutral",
            enabled: true,
            actionId: "autoconnect"
        };
    }

    function connectedWifiSubtitle(row) {
        if (!row) return "Not connected";
        var parts = [];
        if (row.connectionIp && row.connectionIp !== "") parts.push("IP " + row.connectionIp);
        if (row.signal >= 0) parts.push(row.signal + "%");
        if (parts.length === 0) return "Connected";
        return parts.join(" • ");
    }

    // ── Row building ───────────────────────────────────────
    function rebuildRows() {
        var strongest = {};
        for (var i = 0; i < rawNetworks.length; i++) {
            var n = rawNetworks[i];
            var prev = strongest[n.ssid];
            if (!prev || n.signal > prev.signal) {
                strongest[n.ssid] = n;
            }
        }

        var connected = [];
        var known = [];
        var available = [];

        var names = Object.keys(strongest);
        for (var j = 0; j < names.length; j++) {
            var ssid = names[j];
            var base = strongest[ssid];
            var profile = savedProfile(ssid);
            var activeProfile = activeWifiByName[ssid];
            var row = {
                ssid: ssid,
                signal: base.signal,
                security: base.security,
                secure: isSecure(base.security),
                connected: ssid === currentSSID,
                known: profile !== null,
                connectionUuid: activeProfile ? activeProfile.uuid : (profile ? profile.uuid : ""),
                connectionIp: activeProfile ? (activeProfile.ip || "") : "",
                autoconnect: profile ? profile.autoconnect : null
            };

            if (row.connected) connected.push(row);
            else if (row.known) known.push(row);
            else available.push(row);
        }

        if (currentSSID !== "" && connected.length === 0) {
            var currentProfile = savedProfile(currentSSID);
            var currentActive = activeWifiByName[currentSSID];
            connected.push({
                ssid: currentSSID,
                signal: -1,
                security: "",
                secure: false,
                connected: true,
                known: currentProfile !== null,
                connectionUuid: currentActive ? currentActive.uuid : (currentProfile ? currentProfile.uuid : ""),
                connectionIp: currentActive ? (currentActive.ip || "") : "",
                autoconnect: currentProfile ? currentProfile.autoconnect : null
            });
        }

        function bySignalDesc(a, b) {
            return (b.signal || 0) - (a.signal || 0);
        }
        known.sort(bySignalDesc);
        available.sort(bySignalDesc);

        connectedRows = connected;
        otherWifiRows = known.concat(available);
    }

    // ── Actions ────────────────────────────────────────────
    function setWifiEnabled(enabled) {
        if (wifiOn === enabled) return;
        if (!root.toolAvailable) {
            root.setStatusMessage("nmcli is not available");
            return;
        }
        wifiOn = enabled;
        wifiToggleProc.command = ["nmcli", "radio", "wifi", enabled ? "on" : "off"];
        wifiToggleProc.running = true;
        if (!enabled) {
            currentSSID = "";
            scanning = false;
            root.scheduleRebuild();
        }
    }

    function requestConnect(row, password) {
        if (!root.toolAvailable) {
            root.setStatusMessage("nmcli is not available");
            return;
        }
        connectError = "";
        connectErrorSsid = "";
        connecting = true;
        connectingSsid = row.ssid;

        connectProc.targetSsid = row.ssid;
        connectProc.targetSecure = row.secure;
        connectProc.targetKnown = row.known;
        connectProc.hadPassword = password && password !== "";

        var cmd = ["nmcli", "dev", "wifi", "connect", row.ssid];
        if (password && password !== "") {
            cmd.push("password");
            cmd.push(password);
        }
        connectProc.command = cmd;
        connectProc.running = true;
    }

    function requestDisconnectWifi(row) {
        if (!row) return;
        if (!root.toolAvailable) {
            root.setStatusMessage("nmcli is not available");
            return;
        }
        wifiDisconnectProc.targetSsid = row.ssid;
        wifiDisconnectProc.command = row.connectionUuid !== ""
            ? ["nmcli", "connection", "down", "uuid", row.connectionUuid]
            : ["nmcli", "connection", "down", "id", row.ssid];
        wifiDisconnectProc.running = true;
    }

    function onRowPrimary(row) {
        if (!wifiOn || scanning || row.connected) return;

        // Unknown secured networks ask password inline first.
        if (row.secure && !row.known) {
            passwordRowSsid = row.ssid;
            passwordText = "";
            connectError = "";
            connectErrorSsid = "";
            return;
        }

        requestConnect(row, "");
    }

    function onForgetClicked(ssid) {
        if (forgetArmedSsid === ssid) {
            var uuid = savedProfileUuid(ssid);
            forgetProc.targetSsid = ssid;
            forgetProc.command = uuid !== ""
                ? ["nmcli", "connection", "delete", "uuid", uuid]
                : ["nmcli", "connection", "delete", "id", ssid];
            forgetProc.running = true;
            forgetArmedSsid = "";
            forgetArmTimer.stop();
            return;
        }
        forgetArmedSsid = ssid;
        forgetArmTimer.restart();
    }

    function onToggleAutoconnect(row) {
        if (!row || row.connectionUuid === "" || row.autoconnect === null) return;
        if (!root.toolAvailable) {
            root.setStatusMessage("nmcli is not available");
            return;
        }
        autoconnectProc.command = [
            "nmcli", "connection", "modify", "uuid", row.connectionUuid,
            "connection.autoconnect", row.autoconnect ? "no" : "yes"
        ];
        autoconnectProc.running = true;
    }

    function cancelPasswordPrompt() {
        passwordRowSsid = "";
        passwordText = "";
        connectError = "";
        connectErrorSsid = "";
    }

    // ── Lifecycle ──────────────────────────────────────────
    Component.onCompleted: {
        nmcliProbeProc.running = true;
    }

    Connections {
        target: SystemState
        function onDashboardVisibleChanged() {
            if (!root.toolAvailable)
                return;
            if (SystemState.dashboardVisible) {
                root.setMonitorRunning(true);
                root.scheduleMonitorRefresh(true);
                return;
            }

            root.setMonitorRunning(false);
            monitorRefreshTimer.stop();
        }
    }

    // ── Timers ─────────────────────────────────────────────
    Timer {
        id: forgetArmTimer
        interval: 2500
        running: false
        repeat: false
        onTriggered: root.forgetArmedSsid = ""
    }

    Timer {
        id: rebuildTimer
        interval: 0
        running: false
        repeat: false
        onTriggered: root.rebuildRows()
    }

    Timer {
        id: monitorRefreshTimer
        interval: 250
        running: false
        repeat: false
        property bool forceDetails: false
        onTriggered: {
            root.refreshAll(forceDetails);
            forceDetails = false;
        }
    }

    Timer {
        id: networkMonitorRestartTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            if (SystemState.dashboardVisible && !root.scanning)
                root.startProcess(networkMonitorProc);
        }
    }

    // ── Processes ───────────────────────────────────────────
    Process {
        id: nmcliProbeProc
        command: ["sh", "-lc", "command -v nmcli >/dev/null 2>&1"]
        running: false
        onExited: function(exitCode) {
            root.toolAvailable = exitCode === 0;
            if (!root.toolAvailable) {
                root.setStatusMessage("nmcli is not available");
                root.scanning = false;
                root.connecting = false;
                root.connectingSsid = "";
                return;
            }

            root.clearStatusMessage();
            root.setMonitorRunning(true);
            if (SystemState.dashboardVisible)
                root.refreshAll(true);
        }
    }

    Process {
        id: networkMonitorProc
        command: ["nmcli", "monitor"]
        running: false
        onExited: function(exitCode) {
            if (!root.toolAvailable)
                return;
            if (SystemState.dashboardVisible && !root.scanning && exitCode !== 0) {
                root.setStatusMessage("Network status unavailable");
                return;
            }
            if (SystemState.dashboardVisible && !root.scanning)
                networkMonitorRestartTimer.restart();
        }
        stdout: SplitParser {
            onRead: function(line) {
                if ((line || "").trim() !== "")
                    root.scheduleMonitorRefresh(false);
            }
        }
    }

    Process {
        id: activeConnectionsProc
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,IP4.ADDRESS", "connection", "show", "--active"]
        running: false
        property var wifiMap: ({})
        property bool foundEthernet: false
        property string ethernetName: ""
        property string ethernetUuid: ""
        property string ethernetIp: ""
        onRunningChanged: {
            if (running) {
                wifiMap = ({});
                foundEthernet = false;
                ethernetName = "";
                ethernetUuid = "";
                ethernetIp = "";
            }
        }
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.setStatusMessage("Network status unavailable");
                return;
            }
            root.clearStatusMessage();
            activeWifiByName = wifiMap;
            realWiredConnected = foundEthernet;
            realWiredConnectionName = ethernetName;
            realWiredConnectionUuid = ethernetUuid;
            realWiredIp = ethernetIp;
            root.scheduleRebuild();
        }
        stdout: SplitParser {
            onRead: function(line) {
                var parts = root.parseNmcliFields(line, 4);
                if (parts.length < 4) return;
                var name = parts[0] || "";
                var uuid = parts[1] || "";
                var type = (parts[2] || "").toLowerCase();
                var ip = (parts[3] || "").split(",")[0];
                if (type === "802-11-wireless" || type === "wifi") {
                    activeConnectionsProc.wifiMap[name] = { name: name, uuid: uuid, ip: ip };
                } else if (type === "802-3-ethernet" || type === "ethernet") {
                    activeConnectionsProc.foundEthernet = true;
                    activeConnectionsProc.ethernetName = name;
                    activeConnectionsProc.ethernetUuid = uuid;
                    activeConnectionsProc.ethernetIp = ip;
                }
            }
        }
    }

    Process {
        id: wifiStatusProc
        command: ["nmcli", "radio", "wifi"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.setStatusMessage("Network status unavailable");
        }
        stdout: SplitParser {
            onRead: function(line) {
                var v = (line || "").trim().toLowerCase();
                if (v === "enabled") wifiOn = true;
                if (v === "disabled") {
                    wifiOn = false;
                    currentSSID = "";
                    root.scheduleRebuild();
                }
            }
        }
    }

    Process {
        id: activeSsidProc
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID", "dev", "wifi"]
        running: false
        property bool foundActive: false
        onRunningChanged: if (running) foundActive = false
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.setStatusMessage("Network status unavailable");
                return;
            }
            if (!foundActive) currentSSID = "";
            root.scheduleRebuild();
        }
        stdout: SplitParser {
            onRead: function(line) {
                var parts = root.parseNmcliFields(line, 2);
                if (parts.length < 2) return;
                if (parts[0] === "yes") {
                    activeSsidProc.foundActive = true;
                    currentSSID = parts[1] || "";
                }
            }
        }
    }

    Process {
        id: savedProfilesProc
        command: ["nmcli", "-t", "-f", "NAME,UUID,TYPE,AUTOCONNECT", "connection", "show"]
        running: false
        property var results: []
        onRunningChanged: {
            if (running) results = [];
        }
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.setStatusMessage("Saved network list unavailable");
                return;
            }
            savedWifiProfiles = savedProfilesProc.results;
            savedProfilesProc.results = [];
            root.scheduleRebuild();
        }
        stdout: SplitParser {
            onRead: function(line) {
                var parts = root.parseNmcliFields(line, 4);
                if (parts.length < 4) return;
                var type = (parts[2] || "").toLowerCase();
                if (type === "802-11-wireless" || type === "wifi") {
                    savedProfilesProc.results.push({
                        name: parts[0],
                        uuid: parts[1],
                        autoconnect: root.parseAutoconnect(parts[3])
                    });
                }
            }
        }
    }

    Process {
        id: scanProc
        command: ["nmcli", "-t", "-f", "SSID,SIGNAL,SECURITY", "dev", "wifi", "list", "--rescan", "yes"]
        running: false
        property var results: []
        onRunningChanged: {
            if (running) results = [];
        }
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.setStatusMessage("Network scan failed");
                scanProc.results = [];
                root.finishScan();
                return;
            }
            root.clearStatusMessage();
            rawNetworks = scanProc.results;
            scanProc.results = [];
            root.finishScan();
        }
        stdout: SplitParser {
            onRead: function(line) {
                var parts = root.parseNmcliFields(line, 3);
                if (parts.length < 3) return;
                if (!parts[0] || parts[0] === "") return;
                scanProc.results.push({
                    ssid: parts[0],
                    signal: parseInt(parts[1]) || 0,
                    security: parts[2] || ""
                });
            }
        }
    }

    Process {
        id: wifiToggleProc
        command: ["nmcli", "radio", "wifi", "on"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.setStatusMessage("Wi-Fi toggle failed");
            else
                root.clearStatusMessage();
            root.refreshAll(true)
        }
    }

    Process {
        id: connectProc
        command: ["nmcli", "dev", "wifi", "connect", ""]
        running: false
        property string targetSsid: ""
        property bool targetSecure: false
        property bool targetKnown: false
        property bool hadPassword: false
        onExited: function(exitCode) {
            connecting = false;
            connectingSsid = "";

            if (exitCode === 0) {
                root.clearStatusMessage();
                connectError = "";
                connectErrorSsid = "";
                passwordRowSsid = "";
                passwordText = "";
                root.refreshAll(true);
                return;
            }

            if (targetSecure && !targetKnown && !hadPassword) {
                passwordRowSsid = targetSsid;
                connectError = "Password required";
                connectErrorSsid = targetSsid;
            } else {
                connectError = "Could not connect";
                connectErrorSsid = targetSsid;
            }
            root.refreshAll(true);
        }
    }

    Process {
        id: wifiDisconnectProc
        command: ["nmcli", "connection", "down", "id", ""]
        running: false
        property string targetSsid: ""
        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.setStatusMessage("Disconnect failed");
            else
                root.clearStatusMessage();
            if (currentSSID === targetSsid) currentSSID = "";
            root.refreshAll(true);
        }
    }

    Process {
        id: autoconnectProc
        command: ["nmcli", "connection", "modify", "uuid", "", "connection.autoconnect", "yes"]
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.setStatusMessage("Autoconnect update failed");
            else
                root.clearStatusMessage();
            root.refreshAll(true)
        }
    }

    Process {
        id: forgetProc
        command: ["nmcli", "connection", "delete", "id", ""]
        running: false
        property string targetSsid: ""
        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.setStatusMessage("Forget network failed");
            else
                root.clearStatusMessage();
            if (passwordRowSsid === targetSsid) {
                passwordRowSsid = "";
                passwordText = "";
            }
            root.refreshAll(true);
        }
    }
}
