import QtQuick
import "../components" as Components
import "../theme" as ThemeModule
import "../services" as Services

Components.Card {
    id: root
    title: "System Monitor"
    icon: "📊"

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium

        // CPU Bar
        Column {
            width: parent.width
            spacing: 2
            Row {
                width: parent.width
                Text { text: "CPU"; font.pixelSize: ThemeModule.Theme.fontSizeSmall; font.family: ThemeModule.Theme.fontFamily; color: ThemeModule.Theme.text }
                Item { width: Math.max(0, parent.width - parent.children[0].width - parent.children[2].width); height: 1 }
                Text { text: Math.round(Services.SystemMonitorService.cpuPercent) + "%"; font.pixelSize: ThemeModule.Theme.fontSizeSmall; font.family: ThemeModule.Theme.fontFamily; color: ThemeModule.Theme.subtext }
            }
            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: ThemeModule.Theme.surface2
                Rectangle {
                    width: (Services.SystemMonitorService.cpuPercent / 100) * parent.width
                    height: parent.height
                    radius: 3
                    color: ThemeModule.Theme.accent
                    Behavior on width { NumberAnimation { duration: ThemeModule.Theme.animDurationSlow } }
                    Behavior on color { ColorAnimation { duration: ThemeModule.Theme.animDurationSlow } }
                }
            }
        }

        // RAM Bar
        Column {
            width: parent.width
            spacing: 2
            Row {
                width: parent.width
                Text { text: "RAM"; font.pixelSize: ThemeModule.Theme.fontSizeSmall; font.family: ThemeModule.Theme.fontFamily; color: ThemeModule.Theme.text }
                Item { width: Math.max(0, parent.width - parent.children[0].width - parent.children[2].width); height: 1 }
                Text { text: Services.SystemMonitorService.ramUsedStr + " / " + Services.SystemMonitorService.ramTotalStr; font.pixelSize: ThemeModule.Theme.fontSizeSmall; font.family: ThemeModule.Theme.fontFamily; color: ThemeModule.Theme.subtext }
            }
            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: ThemeModule.Theme.surface2
                Rectangle {
                    width: (Services.SystemMonitorService.ramPercent / 100) * parent.width
                    height: parent.height
                    radius: 3
                    color: ThemeModule.Theme.accent
                    Behavior on width { NumberAnimation { duration: ThemeModule.Theme.animDurationSlow } }
                    Behavior on color { ColorAnimation { duration: ThemeModule.Theme.animDurationSlow } }
                }
            }
        }

        // GPU Bar
        Column {
            width: parent.width
            spacing: 2
            Row {
                width: parent.width
                Text { text: "GPU"; font.pixelSize: ThemeModule.Theme.fontSizeSmall; font.family: ThemeModule.Theme.fontFamily; color: ThemeModule.Theme.text }
                Item { width: Math.max(0, parent.width - parent.children[0].width - parent.children[2].width); height: 1 }
                Text { text: Math.round(Services.SystemMonitorService.gpuPercent) + "%"; font.pixelSize: ThemeModule.Theme.fontSizeSmall; font.family: ThemeModule.Theme.fontFamily; color: ThemeModule.Theme.subtext }
            }
            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: ThemeModule.Theme.surface2
                Rectangle {
                    width: (Services.SystemMonitorService.gpuPercent / 100) * parent.width
                    height: parent.height
                    radius: 3
                    color: ThemeModule.Theme.accent
                    Behavior on width { NumberAnimation { duration: ThemeModule.Theme.animDurationSlow } }
                    Behavior on color { ColorAnimation { duration: ThemeModule.Theme.animDurationSlow } }
                }
            }
        }

        // VRAM Bar
        Column {
            width: parent.width
            spacing: 2
            Row {
                width: parent.width
                Text { text: "VRAM"; font.pixelSize: ThemeModule.Theme.fontSizeSmall; font.family: ThemeModule.Theme.fontFamily; color: ThemeModule.Theme.text }
                Item { width: Math.max(0, parent.width - parent.children[0].width - parent.children[2].width); height: 1 }
                Text { text: Services.SystemMonitorService.gpuRamUsedStr + " / " + Services.SystemMonitorService.gpuRamTotalStr; font.pixelSize: ThemeModule.Theme.fontSizeSmall; font.family: ThemeModule.Theme.fontFamily; color: ThemeModule.Theme.subtext }
            }
            Rectangle {
                width: parent.width
                height: 6
                radius: 3
                color: ThemeModule.Theme.surface2
                Rectangle {
                    width: (Services.SystemMonitorService.gpuRamPercent / 100) * parent.width
                    height: parent.height
                    radius: 3
                    color: ThemeModule.Theme.accent
                    Behavior on width { NumberAnimation { duration: ThemeModule.Theme.animDurationSlow } }
                    Behavior on color { ColorAnimation { duration: ThemeModule.Theme.animDurationSlow } }
                }
            }
        }

        // Temp and Uptime
        Row {
            width: parent.width
            spacing: ThemeModule.Theme.spacingMedium
            
            Text {
                text: "🌡 " + Services.SystemMonitorService.cpuTempC + "°C"
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.text
            }
            
            Item { width: 1; height: 10; Rectangle { anchors.centerIn: parent; width: 4; height: 4; radius: 2; color: ThemeModule.Theme.overlay } }
            
            Text {
                text: "Up " + Services.SystemMonitorService.uptimeStr
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                color: ThemeModule.Theme.subtext
            }
        }
    }
}
