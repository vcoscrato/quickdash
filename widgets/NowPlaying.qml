pragma ComponentBehavior: Bound
import QtQuick
import Quickshell.Services.Mpris
import "../components" as Components
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: ""
    property bool dashboardActive: true

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

    Component.onCompleted: {
        root.syncDisplayedPosition();
    }

    function syncDisplayedPosition() {
        root.displayedPosition = root.player ? Number(root.player.position) || 0 : 0;
    }

    onPlayerChanged: root.syncDisplayedPosition()

    onDashboardActiveChanged: {
        if (root.dashboardActive) {
            root.syncDisplayedPosition();
        }
    }

    Timer {
        id: progressTimer
        interval: 1000
        repeat: true
        triggeredOnStart: true
        running: root.dashboardActive
            && root.player !== null
            && root.player.playbackState === MprisPlaybackState.Playing
        onTriggered: root.syncDisplayedPosition()
    }

    // Show the widget: if we have a player show controls,
    // otherwise show a "waiting" message so user can see the widget is alive
    visible: true

    // ── No player fallback ───────────────────
    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall
        visible: !root.hasPlayer

        Text {
            text: "🎵"
            font.pixelSize: 24
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0.5
        }
        Text {
            text: "No media playing"
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.overlay
            anchors.horizontalCenter: parent.horizontalCenter
        }
        Text {
            text: "Play something in a browser or media player"
            font.pixelSize: 10
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.overlay
            anchors.horizontalCenter: parent.horizontalCenter
            opacity: 0.6
        }
    }

    // ── Player content ───────────────────────
    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall
        visible: root.hasPlayer

        Row {
            width: parent.width
            spacing: ThemeModule.Theme.spacingMedium

            // ── Album art ────────────────────────
            Rectangle {
                id: albumArtContainer
                width: 80
                height: 80
                radius: ThemeModule.Theme.borderRadiusSmall
                color: ThemeModule.Theme.surface2
                clip: true

                Image {
                    anchors.fill: parent
                    source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                    fillMode: Image.PreserveAspectCrop
                    visible: source !== ""
                }

                // Fallback icon
                Text {
                    anchors.centerIn: parent
                    text: "🎵"
                    font.pixelSize: 32
                    visible: !root.player || !root.player.trackArtUrl || root.player.trackArtUrl === ""
                }
            }

            // ── Track info + controls ────────────
            Column {
                width: parent.width - 80 - ThemeModule.Theme.spacingMedium
                spacing: ThemeModule.Theme.spacingTiny

                // Title
                Text {
                    text: root.player ? (root.player.trackTitle || "No Track") : "No Track"
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    font.bold: true
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.text
                    width: parent.width
                    elide: Text.ElideRight
                }

                // Artist
                Text {
                    text: root.player ? (root.player.trackArtist || "") : ""
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.subtext
                    width: parent.width
                    elide: Text.ElideRight
                }

                // Album
                Text {
                    text: root.player ? (root.player.trackAlbum || "") : ""
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.overlay
                    width: parent.width
                    elide: Text.ElideRight
                    visible: text !== ""
                }

                Item { width: 1; height: ThemeModule.Theme.spacingTiny }

                // ── Playback controls ────────────
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: ThemeModule.Theme.spacingMedium

                    Components.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        iconText: "⏮"
                        iconSize: ThemeModule.Theme.fontSizeLarge
                        onClicked: { if (root.player) root.player.previous() }
                    }

                    Components.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        iconText: root.player && root.player.playbackState === MprisPlaybackState.Playing ? "⏸" : "▶"
                        iconSize: ThemeModule.Theme.fontSizeXL
                        size: 44
                        iconColor: ThemeModule.Theme.accent
                        iconXOffset: (root.player && root.player.playbackState === MprisPlaybackState.Playing) ? 0 : 2
                        onClicked: {
                            if (root.player) root.player.togglePlaying()
                        }
                    }

                    Components.IconButton {
                        anchors.verticalCenter: parent.verticalCenter
                        iconText: "⏭"
                        iconSize: ThemeModule.Theme.fontSizeLarge
                        onClicked: { if (root.player) root.player.next() }
                    }
                }
            }
        }

        // ── Progress bar ─────────────────────────
        Column {
            width: parent.width
            spacing: 2
            visible: root.player && root.player.length > 0

            Rectangle {
                width: parent.width
                height: 4
                radius: 2
                color: ThemeModule.Theme.surface2

                Rectangle {
                    width: (root.player && root.player.length > 0)
                        ? (root.displayedPosition / root.player.length) * parent.width
                        : 0
                    height: parent.height
                    radius: 2
                    color: ThemeModule.Theme.accent
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: function(mouse) {
                        if (root.player && root.player.length > 0) {
                            var ratio = mouse.x / parent.width;
                            root.displayedPosition = ratio * root.player.length;
                            root.player.position = root.displayedPosition;
                        }
                    }
                }
            }

            Row {
                width: parent.width

                Text {
                    id: elapsedText
                    text: root.player ? root.formatTime(root.displayedPosition) : "0:00"
                    font.pixelSize: 10
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.overlay
                }

                Item {
                    width: Math.max(0, parent.width - elapsedText.width - totalText.width)
                    height: 1
                }

                Text {
                    id: totalText
                    text: root.player ? root.formatTime(root.player.length) : "0:00"
                    font.pixelSize: 10
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.overlay
                }
            }
        }
    }

    function formatTime(ms) {
        if (!ms || ms <= 0) return "0:00";
        var totalSec = Math.floor(ms / 1000000); // MPRIS uses microseconds
        var min = Math.floor(totalSec / 60);
        var sec = totalSec % 60;
        return min + ":" + (sec < 10 ? "0" : "") + sec;
    }
}
