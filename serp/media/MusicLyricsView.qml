import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "../Serp.js" as Serp
import "../reusables"
import "../reusables/media"

Item {
    id: lyricsView
    required property var root
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: parent.width
    x: root.bottomSectionSwitch.currentIndex === 2 ? 0 : parent.width + root.s(24)
    opacity: root.bottomSectionSwitch.currentIndex === 2 ? 1.0 : 0.0
    visible: opacity > 0.0
    clip: true

    Behavior on x { NumberAnimation { duration: 400; easing.type: Easing.OutQuart } }
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

    LyricsView {
        id: popupLyricsViewport
        anchors.fill: parent
        visible: Serp.lyrics.hasLyrics
        sideMargin: root.s(4)
        baseActiveFont: root.fs(18)
        lineHeight: Math.max(root.s(30), baseActiveFont * 1.4)
        lineSpacing: Math.max(root.s(6), baseActiveFont * 0.25)
        activeLineColor: Serp.theme.mauve || root.dynamicTextColor
        inactiveLineColor: Serp.theme.text || "#cdd6f4"
        fontFamily: Serp.theme.fontFamily
    }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: root.s(6)
        visible: !Serp.lyrics.hasLyrics
        z: 5

        Text {
            textFormat: Text.PlainText
            Layout.alignment: Qt.AlignHCenter
            text: "󰎈"
            font.family: Serp.theme.iconFont
            font.pixelSize: root.fs(28)
            color: root.dynamicTextColor
            opacity: 0.75
        }

        Text {
            textFormat: Text.PlainText
            Layout.alignment: Qt.AlignHCenter
            text: {
                if (!root.hasTargetPlayer || !root.targetPlayer.trackTitle) return Serp.tr("music.nothing_playing");
                if (Serp.lyrics.loading) return Serp.tr("music.searching_lyrics");
                return Serp.tr("music.no_lyrics");
            }
            font.family: Serp.theme.fontFamily
            font.weight: Font.DemiBold
            font.pixelSize: root.fs(12)
            color: Serp.theme.subtext0 || "#a6adc8"
        }
    }
}
