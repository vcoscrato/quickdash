import QtQuick
import "../components" as Components
import "../theme" as ThemeModule
import Quickshell.Io

Components.Card {
    id: root
    title: "Quick Timer"
    icon: "⏱"
    
    property int totalSeconds: 0
    property int remainingSeconds: 0
    property bool timerRunning: false

    function startTimer(mins) {
        root.totalSeconds = mins * 60;
        root.remainingSeconds = root.totalSeconds;
        root.timerRunning = true;
        countdownTimer.start();
    }

    function stopTimer() {
        root.timerRunning = false;
        countdownTimer.stop();
        root.remainingSeconds = 0;
    }

    function formatTime(s) {
        var m = Math.floor(s / 60);
        var rem = s % 60;
        return m + ":" + (rem < 10 ? "0" : "") + rem;
    }

    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        onTriggered: {
            if (root.remainingSeconds > 0) {
                root.remainingSeconds--;
            } else {
                root.stopTimer();
                notifyProc.running = true;
            }
        }
    }

    Process {
        id: notifyProc
        command: ["notify-send", "-a", "QuickDash", "-u", "critical", "Timer Done", "Your timer has finished!"]
        running: false
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: ThemeModule.Theme.spacingSmall
            visible: !root.timerRunning

            Repeater {
                model: [5, 10, 15, 25]
                delegate: Components.IconButton {
                    iconText: modelData + "m"
                    iconSize: ThemeModule.Theme.fontSizeNormal
                    size: 40
                    iconColor: ThemeModule.Theme.text
                    onClicked: root.startTimer(modelData)
                }
            }
        }

        Item {
            width: parent.width
            height: 120
            visible: root.timerRunning

            Rectangle {
                anchors.centerIn: parent
                width: 100
                height: 100
                radius: 50
                color: "transparent"
                border.width: 4
                border.color: ThemeModule.Theme.surface2

                // Manual arc logic is hard in pure QML without Canvas, we'll use a simple progress rect 
                // mapped over the circular border visually with a clip or just a simple bar.
                // Let's just use a simple text + bar for now to avoid Canvas performance issues.
            }
            
            Column {
                anchors.centerIn: parent
                spacing: 5
                
                Text {
                    text: root.formatTime(root.remainingSeconds)
                    font.pixelSize: ThemeModule.Theme.fontSizeHuge
                    font.family: ThemeModule.Theme.fontFamily
                    font.bold: true
                    color: root.remainingSeconds < 60 ? ThemeModule.Theme.error : ThemeModule.Theme.accent
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                Rectangle {
                    width: 80
                    height: 4
                    radius: 2
                    color: ThemeModule.Theme.surface2
                    
                    Rectangle {
                        width: root.totalSeconds > 0 ? (root.remainingSeconds / root.totalSeconds) * parent.width : 0
                        height: parent.height
                        radius: 2
                        color: root.remainingSeconds < 60 ? ThemeModule.Theme.error : ThemeModule.Theme.accent
                    }
                }
            }
        }

        Components.IconButton {
            anchors.horizontalCenter: parent.horizontalCenter
            iconText: "Stop"
            iconSize: ThemeModule.Theme.fontSizeNormal
            size: 40
            visible: root.timerRunning
            onClicked: root.stopTimer()
        }
    }
}
