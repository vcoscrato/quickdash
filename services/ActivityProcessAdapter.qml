// qmllint disable signal-handler-parameters

import QtQuick
import Quickshell
import Quickshell.Io
import "." as Services

Scope {
    id: root

    property string lastProbeState: ""

    function applyProbeState(value) {
        var state = String(value || "").trim();
        if (state === root.lastProbeState)
            return;
        root.lastProbeState = state;

        var entries = [];
        var lines = state === "" ? [] : state.split("\n");
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].split("\t");
            if (parts[0] === "screen-recording") {
                entries.push({
                    id: "screen-recording",
                    state: "active",
                    label: "Screen recording",
                    detail: "Recording display",
                    iconName: "screen-recording",
                    tone: "error",
                    priority: 10,
                    sortOrder: 0,
                    actions: [{ id: "stop", label: "Stop", iconName: "close", tone: "error" }]
                });
            } else if (parts[0] === "dictation" && parts[1] === "busy") {
                entries.push({
                    id: "dictation",
                    state: "busy",
                    label: "Dictation",
                    detail: "Transcribing…",
                    iconName: "loader",
                    tone: "info",
                    priority: 10,
                    sortOrder: 1
                });
            } else if (parts[0] === "dictation") {
                entries.push({
                    id: "dictation",
                    state: "active",
                    label: "Dictation",
                    detail: "Listening…",
                    iconName: "audio-input",
                    tone: "info",
                    priority: 10,
                    sortOrder: 1,
                    actions: [{ id: "finish", label: "Finish", iconName: "check", tone: "info" }]
                });
            }
        }
        Services.ActivityService.replaceProvider("process", entries);
    }

    function refresh() {
        if (!probeProc.running)
            probeProc.running = true;
    }

    Component.onCompleted: root.refresh()
    Component.onDestruction: Services.ActivityService.clearProvider("process")

    Timer {
        interval: 750
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Process {
        id: probeProc

        running: false
        command: [
            "sh", "-c",
            "if pgrep -x wf-recorder >/dev/null 2>&1; then printf 'screen-recording\\tactive\\n'; fi; "
                + "if pgrep -f '[w]hisper-cli.*dictate\\.wav' >/dev/null 2>&1 "
                + "|| { pgrep -f '[d]ictate-toggle' >/dev/null 2>&1 "
                + "&& ! pgrep -f '[p]w-record.*dictate\\.wav' >/dev/null 2>&1; }; then "
                + "printf 'dictation\\tbusy\\n'; "
                + "elif pgrep -f '[p]w-record.*dictate\\.wav' >/dev/null 2>&1; then "
                + "printf 'dictation\\tactive\\n'; fi"
        ]
        stdout: StdioCollector { id: probeOutput }
        onExited: root.applyProbeState(probeOutput.text)
    }

    Connections {
        target: Services.ActivityService

        function onActionRequested(provider, activityId, actionId) {
            if (provider !== "process")
                return;
            if (activityId === "screen-recording" && actionId === "stop")
                Quickshell.execDetached(["pkill", "-SIGINT", "-x", "wf-recorder"]);
            else if (activityId === "dictation" && actionId === "finish")
                Quickshell.execDetached(["dictate-toggle"]);
        }
    }
}
