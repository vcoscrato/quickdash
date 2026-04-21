import QtQuick
import "../theme" as ThemeModule

Item {
    id: root
    width: parent ? parent.width : 300
    height: 40

    property var quotes: [
        "The best way to predict the future is to invent it.",
        "Simplicity is the ultimate sophistication.",
        "Talk is cheap. Show me the code.",
        "Code is like humor. When you have to explain it, it's bad.",
        "Make it work, make it right, make it fast.",
        "First, solve the problem. Then, write the code.",
        "Truth can only be found in one place: the code.",
        "Don't worry if it doesn't work right. If everything did, you'd be out of a job.",
        "Perfection is achieved not when there is nothing more to add, but when there is nothing left to take away."
    ]

    property string currentQuote: quotes[Math.floor(Math.random() * quotes.length)]

    Text {
        anchors.centerIn: parent
        width: parent.width - ThemeModule.Theme.spacingMedium * 2
        text: "“" + root.currentQuote + "”"
        font.pixelSize: ThemeModule.Theme.fontSizeSmall
        font.family: ThemeModule.Theme.fontFamily
        font.italic: true
        color: ThemeModule.Theme.overlay
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
    }
}
