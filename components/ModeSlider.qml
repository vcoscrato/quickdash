import QtQuick
import "../theme" as ThemeModule

Rectangle {
    id: root

    property string leftLabel: "Left"
    property string rightLabel: "Right"
    property int selectedIndex: 0 // 0=left, 1=right
    property color activeColor: ThemeModule.Theme.accent

    signal changed(int index)

    width: 132
    height: 28
    radius: height / 2
    color: Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.35)
    border.width: ThemeModule.Theme.borderWidth
    border.color: Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.4)

    Rectangle {
        id: knob
        width: (root.width - 6) / 2
        height: root.height - 6
        radius: height / 2
        x: root.selectedIndex === 0 ? 3 : root.width - width - 3
        y: 3
        color: Qt.rgba(root.activeColor.r, root.activeColor.g, root.activeColor.b, 0.26)
        border.width: ThemeModule.Theme.borderWidth
        border.color: Qt.rgba(root.activeColor.r, root.activeColor.g, root.activeColor.b, 0.7)

        Behavior on x {
            NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutCubic }
        }
    }

    Row {
        anchors.fill: parent

        Rectangle {
            width: parent.width / 2
            height: parent.height
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: root.leftLabel
                font.pixelSize: 10
                font.family: ThemeModule.Theme.fontFamily
                font.bold: root.selectedIndex === 0
                color: root.selectedIndex === 0 ? ThemeModule.Theme.text : ThemeModule.Theme.subtext
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.selectedIndex !== 0) {
                        root.selectedIndex = 0;
                        root.changed(0);
                    }
                }
            }
        }

        Rectangle {
            width: parent.width / 2
            height: parent.height
            color: "transparent"

            Text {
                anchors.centerIn: parent
                text: root.rightLabel
                font.pixelSize: 10
                font.family: ThemeModule.Theme.fontFamily
                font.bold: root.selectedIndex === 1
                color: root.selectedIndex === 1 ? ThemeModule.Theme.text : ThemeModule.Theme.subtext
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.selectedIndex !== 1) {
                        root.selectedIndex = 1;
                        root.changed(1);
                    }
                }
            }
        }
    }
}
