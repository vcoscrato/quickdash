import QtQuick
import Quickshell
import Quickshell.Io
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Config"
    icon: "⚙"

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium

        // ── Config file path ──
        Column {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            Text {
                text: "Config file"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
                color: ThemeModule.Theme.text
            }

            Text {
                width: parent.width
                text: Services.SystemState.configPath !== ""
                      ? Services.SystemState.configPath
                    : "~/.config/quickdash/config.jsonc"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
                wrapMode: Text.WrapAnywhere
            }
        }

        // ── Action buttons ──
        Row {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            // Open in $VISUAL / $EDITOR / xdg-open
            Rectangle {
                width: (parent.width - ThemeModule.Theme.spacingSmall) / 2
                height: 34
                radius: ThemeModule.Theme.borderRadiusSmall
                color: openArea.containsMouse
                       ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.16)
                       : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.15)
                border.width: 1
                border.color: openArea.containsMouse ? ThemeModule.Theme.accent : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "Open"
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: openArea.containsMouse ? ThemeModule.Theme.accent : ThemeModule.Theme.text
                }

                MouseArea {
                    id: openArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        var p = Services.SystemState.configPath !== ""
                                ? Services.SystemState.configPath
                                : "~/.config/quickdash/config.jsonc";
                        openProc.command = [
                            "sh", "-c",
                            "${VISUAL:-${EDITOR:-xdg-open}} " + root.shellQuote(p)
                        ];
                        openProc.running = true;
                    }
                }
            }

            // Reload — triggers a full QML context reload
            Rectangle {
                width: (parent.width - ThemeModule.Theme.spacingSmall) / 2
                height: 34
                radius: ThemeModule.Theme.borderRadiusSmall
                color: reloadArea.containsMouse
                       ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.16)
                       : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.15)
                border.width: 1
                border.color: reloadArea.containsMouse ? ThemeModule.Theme.accent : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "Reload"
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: reloadArea.containsMouse ? ThemeModule.Theme.accent : ThemeModule.Theme.text
                }

                MouseArea {
                    id: reloadArea
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: Quickshell.reload(false)
                }
            }
        }
    }

    Process {
        id: openProc
        running: false
    }
}

