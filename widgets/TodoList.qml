import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../components" as Components
import "../services" as Services
import "../theme" as ThemeModule

Components.Card {
    id: root
    title: "To-Do"
    icon: "✓"

    property bool dashboardActive: true
    readonly property string todosPath: {
        var base = Services.SystemState.dataDir;
        return base !== "" ? (base + "/todos.json")
                           : Qt.resolvedUrl("../data/todos.json").toString().replace(/^file:\/\//, "");
    }
    readonly property string todosDirPath: root.todosPath.substring(0, root.todosPath.lastIndexOf("/"))

    property var todos: []
    property bool loaded: false

    function shellQuote(value) {
        return "'" + String(value).replace(/'/g, "'\"'\"'") + "'";
    }

    function saveTodos() {
        var json = JSON.stringify(root.todos);
        writeProc.command = [
            "sh", "-lc",
            "mkdir -p " + root.shellQuote(root.todosDirPath)
            + " && printf '%s' " + root.shellQuote(json)
            + " > " + root.shellQuote(root.todosPath)
        ];
        writeProc.running = true;
    }

    function addTodo(text) {
        var t = text.trim();
        if (t === "") return;
        var newList = root.todos.slice();
        newList.push({ text: t, done: false });
        root.todos = newList;
        root.saveTodos();
    }

    function toggleTodo(index) {
        var newList = root.todos.slice();
        newList[index] = { text: newList[index].text, done: !newList[index].done };
        root.todos = newList;
        root.saveTodos();
    }

    function removeTodo(index) {
        var newList = root.todos.slice();
        newList.splice(index, 1);
        root.todos = newList;
        root.saveTodos();
    }

    Component.onCompleted: {
        readProc.command = [
            "sh", "-lc",
            "mkdir -p " + root.shellQuote(root.todosDirPath)
            + " && [ -f " + root.shellQuote(root.todosPath) + " ] && cat " + root.shellQuote(root.todosPath) + " || echo '[]'"
        ];
        readProc.running = true;
    }

    Process {
        id: readProc
        running: false
        property string buffer: ""
        stdout: SplitParser {
            onRead: function(data) { readProc.buffer += data; }
        }
        onExited: function(exitCode) {
            if (exitCode === 0) {
                try {
                    var parsed = JSON.parse(readProc.buffer.trim());
                    root.todos = Array.isArray(parsed) ? parsed : [];
                } catch(e) {
                    root.todos = [];
                }
            }
            readProc.buffer = "";
            root.loaded = true;
        }
    }

    Process {
        id: writeProc
        running: false
    }

    Column {
        width: parent.width
        spacing: ThemeModule.Theme.spacingSmall

        Repeater {
            model: root.todos
            delegate: Row {
                width: parent.width
                spacing: ThemeModule.Theme.spacingSmall

                Rectangle {
                    id: checkbox
                    width: 18
                    height: 18
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: modelData.done
                        ? Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.25)
                        : "transparent"
                    border.width: 1
                    border.color: modelData.done
                        ? ThemeModule.Theme.accent
                        : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.5)

                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        font.pixelSize: 11
                        font.bold: true
                        color: ThemeModule.Theme.accent
                        visible: modelData.done
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleTodo(index)
                    }
                }

                Text {
                    width: parent.width - checkbox.width - deleteBtn.width - ThemeModule.Theme.spacingSmall * 2
                    anchors.verticalCenter: parent.verticalCenter
                    text: modelData.text
                    font.pixelSize: ThemeModule.Theme.fontSizeSmall
                    font.family: ThemeModule.Theme.fontFamily
                    color: modelData.done ? ThemeModule.Theme.subtext : ThemeModule.Theme.text
                    font.strikeout: modelData.done
                    wrapMode: Text.WordWrap

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.toggleTodo(index)
                    }
                }

                Components.IconButton {
                    id: deleteBtn
                    anchors.verticalCenter: parent.verticalCenter
                    size: 22
                    iconSize: 11
                    iconText: "✕"
                    iconColor: ThemeModule.Theme.subtext
                    hoverColor: Qt.rgba(ThemeModule.Theme.error.r, ThemeModule.Theme.error.g, ThemeModule.Theme.error.b, 0.15)
                    onClicked: root.removeTodo(index)
                }
            }
        }

        Text {
            width: parent.width
            text: "Nothing on the list yet."
            font.pixelSize: ThemeModule.Theme.fontSizeSmall
            font.family: ThemeModule.Theme.fontFamily
            color: ThemeModule.Theme.subtext
            visible: root.todos.length === 0 && root.loaded
        }

        Row {
            width: parent.width
            spacing: ThemeModule.Theme.spacingSmall

            TextField {
                id: newTodoInput
                width: parent.width - addBtn.width - ThemeModule.Theme.spacingSmall
                height: 34
                background: Rectangle {
                    radius: ThemeModule.Theme.borderRadiusSmall
                    color: ThemeModule.Theme.card
                    border.width: 1
                    border.color: newTodoInput.activeFocus
                        ? ThemeModule.Theme.accent
                        : Qt.rgba(ThemeModule.Theme.overlay.r, ThemeModule.Theme.overlay.g, ThemeModule.Theme.overlay.b, 0.25)
                }
                leftPadding: ThemeModule.Theme.spacingSmall
                rightPadding: ThemeModule.Theme.spacingSmall
                color: ThemeModule.Theme.text
                font.pixelSize: ThemeModule.Theme.fontSizeSmall
                font.family: ThemeModule.Theme.fontFamily
                placeholderText: "Add a task…"
                onAccepted: {
                    root.addTodo(newTodoInput.text);
                    newTodoInput.text = "";
                }
            }

            Components.IconButton {
                id: addBtn
                size: 34
                iconSize: 15
                iconText: "+"
                iconColor: ThemeModule.Theme.accent
                hoverColor: Qt.rgba(ThemeModule.Theme.accent.r, ThemeModule.Theme.accent.g, ThemeModule.Theme.accent.b, 0.16)
                onClicked: {
                    root.addTodo(newTodoInput.text);
                    newTodoInput.text = "";
                }
            }
        }
    }
}
