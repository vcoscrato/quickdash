import QtQuick
import QtQuick.Controls
import "../theme" as ThemeModule

Slider {
    id: root

    property color trackColor: ThemeModule.Theme.surface2
    property color progressColor: ThemeModule.Theme.accent
    property color handleColor: ThemeModule.Theme.text

    from: 0
    to: 100
    stepSize: 1
    height: 32

    background: Rectangle {
        x: root.leftPadding
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: root.availableWidth
        height: 6
        radius: 3
        color: root.trackColor

        Rectangle {
            width: root.visualPosition * parent.width
            height: parent.height
            radius: 3
            color: root.progressColor

            Behavior on width {
                NumberAnimation { duration: 50 }
            }
        }
    }

    handle: Rectangle {
        x: root.leftPadding + root.visualPosition * (root.availableWidth - width)
        y: root.topPadding + root.availableHeight / 2 - height / 2
        width: 18
        height: 18
        radius: 9
        color: root.handleColor
        border.width: 2
        border.color: root.progressColor

        scale: root.pressed ? 1.15 : (hoverHandler.hovered ? 1.08 : 1.0)

        Behavior on scale {
            NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutCubic }
        }

        HoverHandler {
            id: hoverHandler
        }
    }
}
