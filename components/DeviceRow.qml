import QtQuick
import "../theme" as ThemeModule
import "." as Components

Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string leadingIcon: ""
    property int signalLevel: -1
    property bool showLock: false
    property var badges: [] // [{text:"Known", tone:"success"}]

    property bool primaryEnabled: true
    property var actionChips: [] // [{text,tone,armed,enabled,actionId}]

    property bool expanded: false
    default property alias expandedContent: expandedColumn.data

    signal primaryTriggered()
    signal actionTriggered(string actionId)

    function signalText() {
        if (signalLevel < 0) return "";
        if (signalLevel > 75) return "▂▄▆█";
        if (signalLevel > 50) return "▂▄▆░";
        if (signalLevel > 25) return "▂▄░░";
        return "▂░░░";
    }

    width: parent ? parent.width : 300
    radius: ThemeModule.Theme.borderRadiusSmall
    color: rowMouse.containsMouse
        ? ThemeModule.Theme.cardHover
        : Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.18)
    border.width: ThemeModule.Theme.borderWidth
    border.color: Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.16)
    implicitHeight: headRow.implicitHeight + (expanded ? expandedColumn.implicitHeight + ThemeModule.Theme.spacingSmall : 0) + ThemeModule.Theme.spacingSmall * 2

    MouseArea {
        id: rowMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.primaryEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.primaryEnabled) root.primaryTriggered();
        }
    }

    Column {
        z: 1
        anchors.fill: parent
        anchors.margins: ThemeModule.Theme.spacingSmall
        spacing: ThemeModule.Theme.spacingSmall

        Row {
            id: headRow
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            Text {
                text: root.leadingIcon
                font.pixelSize: ThemeModule.Theme.fontSizeLarge
                color: ThemeModule.Theme.text
                anchors.verticalCenter: parent.verticalCenter
                visible: text !== ""
            }

            Text {
                text: root.signalText()
                font.pixelSize: 10
                font.family: "monospace"
                color: ThemeModule.Theme.accent
                anchors.verticalCenter: parent.verticalCenter
                visible: root.signalLevel >= 0
            }

            Text {
                text: root.title
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                font.bold: true
                color: ThemeModule.Theme.text
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                // Take remaining space minus what the subtitle and actions need
                width: Math.max(40, parent.width - subtitleText.implicitWidth - rightActions.implicitWidth
                    - (root.leadingIcon !== "" ? ThemeModule.Theme.fontSizeLarge + ThemeModule.Theme.spacingSmall : 0)
                    - (root.signalLevel >= 0 ? 40 : 0)
                    - (root.showLock ? ThemeModule.Theme.fontSizeSmall + ThemeModule.Theme.spacingSmall : 0)
                    - ThemeModule.Theme.spacingSmall * 4)
            }

            Text {
                text: root.showLock ? "🔒" : ""
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                anchors.verticalCenter: parent.verticalCenter
                visible: root.showLock
            }

            Text {
                id: subtitleText
                text: root.subtitle
                font.pixelSize: 10
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
                anchors.verticalCenter: parent.verticalCenter
                visible: text !== ""
            }

            Item { width: 1; height: 1 }

            Row {
                id: rightActions
                spacing: ThemeModule.Theme.spacingTiny
                anchors.verticalCenter: parent.verticalCenter

                Repeater {
                    model: root.badges
                    delegate: Components.StatusBadge {
                        text: modelData.text || ""
                        tone: modelData.tone || "neutral"
                    }
                }

                Repeater {
                    model: root.actionChips
                    delegate: Components.InlineActionChip {
                        visible: true
                        text: modelData.text || ""
                        tone: modelData.tone || "neutral"
                        armed: !!modelData.armed
                        enabled: modelData.enabled !== false
                        onActivated: root.actionTriggered(modelData.actionId || "")
                    }
                }
            }
        }

        Column {
            id: expandedColumn
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: root.expanded
        }
    }

}
