pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Mpris
import "../theme" as ThemeModule
import "../components" as Components

Rectangle {
    id: root
    
    property bool dashboardActive: true
    signal clicked()

    readonly property var playersList: {
        if (!root.dashboardActive || !Mpris.players || !Mpris.players.values)
            return [];
        return Mpris.players.values;
    }
    readonly property var player: {
        for (var i = 0; i < root.playersList.length; i++) {
            if (root.playersList[i])
                return root.playersList[i];
        }
        return null;
    }
    readonly property bool hasPlayer: root.player !== null

    property real displayedPosition: 0

    function syncDisplayedPosition() {
        root.displayedPosition = root.player ? Number(root.player.position) || 0 : 0;
    }

    onPlayerChanged: root.syncDisplayedPosition()
    onDashboardActiveChanged: {
        if (root.dashboardActive) root.syncDisplayedPosition();
    }

    Timer {
        id: progressTimer
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.dashboardActive && root.player !== null && root.player.playbackState === MprisPlaybackState.Playing
        onTriggered: root.syncDisplayedPosition()
    }

    width: parent.width
    height: root.hasPlayer ? ThemeModule.Theme.miniPlayerHeight : 0
    radius: ThemeModule.Theme.borderRadiusSmall
    color: miniPlayerMouse.containsMouse ? ThemeModule.Theme.cardHover : ThemeModule.Theme.card
    border.color: ThemeModule.Theme.surface2
    border.width: 1
    clip: true
    opacity: root.hasPlayer ? 1.0 : 0.0

    Behavior on height {
        NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutCubic }
    }
    Behavior on opacity {
        NumberAnimation { duration: ThemeModule.Theme.animDuration }
    }
    Behavior on color {
        ColorAnimation { duration: ThemeModule.Theme.animDuration }
    }

    Row {
        anchors.fill: parent
        anchors.margins: ThemeModule.Theme.spacingSmall
        spacing: ThemeModule.Theme.spacingSmall
        visible: root.hasPlayer

        Text {
            text: root.player && root.player.playbackState === MprisPlaybackState.Playing ? "⏸" : "▶"
            font.pixelSize: ThemeModule.Theme.fontSizeNormal
            color: ThemeModule.Theme.accent
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            text: root.player ? ((root.player.trackTitle || "No Track") + (root.player.trackArtist ? " · " + root.player.trackArtist : "")) : ""
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            font.bold: true
            color: ThemeModule.Theme.text
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - 32 - (progressRect.width + ThemeModule.Theme.spacingSmall)
            elide: Text.ElideRight
        }

        // Mini progress bar
        Rectangle {
            id: progressRect
            width: 40
            height: 4
            radius: 2
            color: ThemeModule.Theme.surface2
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: (root.player && root.player.length > 0) ? (root.displayedPosition / root.player.length) * parent.width : 0
                height: parent.height
                radius: 2
                color: ThemeModule.Theme.accent
            }
        }
    }

    MouseArea {
        id: miniPlayerMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
