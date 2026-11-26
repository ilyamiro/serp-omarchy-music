import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import Qt.labs.folderlistmodel
import Quickshell
import "../../Serp.js" as Serp
import "../"

Popup {
    id: pickerRoot
    parent: {
        if (rootObj) {
            return rootObj.contentItem ? rootObj.contentItem : rootObj;
        }
        return Overlay.overlay ? Overlay.overlay : undefined;
    }
    x: parent && parent.width > 0 ? Math.max(0, Math.round((parent.width - width) / 2)) : 0
    y: parent && parent.height > 0 ? Math.max(0, Math.round((parent.height - height) / 2)) : 0
    modal: true
    dim: true
    z: 300000
    property real preferredWidth: Serp.s(960)
    property real preferredHeight: Serp.s(640)
    readonly property real maxPickerWidth: parent && parent.width > 0 ? parent.width * 0.92 : preferredWidth
    readonly property real maxPickerHeight: parent && parent.height > 0 ? parent.height * 0.92 : preferredHeight
    width: Math.round(Math.max(Math.min(preferredWidth, maxPickerWidth), Math.min(Serp.s(320), maxPickerWidth)))
    height: Math.round(Math.max(Math.min(preferredHeight, maxPickerHeight), Math.min(Serp.s(300), maxPickerHeight)))
    padding: Serp.s(18)
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    property var rootObj
    property var nameFilters: ["*"]
    property string titleText: true ? Serp.tr("guide.file_picker.title") : ""
    property string doneButtonText: true ? Serp.tr("guide.file_picker.done") : "Done"
    property var places: []
    property Component previewComponent: null
    property bool showPreview: false
    property real previewWidth: Serp.s(360)

    property real crLarge: Serp.theme.borderRadius
    property real crMedium: Math.max(0, Serp.theme.borderRadius - 2)
    property real crSmall: Math.max(0, Serp.theme.borderRadius - 4)

    property real toolbarHeight: Serp.s(32)
    property real actionHeight: Serp.s(42)

    signal fileSelected(string filePath, string fileName)

    property string selectedFilePath: ""
    property string selectedFileName: ""
    property bool saveMode: false
    property string saveFileName: ""
    onSelectedFileNameChanged: {
        if (saveMode && selectedFileName !== "") saveFileName = selectedFileName;
    }
    property string lastVisitedFolder: ""

    property int currentPlaceIndex: {
        let cur = folderModel.folder.toString();
        if (cur.endsWith("/")) cur = cur.slice(0, -1);
        for (let i = 0; i < pickerRoot.places.length; i++) {
            let p = pickerRoot.places[i].path.toString();
            if (p.endsWith("/")) p = p.slice(0, -1);
            if (cur === p) return i;
        }
        return -1;
    }

    Connections {
        target: pickerRoot.rootObj ? pickerRoot.rootObj : null
        function onVisibleChanged() {
            if (pickerRoot.rootObj && !pickerRoot.rootObj.visible) {
                pickerRoot.close();
            }
        }
    }

    Connections {
        target: pickerRoot.parent && pickerRoot.parent !== pickerRoot.rootObj ? pickerRoot.parent : null
        function onVisibleChanged() {
            if (pickerRoot.parent && !pickerRoot.parent.visible) {
                pickerRoot.close();
            }
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: pickerRoot.opened
        onActivated: pickerRoot.close()
    }

    Shortcut {
        sequence: "Tab"
        enabled: pickerRoot.opened && pickerRoot.places && pickerRoot.places.length > 0
        onActivated: {
            let nextIdx = pickerRoot.currentPlaceIndex >= 0 ? (pickerRoot.currentPlaceIndex + 1) % pickerRoot.places.length : 0;
            pickerRoot.gotoFolder(pickerRoot.places[nextIdx].path);
        }
    }

    Shortcut {
        sequences: ["Backtab", "Shift+Tab"]
        enabled: pickerRoot.opened && pickerRoot.places && pickerRoot.places.length > 0
        onActivated: {
            let len = pickerRoot.places.length;
            let prevIdx = pickerRoot.currentPlaceIndex >= 0 ? (pickerRoot.currentPlaceIndex - 1 + len) % len : len - 1;
            pickerRoot.gotoFolder(pickerRoot.places[prevIdx].path);
        }
    }

    Shortcut {
        sequences: ["Return", "Enter"]
        enabled: pickerRoot.opened
        onActivated: {
            if (listView.activeFocus && listView.currentItem) {
                let obj = folderModel.get(listView.currentIndex, "fileIsDir");
                let fp = folderModel.get(listView.currentIndex, "filePath");
                let fn = folderModel.get(listView.currentIndex, "fileName");
                if (obj) {
                    pickerRoot.gotoFolder(fp);
                } else {
                    pickerRoot.selectedFilePath = pickerRoot.getAbsolutePath(fp);
                    try {
                        pickerRoot.selectedFileName = decodeURIComponent(fn);
                    } catch (e) {
                        pickerRoot.selectedFileName = fn;
                    }
                    pickerRoot.confirmSelection();
                }
            } else if (pickerRoot.saveMode || pickerRoot.selectedFilePath !== "") {
                pickerRoot.confirmSelection();
            }
        }
    }

    function confirmSelection() {
        if (pickerRoot.saveMode) {
            let name = pickerRoot.saveFileName.trim().replace(/\//g, "_");
            if (name === "") return;
            let dir = pickerRoot.getAbsolutePath(folderModel.folder).replace(/\/$/, "");
            pickerRoot.fileSelected(dir + "/" + name, name);
            pickerRoot.close();
            return;
        }
        if (pickerRoot.selectedFilePath !== "") {
            pickerRoot.fileSelected(pickerRoot.selectedFilePath, pickerRoot.selectedFileName);
            pickerRoot.close();
        }
    }

    function getAbsolutePath(pathStr) {
        if (!pathStr) return "";
        let str = pathStr.toString();
        if (str.startsWith("file://")) {
            str = str.substring(7);
        }
        try {
            return decodeURIComponent(str);
        } catch (e) {
            return str;
        }
    }

    function openSave(initialDir, initialName) {
        saveMode = true;
        saveFileName = initialName || "";
        if (initialDir) lastVisitedFolder = "file://" + initialDir;
        openWithOptionalPath("");
        saveFileName = initialName || "";
    }

    function openWithOptionalPath(initialPath) {
        if (!initialPath && !saveMode) saveFileName = "";
        if (searchInput) {
            searchInput.clear();
        }

        let p = initialPath ? initialPath.toString() : "";
        if (p.startsWith("file://")) {
            p = p.substring(7);
        }
        try {
            p = decodeURIComponent(p);
        } catch (e) {}

        if (p !== "") {
            selectedFilePath = p;
            let parts = p.split("/");
            try {
                selectedFileName = decodeURIComponent(parts[parts.length - 1]);
            } catch (e) {
                selectedFileName = parts[parts.length - 1];
            }

            let dir = parts.slice(0, -1).join("/");
            if (dir !== "") {
                lastVisitedFolder = "file://" + dir;
            }
        } else {
            selectedFilePath = "";
            selectedFileName = "";
            if (lastVisitedFolder === "") {
                let home = Quickshell.env("HOME") || "";
                if (home !== "") {
                    lastVisitedFolder = "file://" + home;
                }
            }
        }

        folderModel.folder = lastVisitedFolder || "file:///";
        updateNameFilters();
        open();

        Qt.callLater(() => {
            if (breadcrumbFlickable.contentWidth > breadcrumbFlickable.width) {
                breadcrumbFlickable.contentX = breadcrumbFlickable.contentWidth - breadcrumbFlickable.width;
            }
        });
    }

    function gotoFolder(path) {
        let normalizedPath = path.toString();
        if (!normalizedPath.startsWith("file://")) {
            normalizedPath = "file://" + normalizedPath;
        }
        folderModel.folder = normalizedPath;
        lastVisitedFolder = normalizedPath;
        selectedFilePath = "";
        selectedFileName = "";
    }

    function updateNameFilters() {
        let st = searchInput.text ? searchInput.text.trim() : "";
        if (st.length > 0) {
            let filters = [];
            for (let i = 0; i < pickerRoot.nameFilters.length; i++) {
                filters.push("*" + st + "*" + pickerRoot.nameFilters[i].replace("*", ""));
            }
            filters.push("*" + st + "*");
            folderModel.nameFilters = filters;
        } else {
            folderModel.nameFilters = pickerRoot.nameFilters;
        }
    }

    Timer {
        id: searchDebounceTimer
        interval: 150
        repeat: false
        onTriggered: pickerRoot.updateNameFilters()
    }

    background: Rectangle {
        color: Serp.theme.base
        radius: pickerRoot.crLarge
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.4)
            shadowVerticalOffset: Serp.s(4)
            shadowBlur: 0.5
        }
    }

    contentItem: ColumnLayout {
        spacing: Serp.s(14)

        RowLayout {
            Layout.fillWidth: true
            Text {
                textFormat: Text.PlainText
                text: pickerRoot.titleText
                color: Serp.theme.text
                font.family: Serp.theme.fontFamily
                font.pixelSize: Serp.fs(16)
                font.weight: Font.Bold
                Layout.fillWidth: true
            }
            CloseButton {
                Layout.preferredWidth: pickerRoot.toolbarHeight
                Layout.preferredHeight: pickerRoot.toolbarHeight
                cornerRadius: pickerRoot.crSmall
                iconFontSize: Serp.fs(14)
                accentColor: Serp.theme.surface1
                textColor: Serp.theme.text
                onClicked: pickerRoot.close()
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Serp.s(14)

            Rectangle {
                Layout.preferredWidth: Serp.s(180)
                Layout.fillHeight: true
                color: "transparent"
                visible: pickerRoot.places.length > 0

                ColumnLayout {
                    anchors.fill: parent
                    spacing: Serp.s(2)

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: pickerRoot.places.length * Serp.s(34)

                        Rectangle {
                            id: activeHighlight
                            width: parent.width
                            height: Serp.s(34)
                            radius: pickerRoot.crSmall
                            color: Serp.theme.mauve
                            z: 0
                            visible: pickerRoot.currentPlaceIndex !== -1
                            opacity: pickerRoot.currentPlaceIndex !== -1 ? 1.0 : 0.0

                            Behavior on opacity {
                                NumberAnimation { duration: 150 }
                            }

                            property int curIdx: pickerRoot.currentPlaceIndex
                            property real targetY: curIdx >= 0 ? curIdx * Serp.s(34) : 0
                            y: targetY

                            Behavior on y {
                                NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
                            }
                        }

                        Column {
                            anchors.fill: parent
                            spacing: 0

                            Repeater {
                                model: pickerRoot.places

                                Rectangle {
                                    width: parent.width
                                    height: Serp.s(34)
                                    radius: pickerRoot.crSmall
                                    z: 1

                                    property bool isActive: pickerRoot.currentPlaceIndex === index
                                    color: isActive ? "transparent" : (placeMa.containsMouse ? Qt.alpha(Serp.theme.surface1, 0.5) : "transparent")

                                    Behavior on color {
                                        ColorAnimation { duration: 150 }
                                    }

                                    scale: placeMa.pressed ? 0.98 : 1.0
                                    Behavior on scale {
                                        NumberAnimation { duration: 250; easing.type: Easing.OutQuint }
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: Serp.s(10) + (parent.isActive ? Serp.s(2) : 0)
                                        anchors.rightMargin: Serp.s(10)
                                        spacing: Serp.s(8)

                                        Behavior on anchors.leftMargin {
                                            NumberAnimation { duration: 400; easing.type: Easing.OutQuint }
                                        }

                                        Item {
                                            Layout.preferredWidth: Serp.s(20)
                                            Layout.alignment: Qt.AlignVCenter

                                            Text {
                                                textFormat: Text.PlainText
                                                anchors.centerIn: parent
                                                text: modelData.icon
                                                font.family: Serp.theme.iconFont
                                                font.pixelSize: Serp.fs(16)
                                                color: parent.parent.parent.isActive ? Serp.theme.crust : (placeMa.containsMouse ? Serp.theme.text : Serp.theme.subtext0)

                                                Behavior on color {
                                                    ColorAnimation { duration: 150 }
                                                }
                                            }
                                        }

                                        Text {
                                            textFormat: Text.PlainText
                                            text: modelData.name
                                            font.family: Serp.theme.fontFamily
                                            font.weight: parent.parent.isActive ? Font.Bold : Font.Medium
                                            font.pixelSize: Serp.fs(13)
                                            color: parent.parent.isActive ? Serp.theme.crust : (placeMa.containsMouse ? Serp.theme.text : Serp.theme.subtext0)
                                            Layout.fillWidth: true
                                            Layout.alignment: Qt.AlignVCenter
                                            elide: Text.ElideRight

                                            Behavior on color {
                                                ColorAnimation { duration: 150 }
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: placeMa
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: pickerRoot.gotoFolder(modelData.path)
                                    }
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: 0
                spacing: Serp.s(10)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Serp.s(6)

                    IconButton {
                        Layout.preferredWidth: pickerRoot.toolbarHeight
                        Layout.preferredHeight: pickerRoot.toolbarHeight
                        Layout.minimumWidth: pickerRoot.toolbarHeight
                        Layout.maximumWidth: pickerRoot.toolbarHeight
                        cornerRadius: pickerRoot.crSmall
                        buttonIcon: "󰁍"
                        iconFontSize: Serp.fs(16)
                        accentColor: Serp.theme.surface1
                        textColor: Serp.theme.text
                        enabled: folderModel.folder.toString() !== "file:///"
                        onClicked: {
                            folderModel.folder = folderModel.parentFolder;
                            pickerRoot.lastVisitedFolder = folderModel.parentFolder.toString();
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.minimumWidth: Serp.s(50)
                        Layout.preferredHeight: pickerRoot.toolbarHeight
                        radius: pickerRoot.crSmall
                        color: Serp.theme.surface0
                        clip: true

                        Flickable {
                            id: breadcrumbFlickable
                            anchors.fill: parent
                            contentWidth: breadcrumbRow.width
                            boundsBehavior: Flickable.StopAtBounds
                            clip: true

                            onContentWidthChanged: {
                                Qt.callLater(() => {
                                    if (breadcrumbFlickable.contentWidth > breadcrumbFlickable.width) {
                                        breadcrumbFlickable.contentX = breadcrumbFlickable.contentWidth - breadcrumbFlickable.width;
                                    } else {
                                        breadcrumbFlickable.contentX = 0;
                                    }
                                });
                            }

                            Row {
                                id: breadcrumbRow
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: Serp.s(2)
                                leftPadding: Serp.s(6)
                                rightPadding: Serp.s(6)

                                Repeater {
                                    id: breadcrumbRepeater
                                    model: {
                                        let rawPath = folderModel.folder.toString().replace("file://", "");
                                        try {
                                            rawPath = decodeURIComponent(rawPath);
                                        } catch (e) {}
                                        let parts = rawPath.split("/").filter(p => p !== "");
                                        let rootName = true ? Serp.tr("guide.file_picker.root") : "Root";
                                        let arr = [{ name: rootName, path: "file:///" }];
                                        let cp = "file://";
                                        for (let i = 0; i < parts.length; i++) {
                                            cp += "/" + parts[i];
                                            arr.push({ name: parts[i], path: cp });
                                        }
                                        return arr;
                                    }

                                    delegate: Row {
                                        spacing: Serp.s(2)
                                        anchors.verticalCenter: parent.verticalCenter

                                        Text {
                                            textFormat: Text.PlainText
                                            text: "󰅂"
                                            color: Serp.theme.surface2
                                            font.family: Serp.theme.iconFont
                                            font.pixelSize: Serp.fs(14)
                                            visible: index > 0
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Rectangle {
                                            property bool isCurrent: index === breadcrumbRepeater.count - 1
                                            height: pickerRoot.toolbarHeight - Serp.s(6)
                                            width: bcTxt.implicitWidth + Serp.s(14)
                                            radius: Serp.s(6)
                                            color: isCurrent ? Serp.theme.surface1 : (bcMa.containsMouse ? Serp.theme.surface0 : "transparent")
                                            anchors.verticalCenter: parent.verticalCenter

                                            Text {
                                                textFormat: Text.PlainText
                                                id: bcTxt
                                                anchors.centerIn: parent
                                                text: modelData.name
                                                font.family: Serp.theme.fontFamily
                                                color: parent.isCurrent ? Serp.theme.mauve : (bcMa.containsMouse ? Serp.theme.text : Serp.theme.subtext0)
                                                font.pixelSize: Serp.fs(12)
                                            }

                                            MouseArea {
                                                id: bcMa
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: pickerRoot.gotoFolder(modelData.path)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: Serp.s(84)
                        Layout.preferredHeight: pickerRoot.toolbarHeight
                        Layout.minimumWidth: Serp.s(84)
                        Layout.maximumWidth: Serp.s(84)
                        radius: pickerRoot.crSmall
                        color: Serp.theme.surface0
                        clip: true

                        Toggle {
                            id: hiddenToggle
                            anchors.fill: parent
                            buttonText: ""
                            buttonIcon: "󰈈"
                            iconFontSize: Serp.fs(16)
                            accentColor: Serp.theme.mauve
                            baseColor: "transparent"
                            textColor: Serp.theme.text
                            checked: folderModel.showHidden
                            onToggled: function(chk) {
                                folderModel.showHidden = chk;
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Serp.s(6)

                    Input {
                        id: searchInput
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        Layout.preferredHeight: pickerRoot.toolbarHeight
                        leadingIcon: "󰍉"
                        showClearButton: true
                        placeholderText: {
                            let raw = true ? Serp.tr("guide.file_picker.input_placeholder") : "Search...";
                            let cleaned = raw.replace(/^[\uE000-\uF8FF\s]+/g, "").trim();
                            return cleaned !== "" ? cleaned : "Search...";
                        }
                        baseColor: Serp.theme.surface0
                        accentColor: Serp.theme.mauve
                        textColor: Serp.theme.text
                        subTextColor: Serp.theme.subtext0
                        borderColor: "transparent"
                        cornerRadius: pickerRoot.crSmall
                        horizontalPadding: Serp.s(10)
                        verticalPadding: Serp.s(4)
                        fontPixelSize: Serp.fs(12)
                        onTextEdited: function(txt) {
                            searchDebounceTimer.restart();
                        }
                        onCleared: {
                            searchDebounceTimer.restart();
                        }
                        onAccepted: { if (!pickerRoot.saveMode) pickerRoot.confirmSelection(); }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 0
                    Layout.preferredWidth: 0
                    color: Serp.theme.surface0
                    radius: pickerRoot.crMedium
                    clip: true

                    Text {
                        textFormat: Text.PlainText
                        anchors.centerIn: parent
                        text: true ? Serp.tr("guide.file_picker.not_found") : "No files found"
                        color: Serp.theme.subtext0
                        font.pixelSize: Serp.fs(14)
                        font.family: Serp.theme.fontFamily
                        visible: folderModel.count === 0
                    }

                    ListView {
                        id: listView
                        anchors.fill: parent
                        anchors.margins: Serp.s(2)
                        boundsBehavior: Flickable.StopAtBounds
                        clip: true
                        spacing: Serp.s(0)
                        focus: true

                        model: FolderListModel {
                            id: folderModel
                            showDirsFirst: true
                            showDotAndDotDot: false
                            showFiles: true
                            showDirs: true
                            showHidden: false
                            caseSensitive: false
                            sortField: FolderListModel.Name
                            nameFilters: pickerRoot.nameFilters
                        }

                        delegate: Rectangle {
                            id: delegateItem
                            property string searchText: searchInput.text ? searchInput.text.toLowerCase().trim() : ""
                            property bool matchesSearch: searchText === "" || fileName.toLowerCase().indexOf(searchText) !== -1

                            width: listView.width
                            height: matchesSearch ? Serp.s(32) : 0
                            visible: matchesSearch
                            radius: pickerRoot.crSmall
                            color: (pickerRoot.selectedFilePath === pickerRoot.getAbsolutePath(filePath)) ? Qt.alpha(Serp.theme.mauve, 0.15) : (delegateMa.containsMouse ? Serp.theme.surface1 : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: Serp.s(8)
                                anchors.rightMargin: Serp.s(8)
                                spacing: Serp.s(6)

                                Text {
                                    textFormat: Text.PlainText
                                    text: fileIsDir ? "󰉋" : "󰋩"
                                    font.family: Serp.theme.iconFont
                                    font.pixelSize: Serp.fs(16)
                                    color: fileIsDir ? Serp.theme.blue : Serp.theme.text
                                }

                                Text {
                                    textFormat: Text.PlainText
                                    text: {
                                        try {
                                            return decodeURIComponent(fileName);
                                        } catch (e) {
                                            return fileName;
                                        }
                                    }
                                    font.family: Serp.theme.fontFamily
                                    font.pixelSize: Serp.fs(13)
                                    color: Serp.theme.text
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: delegateMa
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    listView.forceActiveFocus();
                                    listView.currentIndex = index;
                                    if (fileIsDir) {
                                        pickerRoot.gotoFolder(filePath);
                                    } else {
                                        pickerRoot.selectedFilePath = pickerRoot.getAbsolutePath(filePath);
                                        try {
                                            pickerRoot.selectedFileName = decodeURIComponent(fileName);
                                        } catch (e) {
                                            pickerRoot.selectedFileName = fileName;
                                        }
                                    }
                                }
                                onDoubleClicked: {
                                    if (fileIsDir) {
                                        pickerRoot.gotoFolder(filePath);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Loader {
                Layout.preferredWidth: Math.min(pickerRoot.previewWidth, pickerRoot.width * 0.38)
                Layout.fillHeight: true
                sourceComponent: pickerRoot.previewComponent
                visible: pickerRoot.showPreview
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Serp.s(14)

            Input {
                Layout.fillWidth: true
                Layout.preferredHeight: pickerRoot.actionHeight
                visible: pickerRoot.saveMode
                text: pickerRoot.saveFileName
                baseColor: Serp.theme.surface0
                accentColor: Serp.theme.mauve
                textColor: Serp.theme.text
                subTextColor: Serp.theme.subtext0
                borderColor: "transparent"
                cornerRadius: pickerRoot.crMedium
                horizontalPadding: Serp.s(12)
                fontPixelSize: Serp.fs(13)
                onTextEdited: function(txt) { pickerRoot.saveFileName = txt; }
                onAccepted: pickerRoot.confirmSelection()
            }

            Text {
                textFormat: Text.PlainText
                Layout.fillWidth: true
                visible: !pickerRoot.saveMode
                text: {
                    if (pickerRoot.selectedFileName !== "") {
                        try {
                            return decodeURIComponent(pickerRoot.selectedFileName);
                        } catch (e) {
                            return pickerRoot.selectedFileName;
                        }
                    }
                    return true ? Serp.tr("guide.file_picker.no_file_selected") : "No file selected";
                }
                color: pickerRoot.selectedFileName !== "" ? Serp.theme.text : Serp.theme.subtext0
                font.pixelSize: Serp.fs(14)
                font.family: Serp.theme.fontFamily
                elide: Text.ElideRight
            }

            ClickButton {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: pickerRoot.actionHeight
                implicitHeight: pickerRoot.actionHeight
                horizontalPadding: Serp.s(18)
                cornerRadius: pickerRoot.crMedium
                buttonText: pickerRoot.doneButtonText
                textFontSize: Serp.fs(13)
                readonly property bool ready: pickerRoot.saveMode ? pickerRoot.saveFileName.trim() !== "" : pickerRoot.selectedFilePath !== ""
                accentColor: ready ? Serp.theme.mauve : Serp.theme.surface0
                textColor: ready ? Serp.theme.crust : Serp.theme.subtext0
                enabled: ready
                onClicked: pickerRoot.confirmSelection()
            }
        }
    }
}
