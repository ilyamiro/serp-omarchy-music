import QtQuick
import "../../Serp.js" as Serp

Item {
    id: root
    visible: false

    property var targetScreen: null
    readonly property bool opened: false

    signal lyricsSelected(string filePath, string fileName)

    function openPicker(initialPath) {
        Serp.theme.pickLyricsFile();
    }

    function closePicker() {
    }
}
