import QtQuick
import QtQuick.Controls
import "../services" as Services
import "../components" as Components
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Clipboard History"
    icon: "📋"

    property bool dashboardActive: true

    onDashboardActiveChanged: {
        if (dashboardActive) Services.ClipboardService.refresh();
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Repeater {
            model: Services.ClipboardService.history
            delegate: Rectangle {
                width: parent.width
                height: Math.max(30, previewText.implicitHeight + 10)
                radius: ThemeModule.Theme.borderRadiusSmall
                color: clipMouse.containsMouse ? ThemeModule.Theme.cardHover : "transparent"
                border.width: 1
                border.color: ThemeModule.Theme.surface2

                Text {
                    id: previewText
                    anchors.fill: parent
                    anchors.margins: 5
                    text: modelData.preview
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.text
                    elide: Text.ElideRight
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                }

                MouseArea {
                    id: clipMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    ToolTip.visible: containsMouse
                    ToolTip.text: "Copy"
                    ToolTip.delay: 500
                    onClicked: {
                        Services.ClipboardService.decodeAndCopy(modelData.id);
                        dashboard.activePanel = ""; // Close panel
                    }
                }
            }
        }

        Text {
            width: parent.width
            text: "No clipboard history found."
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.subtext
            horizontalAlignment: Text.AlignHCenter
            visible: Services.ClipboardService.history.length === 0
        }
    }
}
