import QtQuick
import Quickshell.Services.Notifications
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Notifications" + (notifList.length > 0 ? " (" + notifList.length + ")" : "")
    icon: "🔔"
    collapsible: true
    headerActions: Components.TogglePill {
        iconText: "🔕"
        label: "DND"
        checked: root.dndEnabled
        activeColor: ThemeModule.Theme.peach
        onToggled: function(state) {
            root.setDnd(state);
        }
    }

    property bool dndEnabled: Services.SystemState.dndEnabled
    property var notifList: Services.SystemState.notificationHistory

    function setDnd(state) {
        Services.SystemState.dndEnabled = state;
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        // ── Clear all button ─────────────────
        Rectangle {
            width: parent.width
            height: 24
            color: "transparent"
            visible: root.notifList.length > 0

            Text {
                anchors.right: parent.right
                text: "Clear all"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Services.SystemState.clearHistory()
                }
            }
        }

        // ── Notification list ────────────────
        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingTiny

            Repeater {
                model: dashboard.activePanel === "notificationCenter" ? root.notifList : root.notifList.slice(0, 3)

                delegate: Rectangle {
                    width: parent.width
                    height: notifContent.height + ThemeModule.Theme.spacingMedium
                    radius: ThemeModule.Theme.borderRadiusSmall
                    color: notifMouse.containsMouse ? ThemeModule.Theme.cardHover : Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.3)

                    Column {
                        id: notifContent
                        anchors {
                            left: parent.left
                            right: dismissBtn.left
                            top: parent.top
                            margins: ThemeModule.Theme.spacingSmall
                        }
                        spacing: 2

                        Row {
                            spacing: ThemeModule.Theme.spacingTiny

                            Text {
                                text: modelData.appName || "App"
                                font.pixelSize: 10
                                font.family: ThemeModule.Theme.fontFamily
                                font.bold: true
                                color: ThemeModule.Theme.accent
                            }
                            Text {
                                // refreshTick dependency forces periodic re-evaluation
                                text: "· " + root.formatTimeAgo(modelData.time, Services.SystemState.refreshTick)
                                font.pixelSize: 10
                                font.family: ThemeModule.Theme.fontFamily
                                color: ThemeModule.Theme.overlay
                            }
                        }

                        Text {
                            text: modelData.summary || ""
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: ThemeModule.Theme.text
                            width: parent.width
                            elide: Text.ElideRight
                            visible: text !== ""
                        }

                        Text {
                            text: modelData.body || ""
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.subtext
                            width: parent.width
                            elide: Text.ElideRight
                            maximumLineCount: 2
                            wrapMode: Text.WordWrap
                            visible: text !== ""
                        }
                    }

                    Components.IconButton {
                        id: dismissBtn
                        anchors.right: parent.right
                        anchors.rightMargin: ThemeModule.Theme.spacingTiny
                        anchors.top: parent.top
                        anchors.topMargin: ThemeModule.Theme.spacingTiny
                        iconText: "✕"
                        size: 22
                        iconSize: 10
                        iconColor: ThemeModule.Theme.overlay
                        onClicked: Services.SystemState.removeHistoryAt(index)
                    }

                    MouseArea {
                        id: notifMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }
                }
            }
        }

        // ── Empty state ──────────────────────
        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.notifList.length === 0

            Text {
                text: "🔔"
                font.pixelSize: 24
                anchors.horizontalCenter: parent.horizontalCenter
                opacity: 0.5
            }
            Text {
                text: "No notifications"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.overlay
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    function formatTimeAgo(date, tick) {
        // 'tick' parameter is unused but creates a QML binding dependency
        // that forces periodic re-evaluation of the time-ago string.
        if (!date) return "";
        var now = new Date();
        var diff = Math.floor((now - date) / 1000);
        if (diff < 60) return "just now";
        if (diff < 3600) return Math.floor(diff / 60) + "m ago";
        if (diff < 86400) return Math.floor(diff / 3600) + "h ago";
        return Math.floor(diff / 86400) + "d ago";
    }
}
