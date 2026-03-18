import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "services" as Services
import "theme" as ThemeModule
import "components" as Components

PanelWindow {
    id: toastWindow
    
    // Anchor to the top right of the screen
    anchors {
        top: true
        right: true
    }
    
    margins {
        top: ThemeModule.Theme.spacingLarge
        right: ThemeModule.Theme.spacingLarge
    }

    // Transparent background, resizing to fit contents
    color: "transparent"
    implicitWidth: 350
    implicitHeight: toastColumn.height
    
    // Only show if there are active popups
    visible: Services.SystemState.activePopups.length > 0

    Column {
        id: toastColumn
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium
        
        Repeater {
            model: Services.SystemState.activePopups
            
            delegate: Rectangle {
                id: toastCard
                width: parent.width
                height: toastContent.height + (ThemeModule.Theme.spacingMedium * 2)
                radius: ThemeModule.Theme.borderRadius
                color: ThemeModule.Theme.card
                border.color: ThemeModule.Theme.cardHover
                border.width: 1
                clip: true
                
                // Add an entrance animation
                scale: 0.95
                opacity: 0
                Component.onCompleted: {
                    entranceAnim.start()
                }
                
                ParallelAnimation {
                    id: entranceAnim
                    NumberAnimation { target: toastCard; property: "scale"; to: 1.0; duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutBack }
                    NumberAnimation { target: toastCard; property: "opacity"; to: 1.0; duration: ThemeModule.Theme.animDuration }
                }

                Column {
                    id: toastContent
                    anchors {
                        left: parent.left
                        right: dismissBtn.left
                        top: parent.top
                        margins: ThemeModule.Theme.spacingMedium
                    }
                    spacing: ThemeModule.Theme.spacingSmall

                    Row {
                        spacing: ThemeModule.Theme.spacingTiny
                        
                        Text {
                            text: modelData.appName || "App"
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: ThemeModule.Theme.accent
                        }
                    }

                    Text {
                        text: modelData.summary || ""
                        font.pixelSize: ThemeModule.Theme.fontSizeNormal
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
                        maximumLineCount: 3
                        wrapMode: Text.WordWrap
                        visible: text !== ""
                    }
                }

                Components.IconButton {
                    id: dismissBtn
                    anchors.right: parent.right
                    anchors.rightMargin: ThemeModule.Theme.spacingSmall
                    anchors.top: parent.top
                    anchors.topMargin: ThemeModule.Theme.spacingSmall
                    iconText: "✕"
                    size: 24
                    iconSize: 12
                    iconColor: ThemeModule.Theme.overlay
                    onClicked: {
                        Services.SystemState.dismissPopup(modelData.popupId)
                    }
                }
            }
        }
    }
}
