import QtQuick
import "../theme" as ThemeModule
import "." as Components

Item {
    id: root

    property string title: ""
    property string icon: ""
    default property alias headerActions: actionsRow.data

    signal closed()

    width: parent.width
    height: Math.max(28, leftRow.height, rightRow.height)

    Row {
        id: leftRow
        spacing: ThemeModule.Theme.spacingSmall
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: root.icon
            font.pixelSize: ThemeModule.Theme.fontSizeLarge
            color: ThemeModule.Theme.accent
            visible: root.icon !== ""
        }

        Text {
            text: root.title
            font.pixelSize: ThemeModule.Theme.fontSizeNormal
            font.bold: true
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.text
        }
    }

    Row {
        id: rightRow
        spacing: ThemeModule.Theme.spacingSmall
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        Row {
            id: actionsRow
            spacing: ThemeModule.Theme.spacingSmall
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
