import QtQuick
import QtQuick.Controls
import "../theme" as ThemeModule

Rectangle {
    id: root

    property string widgetName: ""
    property string iconText: ""
    property bool active: false
    property string statusText: ""
    property string microStatus: ""

    signal activated(string name)
    signal wheelDelta(int angleDelta)

    width: parent ? parent.width : ThemeModule.Theme.sidebarIconSize
    height: ThemeModule.Theme.sidebarIconSize
    radius: 0
    color: active ? ThemeModule.Theme.surface2 : (mouseArea.containsMouse ? ThemeModule.Theme.cardHover : "transparent")

    Column {
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            width: parent.width
            text: root.iconText
            font.pixelSize: 18
            color: root.active ? ThemeModule.Theme.accent : (mouseArea.containsMouse ? ThemeModule.Theme.text : ThemeModule.Theme.subtext)
            horizontalAlignment: Text.AlignHCenter
        }

        Text {
            width: parent.width
            text: root.microStatus
            font.pixelSize: 9
            font.family: ThemeModule.Theme.fontFamily
            font.bold: true
            color: root.active ? ThemeModule.Theme.accent : ThemeModule.Theme.overlay
            horizontalAlignment: Text.AlignHCenter
            visible: root.microStatus !== ""
        }
    }

    ToolTip {
        visible: mouseArea.containsMouse && root.statusText !== ""
        text: root.statusText
        delay: 150
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated(root.widgetName)
        onWheel: function(wheel) {
            root.wheelDelta(wheel.angleDelta.y)
        }
    }
}
