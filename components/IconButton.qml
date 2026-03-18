import QtQuick
import "../theme" as ThemeModule

Rectangle {
    id: root

    property string iconText: ""
    property int iconSize: ThemeModule.Theme.fontSizeLarge
    property color iconColor: ThemeModule.Theme.text
    property color hoverColor: ThemeModule.Theme.cardHover
    property real size: 36
    property real iconXOffset: 0
    property real iconYOffset: 0

    signal clicked()

    width: size
    height: size
    radius: size / 2
    color: mouseArea.containsMouse
        ? (mouseArea.pressed ? ThemeModule.Theme.surface2 : root.hoverColor)
        : "transparent"

    Behavior on color {
        ColorAnimation { duration: ThemeModule.Theme.animDuration }
    }

    Text {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.iconXOffset
        anchors.verticalCenterOffset: root.iconYOffset
        text: root.iconText
        font.pixelSize: root.iconSize
        color: root.iconColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter

        scale: mouseArea.pressed ? 0.85 : 1.0
        Behavior on scale {
            NumberAnimation { duration: 100; easing.type: Easing.OutCubic }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true
        onClicked: root.clicked()
    }
}
