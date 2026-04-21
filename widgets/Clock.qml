import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: ""
    property bool dashboardActive: true

    readonly property real dockedTimerWidth: root.timerRunning ? 80 : 0
    readonly property real dockedTimerGap: root.timerRunning ? 28 : 0

    property string timeString: ""
    property string dateString: ""
    property string greeting: ""
    property bool showColon: true
    property bool timerControlsOpen: false
    property int totalSeconds: 0
    property int remainingSeconds: 0
    property bool timerRunning: false

    function refreshTime() {
        var now = new Date();
        var h = now.getHours();
        var m = now.getMinutes();
        root.timeString = (h < 10 ? "0" : "") + h + " " + (m < 10 ? "0" : "") + m;
        root.dateString = Qt.formatDate(now, "dddd, MMMM d");
        
        if (h >= 5 && h < 12) root.greeting = "Good morning";
        else if (h >= 12 && h < 18) root.greeting = "Good afternoon";
        else if (h >= 18 && h < 22) root.greeting = "Good evening";
        else root.greeting = "Good night";
    }

    function scheduleNextTick() {
        clockTimer.stop();
        if (!root.dashboardActive)
            return;

        var now = new Date();
        var nextSecond = new Date(now.getTime());
        nextSecond.setMilliseconds(0);
        nextSecond.setSeconds(nextSecond.getSeconds() + 1);
        clockTimer.interval = Math.max(50, nextSecond.getTime() - now.getTime());
        clockTimer.start();
    }

    function formatTimer(seconds) {
        var safeSeconds = Math.max(0, seconds);
        var hours = Math.floor(safeSeconds / 3600);
        var minutes = Math.floor((safeSeconds % 3600) / 60);
        var remainder = safeSeconds % 60;

        if (hours > 0) {
            return hours + ":"
                + (minutes < 10 ? "0" : "") + minutes + ":"
                + (remainder < 10 ? "0" : "") + remainder;
        }

        return minutes + ":" + (remainder < 10 ? "0" : "") + remainder;
    }

    function timerAccentColor() {
        return ThemeModule.Theme.accent;
    }

    function startTimer(minutes) {
        var safeMinutes = Math.max(1, Math.round(Number(minutes) || 0));
        root.totalSeconds = safeMinutes * 60;
        root.remainingSeconds = root.totalSeconds;
        root.timerRunning = true;
        root.timerControlsOpen = false;
        customTimerInput.text = "";
        countdownTimer.start();
    }

    function stopTimer() {
        root.timerRunning = false;
        root.totalSeconds = 0;
        root.remainingSeconds = 0;
        countdownTimer.stop();
    }

    function addTimerMinutes(minutes) {
        var extra = Math.max(1, Math.round(Number(minutes) || 0)) * 60;
        if (!root.timerRunning) {
            root.startTimer(minutes);
            return;
        }

        root.remainingSeconds += extra;
        root.totalSeconds += extra;
    }

    function startCustomTimer() {
        var customMinutes = parseInt(customTimerInput.text, 10);
        if (!isNaN(customMinutes) && customMinutes > 0) {
            root.startTimer(customMinutes);
        }
    }

    Component.onCompleted: {
        root.refreshTime();
        root.scheduleNextTick();
    }

    Timer {
        id: clockTimer
        interval: 1000
        running: false
        repeat: false
        onTriggered: {
            root.showColon = !root.showColon;
            var now = new Date();
            if (now.getSeconds() === 0) {
                root.refreshTime();
            }
            root.scheduleNextTick();
        }
    }

    Timer {
        id: countdownTimer
        interval: 1000
        running: false
        repeat: true
        onTriggered: {
            if (root.remainingSeconds > 1) {
                root.remainingSeconds--;
            } else {
                root.stopTimer();
                timerDoneProc.running = true;
            }
        }
    }

    Process {
        id: timerDoneProc
        command: ["notify-send", "-a", "QuickDash", "-u", "critical", "Timer Done", "Your timer has finished."]
        running: false
    }

    onDashboardActiveChanged: {
        if (root.dashboardActive)
            root.refreshTime();
        root.scheduleNextTick();
    }

    Column {
        width: parent.width
        spacing: root.timerControlsOpen ? ThemeModule.Theme.spacingMedium : ThemeModule.Theme.spacingTiny

        Item {
            width: parent.width
            height: Math.max(clockStage.implicitHeight, timerEntryButton.visible ? timerEntryButton.height : 0)

            Item {
                id: clockStage
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                width: clockInfoColumn.implicitWidth + root.dockedTimerGap + root.dockedTimerWidth
                implicitHeight: Math.max(clockInfoColumn.implicitHeight, root.dockedTimerWidth)

                Behavior on width {
                    NumberAnimation { duration: 240; easing.type: Easing.OutCubic }
                }

                Column {
                    id: clockInfoColumn
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: ThemeModule.Theme.spacingTiny

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 2

                        Text {
                            text: root.timeString.substring(0, 2)
                            font.pixelSize: ThemeModule.Theme.fontSizeHuge
                            font.bold: true
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.text
                        }
                        Text {
                            text: ":"
                            font.pixelSize: ThemeModule.Theme.fontSizeHuge
                            font.bold: true
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.text
                            opacity: root.showColon ? 1.0 : 0.2
                            Behavior on opacity { NumberAnimation { duration: 100 } }
                        }
                        Text {
                            text: root.timeString.substring(3, 5)
                            font.pixelSize: ThemeModule.Theme.fontSizeHuge
                            font.bold: true
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.text
                        }
                    }

                    Text {
                        text: root.dateString
                        font.pixelSize: ThemeModule.Theme.fontSizeNormal
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.text
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Item { width: 1; height: 2 }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5

                        Text {
                            text: root.greeting
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.subtext
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            text: "·"
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.overlay
                            visible: Services.WeatherService.currentWeatherStr !== "Loading..."
                                && Services.WeatherService.currentWeatherStr !== "Offline"
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            readonly property string locationLabel: Services.WeatherService.location.trim() !== ""
                                ? ("  " + Services.WeatherService.location.trim())
                                : ""
                            text: Services.WeatherService.currentWeatherStr + locationLabel
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.subtext
                            visible: Services.WeatherService.currentWeatherStr !== "Loading..."
                                && Services.WeatherService.currentWeatherStr !== "Offline"
                            anchors.verticalCenter: parent.verticalCenter

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true
                                onClicked: Services.WeatherService.fetchWeather()
                                ToolTip.visible: containsMouse
                                ToolTip.text: "Click to refresh weather"
                                ToolTip.delay: 400
                            }
                        }
                    }
                }

                Item {
                    id: compactTimerRing
                    anchors.left: clockInfoColumn.right
                    anchors.leftMargin: root.dockedTimerGap
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.dockedTimerWidth
                    height: root.dockedTimerWidth
                    opacity: root.timerRunning ? 1.0 : 0.0
                    visible: opacity > 0

                    Behavior on opacity { NumberAnimation { duration: 200 } }

                    Canvas {
                        id: timerCanvas
                        anchors.fill: parent

                        readonly property real progress: root.totalSeconds > 0
                            ? root.remainingSeconds / root.totalSeconds : 1.0
                        readonly property color ringColor: root.timerAccentColor()

                        onProgressChanged: requestPaint()
                        onRingColorChanged: requestPaint()
                        Component.onCompleted: requestPaint()

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.reset();

                            var cx = width / 2;
                            var cy = height / 2;
                            var stroke = 4;
                            var r = width / 2 - stroke;

                            // Track
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, 0, Math.PI * 2);
                            ctx.strokeStyle = Qt.rgba(ringColor.r, ringColor.g, ringColor.b, 0.18);
                            ctx.lineWidth = stroke;
                            ctx.stroke();

                            // Progress arc (counterclockwise from top)
                            if (progress > 0) {
                                ctx.beginPath();
                                ctx.arc(cx, cy, r,
                                    -Math.PI / 2,
                                    -Math.PI / 2 - progress * Math.PI * 2,
                                    true);
                                ctx.strokeStyle = Qt.rgba(ringColor.r, ringColor.g, ringColor.b, 1.0);
                                ctx.lineWidth = stroke;
                                ctx.lineCap = "round";
                                ctx.stroke();
                            }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: root.formatTimer(root.remainingSeconds)
                        font.pixelSize: 13
                        font.bold: true
                        font.family: ThemeModule.Theme.fontFamily
                        color: root.timerAccentColor()
                        horizontalAlignment: Text.AlignHCenter
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onClicked: root.timerControlsOpen = !root.timerControlsOpen
                        ToolTip.visible: containsMouse
                        ToolTip.text: "Click to edit timer"
                        ToolTip.delay: 400
                    }
                }
            }

            Components.IconButton {
                id: timerEntryButton
                visible: !root.timerRunning
                anchors.right: parent.right
                anchors.top: parent.top
                size: 34
                iconSize: 16
                iconText: "⏱"
                iconColor: ThemeModule.Theme.text
                hoverColor: Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.16)
                onClicked: root.timerControlsOpen = !root.timerControlsOpen
            }
        }

        Column {
            id: timerControlsColumn
            width: parent.width
            visible: root.timerControlsOpen
            spacing: ThemeModule.Theme.spacingSmall

            Text {
                text: root.timerRunning ? "Timer controls" : "Start a timer"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
                color: ThemeModule.Theme.text
            }

            Flow {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Repeater {
                    model: root.timerRunning ? [1, 5, 10] : [10, 25, 45]
                    delegate: Components.InlineActionChip {
                        text: (root.timerRunning ? "+" : "") + modelData + "m"
                        tone: root.timerRunning ? "success" : "info"
                        onActivated: {
                            if (root.timerRunning) root.addTimerMinutes(modelData);
                            else root.startTimer(modelData);
                        }
                    }
                }

                Components.InlineActionChip {
                    visible: root.timerRunning
                    text: "Stop"
                    tone: "error"
                    onActivated: root.stopTimer()
                }

                Components.InlineActionChip {
                    visible: !root.timerRunning
                    text: "5m"
                    tone: "neutral"
                    onActivated: root.startTimer(5)
                }
            }

            Row {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                TextField {
                    id: customTimerInput
                    width: parent.width - 44
                    height: 36
                    background: Rectangle {
                        radius: ThemeModule.Theme.borderRadiusSmall
                        color: ThemeModule.Theme.card
                        border.width: 1
                        border.color: customTimerInput.activeFocus
                            ? ThemeModule.Theme.accent
                            : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.25)
                    }
                    leftPadding: ThemeModule.Theme.spacingSmall
                    rightPadding: ThemeModule.Theme.spacingSmall
                    color: ThemeModule.Theme.text
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    placeholderText: root.timerRunning ? "Reset to custom minutes" : "Custom minutes"
                    inputMethodHints: Qt.ImhDigitsOnly
                    validator: IntValidator { bottom: 1; top: 720 }
                    onAccepted: root.startCustomTimer()
                }

                Components.IconButton {
                    size: 36
                    iconSize: 16
                    iconText: "▶"
                    iconColor: ThemeModule.Theme.text
                    hoverColor: Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.16)
                    onClicked: root.startCustomTimer()
                }
            }
        }
    }
}
