import QtQuick
import "../theme" as ThemeModule

Rectangle {
    id: root

    property string text: ""
    property string tone: "neutral" // neutral | success | warning | error | info
    property bool armed: false

    signal activated()
    function toneColor() {
        return ThemeModule.Theme.toneColor(root.tone);
    }

    radius: 11
    height: 22
    width: chipText.width + 16
    opacity: enabled ? 1.0 : 0.45
    color: chipMouse.containsMouse
        ? Qt.rgba(toneColor().r, toneColor().g, toneColor().b, armed ? 0.32 : 0.24)
        : Qt.rgba(toneColor().r, toneColor().g, toneColor().b, armed ? 0.24 : 0.12)
    border.width: ThemeModule.Theme.borderWidth
    border.color: Qt.rgba(toneColor().r, toneColor().g, toneColor().b, armed ? 0.85 : 0.45)

    Behavior on color {
        ColorAnimation { duration: ThemeModule.Theme.animDuration }
    }
    Behavior on border.color {
        ColorAnimation { duration: ThemeModule.Theme.animDuration }
    }

    Text {
        id: chipText
        anchors.centerIn: parent
        text: root.text
        font.pixelSize: 10
        font.family: ThemeModule.Theme.fontFamily
        font.bold: true
        color: root.toneColor()
    }

    MouseArea {
        id: chipMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            root.activated();
        }
    }
}
