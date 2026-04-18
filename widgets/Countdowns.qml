import QtQuick
import "../components" as Components
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Countdowns"
    icon: "⏳"
    
    property var countdownsList: dashboard && dashboard.config && dashboard.config.countdowns ? dashboard.config.countdowns : []
    
    visible: countdownsList.length > 0
    
    function daysUntil(dateStr) {
        var target = new Date(dateStr);
        var now = new Date();
        target.setHours(0, 0, 0, 0);
        now.setHours(0, 0, 0, 0);
        var diff = target - now;
        return Math.ceil(diff / (1000 * 60 * 60 * 24));
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium

        Repeater {
            model: root.countdownsList
            delegate: Row {
                width: parent.width
                property int daysLeft: root.daysUntil(modelData.date)

                Text {
                    text: modelData.label
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    font.family: ThemeModule.Theme.fontFamily
                    font.bold: true
                    color: parent.daysLeft <= 7 ? ThemeModule.Theme.accent : ThemeModule.Theme.text
                }

                Item {
                    width: Math.max(0, parent.width - parent.children[0].width - parent.children[2].width)
                    height: 1
                }

                Text {
                    text: parent.daysLeft < 0 ? Math.abs(parent.daysLeft) + "d ago" : (parent.daysLeft === 0 ? "Today!" : parent.daysLeft + " days")
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    font.family: ThemeModule.Theme.fontFamily
                    color: parent.daysLeft <= 0 ? ThemeModule.Theme.success : ThemeModule.Theme.subtext
                }
            }
        }
    }
}
