import QtQuick
import "../theme" as ThemeModule

Item {
    id: root

    property string title: ""
    property int count: 0
    property bool expanded: true

    width: parent ? parent.width : 300
    implicitHeight: Math.max(22, sectionRow.implicitHeight + ThemeModule.Theme.spacingTiny)
    height: implicitHeight

    Row {
        id: sectionRow

        anchors.verticalCenter: parent.verticalCenter
        spacing: ThemeModule.Theme.spacingSmall

        Text {
            text: root.title
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            font.bold: true
            color: ThemeModule.Theme.subtext
        }

        Rectangle {
            radius: ThemeModule.Theme.borderRadiusSmall
            height: Math.max(16, countText.implicitHeight + ThemeModule.Theme.spacingTiny)
            width: countText.width + 10
            color: Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.2)

            Text {
                id: countText
                anchors.centerIn: parent
                text: root.count
                font.pixelSize: ThemeModule.Theme.fontSizeMicro
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.14)
    }
}
