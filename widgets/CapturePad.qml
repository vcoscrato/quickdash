import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "Capture Pad"
    icon: "🗂"

    property bool dashboardActive: true
    readonly property string notesPath: Qt.resolvedUrl("../data/scratchpad.txt").toString().replace(/^file:\/\//, "")
    readonly property string notesDirPath: root.notesPath.substring(0, root.notesPath.lastIndexOf("/"))
    readonly property bool wideLayout: width >= 420

    property string savedText: ""
    property bool notesLoaded: false
    property bool notesDirty: false

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    function readNotes() {
        if (!readProc.running) {
            readProc.command = [
                "sh",
                "-lc",
                "mkdir -p " + root.shellQuote(root.notesDirPath)
                    + " && touch " + root.shellQuote(root.notesPath)
                    + " && cat " + root.shellQuote(root.notesPath)
            ];
            readProc.running = true;
        }
    }

    function saveNotes() {
        if (!root.notesLoaded || writeProc.running) {
            return;
        }

        root.savedText = notesInput.text;
        root.notesDirty = false;
        writeProc.command = [
            "sh",
            "-lc",
            "mkdir -p " + root.shellQuote(root.notesDirPath)
                + " && printf '%s' " + root.shellQuote(root.savedText)
                + " > " + root.shellQuote(root.notesPath)
        ];
        writeProc.running = true;
    }

    function queueSave() {
        if (!root.notesLoaded) {
            return;
        }
        root.notesDirty = root.savedText !== notesInput.text;
        if (root.notesDirty) {
            saveTimer.restart();
        }
    }

    onDashboardActiveChanged: {
        Services.ClipboardService.setPanelVisible(root.dashboardActive);
        if (root.dashboardActive) {
            root.readNotes();
        } else if (root.notesDirty) {
            saveTimer.stop();
            root.saveNotes();
        }
    }

    Component.onCompleted: {
        root.readNotes();
        Services.ClipboardService.setPanelVisible(root.dashboardActive);
    }

    Process {
        id: readProc
        running: false
        property string buffer: ""
        stdout: SplitParser {
            onRead: function(data) {
                readProc.buffer += data;
            }
        }
        onExited: function(exitCode) {
            var nextText = exitCode === 0 ? readProc.buffer : "";
            root.savedText = nextText;
            notesInput.text = nextText;
            root.notesLoaded = true;
            root.notesDirty = false;
            readProc.buffer = "";
        }
    }

    Process {
        id: writeProc
        running: false
        onExited: function(exitCode) {
            if (exitCode !== 0) {
                root.notesDirty = true;
            }
        }
    }

    Timer {
        id: saveTimer
        interval: 900
        running: false
        repeat: false
        onTriggered: root.saveNotes()
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingMedium

        Flow {
            width: parent.width
            spacing: ThemeModule.Theme.spacingMedium
            flow: root.wideLayout ? Flow.LeftToRight : Flow.TopToBottom

            Rectangle {
                width: root.wideLayout
                    ? Math.floor((parent.width - ThemeModule.Theme.spacingMedium) * 0.44)
                    : parent.width
                height: 248
                radius: ThemeModule.Theme.borderRadiusSmall
                color: Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.32)
                border.width: 1
                border.color: notesInput.activeFocus ? ThemeModule.Theme.accent : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.25)

                Column {
                    anchors.fill: parent
                    anchors.margins: ThemeModule.Theme.spacingSmall
                    spacing: ThemeModule.Theme.spacingSmall

                    Row {
                        width: parent.width

                        property real spareWidth: Math.max(0, width - notesTitle.implicitWidth - notesStatus.implicitWidth)

                        Text {
                            id: notesTitle
                            text: "Notes"
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: ThemeModule.Theme.text
                        }

                        Item { width: parent.spareWidth; height: 1 }

                        Text {
                            id: notesStatus
                            text: writeProc.running ? "Saving…" : (root.notesDirty ? "Unsaved" : (root.notesLoaded ? "Saved" : "Loading…"))
                            font.pixelSize: 10
                            font.family: ThemeModule.Theme.fontFamily
                            color: root.notesDirty ? ThemeModule.Theme.warning : ThemeModule.Theme.subtext
                        }
                    }

                    Flickable {
                        id: notesFlickable
                        width: parent.width
                        height: parent.height - 24
                        contentWidth: width
                        contentHeight: Math.max(notesInput.implicitHeight, height)
                        clip: true

                        ScrollBar.vertical: ScrollBar {
                            policy: notesFlickable.contentHeight > notesFlickable.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                        }

                        TextArea {
                            id: notesInput
                            width: parent.width
                            height: notesFlickable.contentHeight
                            wrapMode: TextEdit.Wrap
                            background: null
                            placeholderText: "Keep sticky notes, prompts, or anything you want to paste later."
                            color: ThemeModule.Theme.text
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            onTextChanged: root.queueSave()
                        }
                    }
                }
            }

            Rectangle {
                width: root.wideLayout
                    ? parent.width - Math.floor((parent.width - ThemeModule.Theme.spacingMedium) * 0.44) - ThemeModule.Theme.spacingMedium
                    : parent.width
                height: 248
                radius: ThemeModule.Theme.borderRadiusSmall
                color: Qt.rgba(ThemeModule.Theme.surface2.r, ThemeModule.Theme.surface2.g, ThemeModule.Theme.surface2.b, 0.32)
                border.width: 1
                border.color: Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.25)

                Column {
                    anchors.fill: parent
                    anchors.margins: ThemeModule.Theme.spacingSmall
                    spacing: ThemeModule.Theme.spacingSmall

                    Row {
                        width: parent.width
                        spacing: ThemeModule.Theme.spacingSmall

                        property real spareWidth: Math.max(0, width - clipboardTitle.implicitWidth - clipboardCount.implicitWidth - refreshButton.size - spacing * 2)

                        Text {
                            id: clipboardTitle
                            text: "Clipboard"
                            font.pixelSize: ThemeModule.Theme.fontSizeSmall
                            font.family: ThemeModule.Theme.fontFamily
                            font.bold: true
                            color: ThemeModule.Theme.text
                        }

                        Text {
                            id: clipboardCount
                            text: Services.ClipboardService.history.length > 0
                                ? Services.ClipboardService.history.length + " items"
                                : ""
                            font.pixelSize: 10
                            font.family: ThemeModule.Theme.fontFamily
                            color: ThemeModule.Theme.subtext
                        }

                        Item { width: parent.spareWidth; height: 1 }

                        Components.IconButton {
                            id: refreshButton
                            iconText: Services.ClipboardService.loading ? "…" : "↻"
                            iconSize: 12
                            size: 24
                            iconColor: ThemeModule.Theme.subtextBright
                            onClicked: {
                                Services.ClipboardService.requestBurst(6);
                                Services.ClipboardService.refresh();
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 18
                        radius: 9
                        color: "transparent"
                        visible: Services.ClipboardService.feedbackText !== ""

                        Text {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: Services.ClipboardService.feedbackText
                            font.pixelSize: 10
                            font.family: ThemeModule.Theme.fontFamily
                            color: {
                                if (Services.ClipboardService.feedbackTone === "success") return ThemeModule.Theme.success;
                                if (Services.ClipboardService.feedbackTone === "warning") return ThemeModule.Theme.warning;
                                if (Services.ClipboardService.feedbackTone === "error") return ThemeModule.Theme.error;
                                return ThemeModule.Theme.subtext;
                            }
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    ListView {
                        width: parent.width
                        height: parent.height - 50
                        clip: true
                        spacing: ThemeModule.Theme.spacingTiny
                        model: Services.ClipboardService.history

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                        }

                        delegate: Rectangle {
                            width: ListView.view.width
                            height: Math.max(38, previewText.implicitHeight + 14)
                            radius: ThemeModule.Theme.borderRadiusSmall
                            color: clipMouse.containsMouse
                                ? ThemeModule.Theme.cardHover
                                : (modelData.id === Services.ClipboardService.lastCopiedId
                                    ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.12)
                                    : "transparent")
                            border.width: 1
                            border.color: modelData.id === Services.ClipboardService.lastCopiedId
                                ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.45)
                                : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.25)

                            Text {
                                id: previewText
                                anchors.fill: parent
                                anchors.margins: 7
                                text: modelData.preview
                                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                                font.family: ThemeModule.Theme.fontFamily
                                color: ThemeModule.Theme.text
                                wrapMode: Text.Wrap
                                elide: Text.ElideRight
                                maximumLineCount: 3
                            }

                            MouseArea {
                                id: clipMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Services.ClipboardService.copyEntry(modelData)
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Services.ClipboardService.available
                            ? "Nothing copied yet."
                            : "Install and run cliphist to enable clipboard history."
                        font.pixelSize: ThemeModule.Theme.fontSizeSmall
                        font.family: ThemeModule.Theme.fontFamily
                        color: ThemeModule.Theme.subtext
                        visible: Services.ClipboardService.history.length === 0 && !Services.ClipboardService.loading
                    }
                }
            }
        }
    }
}