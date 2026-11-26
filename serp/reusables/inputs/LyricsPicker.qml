import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../Serp.js" as Serp
import "../"

PanelWindow {
    id: lyricsPickerWindow

    color: "transparent"
    visible: false

    WlrLayershell.namespace: "qs-lyrics-picker"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    exclusionMode: ExclusionMode.Ignore
    focusable: true

    anchors.top: true
    anchors.left: true
    anchors.right: true
    anchors.bottom: true

    margins.left: 0
    margins.top: 0

    property var targetScreen: null
    screen: targetScreen || (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)

    readonly property bool opened: filePicker.opened

    signal lyricsSelected(string filePath, string fileName)

    function openPicker(initialPath) {
        visible = true;
        Qt.callLater(() => {
            filePicker.openWithOptionalPath(initialPath || "");
        });
    }

    function closePicker() {
        filePicker.close();
        visible = false;
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(Serp.theme.crust.r, Serp.theme.crust.g, Serp.theme.crust.b, 0.45)
        visible: filePicker.opened

        MouseArea {
            anchors.fill: parent
            onClicked: lyricsPickerWindow.closePicker()
        }
    }

    FilePicker {
        id: filePicker
        rootObj: lyricsPickerWindow

        preferredWidth: Serp.s(960)
        preferredHeight: Serp.s(640)
        previewWidth: Serp.s(340)
        titleText: true ? Serp.tr("guide.lyrics_picker.title", "Select lyrics file") : "Select lyrics file"
        nameFilters: ["*.lrc", "*.txt", "*.yrc"]
        showPreview: true

        places: [
            { name: true ? Serp.tr("guide.file_picker.places.home") : "Home", icon: "󰋜", path: "file://" + (Quickshell.env("HOME") || "") },
            { name: true ? Serp.tr("guide.file_picker.places.downloads") : "Downloads", icon: "󰇚", path: "file://" + (Quickshell.env("HOME") || "") + "/Downloads" },
            { name: true ? Serp.tr("guide.file_picker.places.music", "Music") : "Music", icon: "󰎈", path: "file://" + (Quickshell.env("HOME") || "") + "/Music" },
            { name: true ? Serp.tr("guide.file_picker.places.documents", "Documents") : "Documents", icon: "󰈙", path: "file://" + (Quickshell.env("HOME") || "") + "/Documents" }
        ]

        onFileSelected: function(filePath, fileName) {
            lyricsPickerWindow.lyricsSelected(filePath, fileName);
            lyricsPickerWindow.visible = false;
        }

        onClosed: {
            lyricsPickerWindow.visible = false;
        }

        previewComponent: Component {
            Item {
                anchors.fill: parent

                Rectangle {
                    anchors.fill: parent
                    color: Serp.theme.surface0
                    radius: filePicker.crMedium
                    clip: true

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - Serp.s(32)
                        spacing: Serp.s(16)

                        Rectangle {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: Serp.s(80)
                            Layout.preferredHeight: Serp.s(80)
                            radius: filePicker.crLarge
                            color: Serp.theme.surface1

                            Text {
                                textFormat: Text.PlainText
                                anchors.centerIn: parent
                                text: "󰈔"
                                font.family: Serp.theme.iconFont
                                font.pixelSize: Serp.fs(36)
                                color: filePicker.selectedFilePath !== "" ? Serp.theme.mauve : Serp.theme.subtext0
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: Serp.s(4)

                            Text {
                                textFormat: Text.PlainText
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: {
                                    if (filePicker.selectedFileName !== "") {
                                        try {
                                            return decodeURIComponent(filePicker.selectedFileName);
                                        } catch (e) {
                                            return filePicker.selectedFileName;
                                        }
                                    }
                                    return true ? Serp.tr("guide.lyrics_picker.no_lyrics_selected", "No lyrics selected") : "No lyrics selected";
                                }
                                font.family: Serp.theme.fontFamily
                                font.weight: Font.Bold
                                font.pixelSize: Serp.fs(14)
                                color: filePicker.selectedFileName !== "" ? Serp.theme.text : Serp.theme.subtext0
                                elide: Text.ElideMiddle
                            }

                            Text {
                                textFormat: Text.PlainText
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                text: filePicker.selectedFilePath !== "" ? filePicker.selectedFilePath : ""
                                font.family: Serp.theme.fontFamily
                                font.pixelSize: Serp.fs(11)
                                color: Serp.theme.subtext0
                                elide: Text.ElideMiddle
                                visible: filePicker.selectedFilePath !== ""
                            }
                        }
                    }
                }
            }
        }
    }
}
