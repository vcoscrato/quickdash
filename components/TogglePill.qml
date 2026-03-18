import QtQuick
import "../theme" as ThemeModule

Rectangle {
    id: root

    property bool checked: false
    property string label: ""
    property string iconText: ""
    property color activeColor: ThemeModule.Theme.accent

    signal toggled(bool newState)

    width: pillRow.width + ThemeModule.Theme.spacingLarge * 2
    height: 36
    radius: height / 2
    color: checked
        ? Qt.rgba(activeColor.r, activeColor.g, activeColor.b, 0.25)
        : ThemeModule.Theme.card
    border.width: ThemeModule.Theme.borderWidth
    border.color: checked
        ? activeColor
        : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.2)

    Behavior on color {
        ColorAnimation { duration: ThemeModule.Theme.animDuration }
    }
    Behavior on border.color {
        ColorAnimation { duration: ThemeModule.Theme.animDuration }
    }

    Row {
        id: pillRow
        anchors.centerIn: parent
        spacing: ThemeModule.Theme.spacingTiny

        Text {
            text: root.iconText
            font.pixelSize: ThemeModule.Theme.fontSizeNormal
            color: root.checked ? root.activeColor : ThemeModule.Theme.subtext
            anchors.verticalCenter: parent.verticalCenter
            visible: root.iconText !== ""

            Behavior on color {
                ColorAnimation { duration: ThemeModule.Theme.animDuration }
            }
        }

        Text {
            text: root.label
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            font.bold: true
            color: root.checked ? root.activeColor : ThemeModule.Theme.subtext
            anchors.verticalCenter: parent.verticalCenter

            Behavior on color {
                ColorAnimation { duration: ThemeModule.Theme.animDuration }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onClicked: {
            root.checked = !root.checked
            root.toggled(root.checked)
        }

        onContainsMouseChanged: {
            if (!root.checked) {
                root.color = containsMouse
                    ? ThemeModule.Theme.cardHover
                    : ThemeModule.Theme.card
            }
        }
    }
}
