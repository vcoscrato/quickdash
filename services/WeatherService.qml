pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: true
    property string currentWeatherStr: "Loading..."
    property string location: ""
    property bool fetchQueued: false

    Timer {
        id: weatherTimer
        interval: 1800000 // 30 mins
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchWeather()
    }

    onLocationChanged: {
        root.fetchWeather();
    }

    function fetchWeather() {
        if (!weatherProc.running) {
            var loc = root.location.trim();
            var url = loc !== "" ? ("wttr.in/" + loc + "?format=%c+%t") : "wttr.in/?format=%c+%t";
            weatherProc.command = ["curl", "-s", url];
            weatherProc.running = true;
        } else {
            root.fetchQueued = true;
        }
    }

    Process {
        id: weatherProc
        command: ["curl", "-s", "wttr.in/?format=%c+%t"]
        running: false

        property string output: ""

        stdout: SplitParser {
            onRead: function(data) {
                weatherProc.output += data;
            }
        }

        onExited: {
            var text = weatherProc.output.trim();
            weatherProc.output = "";

            if (text.length > 0 && !text.includes("Sorry") && !text.includes("Unknown")) {
                root.currentWeatherStr = text;
            } else if (text === "") {
                root.currentWeatherStr = "Offline";
            }

            if (root.fetchQueued) {
                root.fetchQueued = false;
                root.fetchWeather();
            }
        }
    }
}
