import QtQuick
import QtQuick.Controls
import "../theme" as ThemeModule

Rectangle {
    id: root
    
    property bool scanning: false
    property string text: "Scanning..."
    property string iconText: "🔄"
    
    signal clicked()
    
    height: 32
    // If scanning, width expands to fit icon + text. Otherwise just 32 for icon.
    implicitWidth: scanning ? contentRow.implicitWidth + 24 : 32
    radius: height / 2
    
    color: mouseArea.containsMouse && !scanning 
        ? ThemeModule.Theme.cardHover 
        : (scanning ? ThemeModule.Theme.surface2 : "transparent")
        
    border.width: scanning ? 1 : 0
    border.color: Qt.rgba(ThemeModule.Theme.sky.r, ThemeModule.Theme.sky.g, ThemeModule.Theme.sky.b, 0.3)
        
    Behavior on implicitWidth {
        NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
    }
    
    Behavior on color {
        ColorAnimation { duration: 150 }
    }
    
    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: ThemeModule.Theme.spacingSmall
        
        Text {
            id: iconElement
            text: root.iconText
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            color: root.scanning ? ThemeModule.Theme.sky : ThemeModule.Theme.text
            anchors.verticalCenter: parent.verticalCenter
            
            RotationAnimator on rotation {
                from: 0; to: 360; duration: 1000; loops: Animation.Infinite
                running: root.scanning
            }
        }
        
        Text {
            id: labelElement
            text: root.text
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.text
            anchors.verticalCenter: parent.verticalCenter
            visible: opacity > 0
            opacity: root.scanning ? 1.0 : 0.0
            
            Behavior on opacity {
                NumberAnimation { duration: 250 }
            }
        }
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.scanning ? Qt.ArrowCursor : Qt.PointingHandCursor
        onClicked: {
            if (!root.scanning) {
                root.clicked()
            }
        }
    }
}
