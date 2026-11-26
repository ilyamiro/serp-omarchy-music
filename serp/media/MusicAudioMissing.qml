import QtQuick
import QtQuick.Layouts
import "../Serp.js" as Serp
import "../reusables"

Item {
    id: missing
    required property var root
    anchors.fill: parent
    z: 20
    visible: !Serp.theme.audioInstalled

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        onWheel: (wheel) => wheel.accepted = true
    }

    Rectangle {
        anchors.fill: parent
        radius: Serp.theme.borderRadius
        color: Qt.alpha(Serp.theme.base, 0.85)
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - missing.root.s(48)
        spacing: missing.root.s(8)

        Text {
            Layout.alignment: Qt.AlignHCenter
            textFormat: Text.PlainText
            text: "󰓃"
            font.family: Serp.theme.iconFont
            font.pixelSize: missing.root.fs(28)
            color: Serp.theme.mauve
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            text: Serp.tr("music.audio.missing", "serpantinum-audio isn't installed")
            font.family: Serp.theme.fontFamily
            font.pixelSize: missing.root.fs(15)
            font.bold: true
            color: Serp.theme.text
        }

        Text {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            textFormat: Text.PlainText
            wrapMode: Text.WordWrap
            text: Serp.tr("music.audio.missing_hint", "The equalizer, audio settings and visualizer run on it. It installs to your home folder, no password needed.")
            font.family: Serp.theme.fontFamily
            font.pixelSize: missing.root.fs(11.5)
            color: Serp.theme.subtext0
        }

        ClickButton {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: missing.root.s(6)
            Layout.preferredHeight: missing.root.s(30)
            cornerRadius: Serp.theme.borderRadius
            horizontalPadding: missing.root.s(14)
            buttonIcon: "󰇚"
            buttonText: Serp.tr("music.audio.install", "Install")
            textFontSize: missing.root.fs(12)
            iconFontSize: missing.root.fs(13)
            accentColor: Serp.theme.mauve
            textColor: Serp.theme.base
            onClicked: Serp.theme.installAudio()
        }
    }
}
