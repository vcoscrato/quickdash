import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.SystemTray
import "../components" as Components
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "System Tray"
    icon: ""

    Flow {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Repeater {
            model: SystemTray.items

            delegate: Rectangle {
                id: trayDelegate
                width: 36
                height: 36
                radius: ThemeModule.Theme.borderRadiusSmall
                color: trayMouse.containsMouse ? ThemeModule.Theme.cardHover : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 20
                    height: 20
                    source: {
                        if (!modelData.icon) return "";
                        let iconStr = modelData.icon.toString();
                        
                        // Quickshell does not yet support custom icon paths and logs a warning.
                        // We strip the ?path= query to suppress the warning and allow it to fall back.
                        let pathIndex = iconStr.indexOf("?path=");
                        if (pathIndex !== -1) {
                            if (iconStr.startsWith("icon://")) {
                                iconStr = iconStr.substring(0, pathIndex);
                            } else {
                                // If no explicit scheme, it might just be the raw string
                                iconStr = iconStr.substring(0, pathIndex);
                            }
                        }
                        
                        return iconStr;
                    }
                    sourceSize: Qt.size(20, 20)
                    fillMode: Image.PreserveAspectFit
                    visible: source !== ""
                }

                Text {
                    anchors.centerIn: parent
                    text: "●"
                    font.pixelSize: 12
                    color: ThemeModule.Theme.accent
                    visible: !modelData.icon || modelData.icon === ""
                }

                ToolTip {
                    visible: trayMouse.containsMouse
                    text: modelData.tooltipTitle || modelData.title || modelData.id || ""
                    delay: 150
                }

                // Menu anchor for context menus
                QsMenuAnchor {
                    id: menuAnchor
                    menu: modelData.menu
                    anchor.item: trayDelegate
                    anchor.edges: Edges.Bottom
                    anchor.gravity: Edges.Bottom
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            if (modelData.onlyMenu && modelData.hasMenu) {
                                menuAnchor.open();
                            } else {
                                modelData.activate();
                            }
                        } else if (mouse.button === Qt.RightButton) {
                            if (modelData.hasMenu) {
                                menuAnchor.open();
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Empty state ──────────────────────
    Text {
        text: "No tray items"
        font.pixelSize: ThemeModule.Theme.fontSizeSmall
        font.family: ThemeModule.Theme.fontFamily
        color: ThemeModule.Theme.overlay
        visible: SystemTray.items.length === 0
        anchors.horizontalCenter: parent.horizontalCenter
    }
}
