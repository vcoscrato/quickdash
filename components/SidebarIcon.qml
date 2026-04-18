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
    radius: ThemeModule.Theme.borderRadiusSmall
    color: active ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.15) : (mouseArea.containsMouse ? ThemeModule.Theme.cardHover : "transparent")

    Behavior on color {
        ColorAnimation { duration: ThemeModule.Theme.animDuration }
    }

    // Left accent bar when active
    Rectangle {
        width: 3
        height: parent.height * 0.6
        radius: 1.5
        color: ThemeModule.Theme.accent
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        visible: root.active

        // Entrance animation for the bar
        scale: root.active ? 1.0 : 0.0
        Behavior on scale {
            NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutBack }
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 2

        Text {
            text: root.iconText
            font.pixelSize: 18
            color: root.active ? ThemeModule.Theme.accent : (mouseArea.containsMouse ? ThemeModule.Theme.text : ThemeModule.Theme.subtext)
            anchors.horizontalCenter: parent.horizontalCenter

            Behavior on color {
                ColorAnimation { duration: ThemeModule.Theme.animDuration }
            }
        }

        Text {
            text: root.microStatus
            font.pixelSize: 9
            font.family: ThemeModule.Theme.fontFamily
            font.bold: true
            color: root.active ? ThemeModule.Theme.accent : ThemeModule.Theme.overlay
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.microStatus !== ""
            
            Behavior on color {
                ColorAnimation { duration: ThemeModule.Theme.animDuration }
            }
        }
    }

    ToolTip {
        visible: mouseArea.containsMouse && root.statusText !== ""
        text: root.statusText
        delay: 500
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
