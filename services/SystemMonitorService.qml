pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: true
    property real cpuPercent: 0
    property real ramPercent: 0
    property string ramUsedStr: "0.0G"
    property string ramTotalStr: "0.0G"
    property int cpuTempC: 0
    property string uptimeStr: ""
    property real gpuPercent: 0
    property string gpuRamUsedStr: "0.0G"
    property string gpuRamTotalStr: "0.0G"
    property real gpuRamPercent: 0

    // CPU calc state
    property real lastTotal: 0
    property real lastIdle: 0

    Timer {
        id: pollTimer
        interval: 3000
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!sysProc.running) sysProc.running = true;
            if (!gpuProc.running) gpuProc.running = true;
        }
    }

    Process {
        id: sysProc
        // Gather stat, meminfo, temp, and uptime in one call
        command: ["sh", "-c", "head -n1 /proc/stat; echo '---'; head -n3 /proc/meminfo; echo '---'; cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0; echo '---'; cat /proc/uptime"]
        running: false

        property string buffer: ""

        stdout: SplitParser {
            onRead: function(data) {
                sysProc.buffer += data;
            }
        }

        onExited: {
            var lines = sysProc.buffer.split("\n");
            sysProc.buffer = "";
            var section = 0;
            var memTotal = 0, memAvail = 0;

            for (var i = 0; i < lines.length; i++) {
                var line = lines[i].trim();
                if (line === "---") {
                    section++;
                    continue;
                }
                
                if (section === 0) { // /proc/stat CPU
                    if (line.startsWith("cpu ")) {
                        var parts = line.split(/\s+/);
                        var user = parseInt(parts[1]) || 0;
                        var nice = parseInt(parts[2]) || 0;
                        var system = parseInt(parts[3]) || 0;
                        var idle = parseInt(parts[4]) || 0;
                        var iowait = parseInt(parts[5]) || 0;
                        var irq = parseInt(parts[6]) || 0;
                        var softirq = parseInt(parts[7]) || 0;
                        var steal = parseInt(parts[8]) || 0;
                        
                        var totalIdle = idle + iowait;
                        var nonIdle = user + nice + system + irq + softirq + steal;
                        var total = totalIdle + nonIdle;
                        
                        if (root.lastTotal > 0) {
                            var totald = total - root.lastTotal;
                            var idled = totalIdle - root.lastIdle;
                            if (totald > 0) {
                                root.cpuPercent = Math.max(0, Math.min(100, ((totald - idled) / totald) * 100));
                            }
                        }
                        root.lastTotal = total;
                        root.lastIdle = totalIdle;
                    }
                } else if (section === 1) { // /proc/meminfo
                    if (line.startsWith("MemTotal:")) memTotal = parseInt(line.match(/\d+/)[0]);
                    if (line.startsWith("MemAvailable:")) memAvail = parseInt(line.match(/\d+/)[0]);
                } else if (section === 2) { // temp
                    if (line.length > 0) {
                        var tempMillis = parseInt(line);
                        root.cpuTempC = Math.round(tempMillis / 1000);
                    }
                } else if (section === 3) { // uptime
                    if (line.length > 0) {
                        var upSecs = parseFloat(line.split(/\s+/)[0]);
                        var d = Math.floor(upSecs / 86400);
                        var h = Math.floor((upSecs % 86400) / 3600);
                        var m = Math.floor((upSecs % 3600) / 60);
                        var s = "";
                        if (d > 0) s += d + "d ";
                        if (h > 0 || d > 0) s += h + "h ";
                        s += m + "m";
                        root.uptimeStr = s;
                    }
                }
            }

            if (memTotal > 0 && memAvail > 0) {
                var used = memTotal - memAvail;
                root.ramPercent = (used / memTotal) * 100;
                root.ramUsedStr = (used / 1048576).toFixed(1) + "G";
                root.ramTotalStr = (memTotal / 1048576).toFixed(1) + "G";
            }
        }
    }

    Process {
        id: gpuProc
        command: ["sh", "-c", "nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits 2>/dev/null || echo '0, 0, 0'"]
        running: false
        property string buffer: ""
        stdout: SplitParser {
            onRead: function(data) { gpuProc.buffer += data; }
        }
        onExited: {
            var text = gpuProc.buffer.trim();
            gpuProc.buffer = "";
            var parts = text.split(",");
            if (parts.length >= 3) {
                root.gpuPercent = parseFloat(parts[0]) || 0;
                var used = parseFloat(parts[1]) || 0;
                var total = parseFloat(parts[2]) || 0;
                if (total > 0) {
                    root.gpuRamPercent = (used / total) * 100;
                    root.gpuRamUsedStr = (used / 1024).toFixed(1) + "G";
                    root.gpuRamTotalStr = (total / 1024).toFixed(1) + "G";
                }
            }
        }
    }
}
