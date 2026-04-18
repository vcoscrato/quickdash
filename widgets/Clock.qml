import QtQuick
import "../components" as Components
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: ""
    property bool dashboardActive: true

    property string timeString: ""
    property string dateString: ""
    property string greeting: ""
    property bool showColon: true

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

    onDashboardActiveChanged: {
        if (root.dashboardActive)
            root.refreshTime();
        root.scheduleNextTick();
    }

    Column {
        width: parent.width
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

        Text {
            text: root.greeting
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.subtext
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
