import QtQuick
import QtQuick.Controls
import "../services" as Services
import "../theme" as ThemeModule

Item {
    id: root
    width: parent ? parent.width : 300
    height: 32
    property bool dashboardActive: true

    Text {
        anchors.centerIn: parent
        text: Services.WeatherService.currentWeatherStr
        font.pixelSize: ThemeModule.Theme.fontSizeNormal
        font.family: ThemeModule.Theme.fontFamily
        color: ThemeModule.Theme.subtext
        
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Services.WeatherService.fetchWeather()
            hoverEnabled: true
            ToolTip.visible: containsMouse
            ToolTip.text: "Click to refresh"
            ToolTip.delay: 500
        }
    }
}
