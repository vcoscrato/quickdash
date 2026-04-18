import QtQuick
import QtQuick.Controls
import "../components" as Components
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Config"
    icon: "⚙"

    Flow {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Repeater {
            model: Object.keys(ThemeModule.Palettes.palettes)
            delegate: Rectangle {
                width: 32
                height: 32
                radius: 16
                color: ThemeModule.Palettes.palettes[modelData].bg
                border.width: ThemeModule.Theme.paletteName === modelData ? 2 : 1
                border.color: ThemeModule.Theme.paletteName === modelData ? ThemeModule.Theme.accent : ThemeModule.Theme.overlay

                Rectangle {
                    anchors.centerIn: parent
                    width: 16
                    height: 16
                    radius: 8
                    color: ThemeModule.Palettes.palettes[modelData].blue || ThemeModule.Palettes.palettes[modelData].text
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    ToolTip.visible: containsMouse
                    ToolTip.text: modelData
                    ToolTip.delay: 500
                    onClicked: {
                        ThemeModule.Theme.paletteName = modelData;
                    }
                }
            }
        }
    }
}
