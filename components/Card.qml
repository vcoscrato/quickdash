import QtQuick
import QtQuick.Controls
import "../theme" as ThemeModule

Rectangle {
    id: root

    default property alias content: contentColumn.data
    property alias contentItem: contentColumn
    property alias pinnedContent: pinnedColumn.data
    property alias headerActions: headerActionsRow.data
    property string title: ""
    property string icon: ""
    property bool collapsible: false
    property bool collapsed: collapsible

    color: ThemeModule.Theme.card
    radius: ThemeModule.Theme.borderRadius
    border.width: ThemeModule.Theme.borderWidth
    border.color: Qt.rgba(
        ThemeModule.Theme.overlay.r,
        ThemeModule.Theme.overlay.g,
        ThemeModule.Theme.overlay.b,
        0.15
    )

    implicitHeight: container.implicitHeight + ThemeModule.Theme.spacingMedium * 2
    implicitWidth: parent ? parent.width : 300

    Behavior on implicitHeight {
        NumberAnimation { duration: ThemeModule.Theme.animDuration; easing.type: Easing.OutCubic }
    }

    clip: true

    Column {
        id: container
        anchors {
            fill: parent
            margins: ThemeModule.Theme.spacingMedium
        }
        spacing: ThemeModule.Theme.spacingSmall

        // Header (optional)
        Item {
            id: headerContainer
            visible: root.title !== ""
            width: parent.width
            height: visible ? Math.max(28, leftTitleRow.height, rightControlsRow.height) : 0

            Row {
                id: leftTitleRow
                spacing: ThemeModule.Theme.spacingSmall
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: root.icon
                    font.pixelSize: ThemeModule.Theme.fontSizeLarge
                    color: ThemeModule.Theme.accent
                    visible: root.icon !== ""
                }

                Text {
                    text: root.title
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    font.bold: true
                    font.family: ThemeModule.Theme.fontFamily
                    color: ThemeModule.Theme.text
                }
            }

            Row {
                id: rightControlsRow
                spacing: ThemeModule.Theme.spacingSmall
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                Row {
                    id: headerActionsRow
                    spacing: ThemeModule.Theme.spacingSmall
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    id: collapseIndicator
                    text: root.collapsed ? "▸" : "▾"
                    color: ThemeModule.Theme.subtext
                    font.pixelSize: ThemeModule.Theme.fontSizeNormal
                    visible: root.collapsible
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        visible: root.collapsible
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.collapsed = !root.collapsed
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.rightMargin: rightControlsRow.width + ThemeModule.Theme.spacingSmall
                visible: root.collapsible
                cursorShape: root.collapsible ? Qt.PointingHandCursor : Qt.ArrowCursor
                onClicked: {
                    if (root.collapsible) root.collapsed = !root.collapsed
                }
            }
        }

        Column {
            id: pinnedColumn
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
        }

        // Content area
        Column {
            id: contentColumn
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall
            visible: !root.collapsed
            opacity: root.collapsed ? 0 : 1

            Behavior on opacity {
                NumberAnimation { duration: ThemeModule.Theme.animDuration }
            }
        }
    }
}
