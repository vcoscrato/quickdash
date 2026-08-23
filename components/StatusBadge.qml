import QtQuick
import "../theme" as ThemeModule

Rectangle {
    id: root

    property string text: ""
    property string tone: "neutral" // neutral | success | warning | error | info

    function toneColor() {
        return ThemeModule.Theme.toneColor(root.tone);
    }

    radius: height / 2
    implicitHeight: Math.max(18, badgeText.implicitHeight + ThemeModule.Theme.spacingTiny)
    height: implicitHeight
    width: badgeText.width + 14
    color: Qt.rgba(toneColor().r, toneColor().g, toneColor().b, 0.18)
    border.width: ThemeModule.Theme.borderWidth
    border.color: Qt.rgba(toneColor().r, toneColor().g, toneColor().b, 0.45)

    Text {
        id: badgeText
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: ThemeModule.Theme.fontSizeCaption
        font.family: ThemeModule.Theme.fontFamily
        font.bold: true
        color: root.toneColor()
    }
}
