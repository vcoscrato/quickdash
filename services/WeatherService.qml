pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool active: true
    property string currentWeatherStr: "Loading..."
    property bool fetchQueued: false

    Timer {
        id: weatherTimer
        interval: 1800000 // 30 mins
        running: root.active
        repeat: true
        triggeredOnStart: true
        onTriggered: root.fetchWeather()
    }

    function fetchWeather() {
        if (!weatherProc.running) {
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
            
            // Basic validation
            if (text.length > 0 && !text.includes("Sorry") && !text.includes("Unknown")) {
                root.currentWeatherStr = text;
            } else if (text === "") {
                root.currentWeatherStr = "Offline";
            }
            
            if (root.fetchQueued) {
                root.fetchQueued = false;
                weatherProc.running = true;
            }
        }
    }
}
