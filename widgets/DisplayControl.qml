import QtQuick
import Quickshell.Io
import "../components" as Components
import "../theme" as ThemeModule
import "../services" as Services

Components.Card {
    id: root
    title: "Displays"
    icon: "🖥"

    property bool dashboardActive: true

    onDashboardActiveChanged: {
        if (root.dashboardActive) {
            Services.DisplayService.refresh();
        }
    }

    headerActions: Components.TogglePill {
        visible: Services.DisplayService.hasMultipleMonitors
        iconText: "🖵"
        label: Services.DisplayService.isMirrored ? "Mirrored" : "Extended"
        checked: Services.DisplayService.isMirrored
        activeColor: ThemeModule.Theme.accent
        onToggled: function(state) {
            Services.DisplayService.setMirrorMode(state);
        }
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium

        Row {
            width: parent.width
            spacing: ThemeModule.Theme.spacingMedium

            Text {
                text: !Services.DisplayService.hasMultipleMonitors
                    ? "Only one display is connected."
                    : (Services.DisplayService.isMirrored 
                        ? "Your secondary monitor is mirroring the primary display." 
                        : "Your secondary monitor is extending your workspace.")
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
                width: parent.width
                wrapMode: Text.WordWrap
            }
        }
    }
}
