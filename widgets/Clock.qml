import QtQuick
import "../components" as Components
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: ""
    property bool dashboardActive: true

    property string timeString: ""
    property string dateString: ""

    function refreshTime() {
        var now = new Date();
        root.timeString = Qt.formatTime(now, "HH:mm");
        root.dateString = Qt.formatDate(now, "dddd, MMMM d");
    }

    function scheduleNextTick() {
        clockTimer.stop();
        if (!root.dashboardActive)
            return;

        var now = new Date();
        var nextMinute = new Date(now.getTime());
        nextMinute.setSeconds(0);
        nextMinute.setMilliseconds(0);
        nextMinute.setMinutes(nextMinute.getMinutes() + 1);
        clockTimer.interval = Math.max(250, nextMinute.getTime() - now.getTime());
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
            root.refreshTime();
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

        Text {
            text: root.timeString
            font.pixelSize: ThemeModule.Theme.fontSizeHuge
            font.bold: true
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.text
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.dateString
            font.pixelSize: ThemeModule.Theme.fontSizeNormal
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.subtext
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
