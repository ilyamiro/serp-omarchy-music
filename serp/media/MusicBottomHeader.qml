import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import "../Serp.js" as Serp
import "../reusables"

RowLayout {
    id: bottomHeader
    required property var root
    property alias bottomSectionSwitch: bottomSectionSwitch

    Layout.fillWidth: true
    opacity: root.introEqHeader
    transform: Translate { y: root.s(12) * (1 - root.introEqHeader) }

    Switch {
        id: bottomSectionSwitch
        Layout.preferredHeight: root.s(26)
        Layout.preferredWidth: root.fs(224)
        Layout.minimumWidth: root.fs(168)
        Layout.maximumWidth: root.fs(224)
        implicitHeight: root.s(26)
        implicitWidth: root.fs(224)
        horizontalPadding: root.s(10)
        minFontPixelSize: root.fs(7)
        options: [
            true ? Serp.tr("music.equalizer", "Equalizer") : "Equalizer",
            true ? Serp.tr("music.audio.title", "Audio") : "Audio",
            true ? Serp.tr("music.lyrics", "Lyrics") : "Lyrics"
        ]
        currentIndex: Serp.theme.musicTab
        accentColor: Serp.theme.mauve || "#cba6f7"
        baseColor: Qt.alpha(Serp.theme.surface0 || "#313244", Serp.theme.elementOpacity)
        textColor: Serp.theme.subtext0 || "#a6adc8"
        activeTextColor: Serp.theme.base || "#1e1e2e"
        cornerRadius: Serp.theme.borderRadius
        fontPixelSize: root.fs(11.5)
        onCurrentIndexChanged: {
            Serp.theme.musicTab = currentIndex;
            if (currentIndex !== 1 && root.audioTestRunning) {
                root.toggleAudioTest();
            }
            root.updateLyricsSubscription();
            if (currentIndex === 2) {
                root.toEqAnim.stop();
                root.toAudioAnim.stop();
                root.toLyricsAnim.restart();
                root.restoreLastSavedEqualizer();
            } else if (currentIndex === 1) {
                root.toEqAnim.stop();
                root.toLyricsAnim.stop();
                root.toAudioAnim.restart();
                root.playAudioIntro();
                root.restoreLastSavedEqualizer();
            } else {
                root.toLyricsAnim.stop();
                root.toAudioAnim.stop();
                root.restoreLastSavedEqualizer();
                root.toEqAnim.restart();
            }
        }
        onValueChanged: (index, val) => {
            currentIndex = index;
        }
    }

    Item { Layout.fillWidth: true }

    ClickButton {
        id: audioTestBtn
        Layout.preferredHeight: root.s(26)
        Layout.preferredWidth: root.audioTestBtnWidth * root.audioHeaderProgress
        implicitWidth: Layout.preferredWidth
        visible: root.audioHeaderProgress > 0.01
        opacity: root.audioHeaderProgress
        clip: true
        cornerRadius: Serp.theme.borderRadius
        horizontalPadding: root.s(8)
        buttonIcon: root.audioTestRunning ? "󰓛" : "󰋋"
        buttonText: root.audioTestRunning
            ? (true ? Serp.tr("music.audio.stop_test", "Stop") : "Stop")
            : (true ? Serp.tr("music.audio.test", "Test") : "Test")
        textFontSize: root.fs(11.5)
        iconFontSize: root.fs(12)
        accentColor: root.audioTestRunning
            ? (Serp.theme.mauve || "#cba6f7")
            : (Serp.theme.surface0 || "#313244")
        bgOpacity: Serp.theme.elementOpacity
        textColor: root.audioTestRunning
            ? (Serp.theme.base || "#1e1e2e")
            : (Serp.theme.text || "#cdd6f4")
        onClicked: root.toggleAudioTest()
    }

    ClickButton {
        id: dynamicEqBtn
        readonly property real showProgress: Math.max(0.0, 1.0 - root.actionBtnMorph)
        readonly property bool dynamicOn: !!root.eqData && root.eqData.dyneq === true
        Layout.preferredHeight: root.s(26)
        Layout.preferredWidth: root.dynamicEqBtnWidth * showProgress
        implicitWidth: Layout.preferredWidth
        visible: showProgress > 0.01
        opacity: showProgress
        clip: true
        cornerRadius: Serp.theme.borderRadius
        horizontalPadding: root.s(12)
        contentAlignment: Qt.AlignLeft
        buttonText: true ? Serp.tr("music.eq.dynamic", "Dynamic") : "Dynamic"
        textFontSize: root.fs(11.5)
        clickSound: dynamicEqToggle.toggleSound
        accentColor: Serp.theme.surface0 || "#313244"
        bgOpacity: Serp.theme.elementOpacity
        textColor: Serp.theme.text || "#cdd6f4"
        onClicked: root.setAudioFlag("dyneq", !dynamicOn)

        Toggle {
            id: dynamicEqToggle
            anchors.verticalCenter: parent.verticalCenter
            x: Serp.theme.rtl ? root.s(5) : parent.width - width - root.s(5)
            horizontalPadding: 0
            trackWidth: root.s(30)
            trackHeight: root.s(16)
            implicitHeight: trackHeight
            cornerRadius: Serp.theme.borderRadius
            checked: dynamicEqBtn.dynamicOn
            accentColor: Serp.theme.mauve || "#cba6f7"
            baseColor: Serp.theme.surface2 || "#585b70"
            onToggled: (isChecked) => {
                root.setAudioFlag("dyneq", isChecked);
                checked = Qt.binding(() => dynamicEqBtn.dynamicOn);
            }
        }
    }

    ClickButton {
        id: actionBtn
        Layout.preferredHeight: root.s(26)
        Layout.preferredWidth: root.actionBtnCurrentWidth
        implicitWidth: root.actionBtnCurrentWidth
        cornerRadius: Serp.theme.borderRadius
        horizontalPadding: root.s(12)
        buttonIcon: bottomSectionSwitch.currentIndex === 2
            ? "󰈔"
            : (bottomSectionSwitch.currentIndex === 1 ? "󰑐" : "")
        buttonText: {
            if (bottomSectionSwitch.currentIndex === 2) {
                return true ? Serp.tr("music.select_local_file", "Select file") : "Select file";
            }
            if (bottomSectionSwitch.currentIndex === 1) {
                return true ? Serp.tr("music.audio.reset", "Reset") : "Reset";
            }
            return root.eqData && root.eqData.pending ? Serp.tr("music.eq.apply") : Serp.tr("music.eq.saved");
        }
        textFontSize: root.fs(11.5)
        iconFontSize: root.fs(13)
        accentColor: {
            if (bottomSectionSwitch.currentIndex !== 0) {
                return Serp.theme.surface0 || "#313244";
            }
            return root.eqData && root.eqData.pending ? (Serp.theme.mauve || "#cba6f7") : (Serp.theme.surface0 || "#313244");
        }
        bgOpacity: Serp.theme.elementOpacity
        textColor: {
            if (bottomSectionSwitch.currentIndex !== 0) {
                return Serp.theme.text || "#cdd6f4";
            }
            return root.eqData && root.eqData.pending ? (Serp.theme.base || "#1e1e2e") : (Serp.theme.text || "#cdd6f4");
        }
        enabled: bottomSectionSwitch.currentIndex === 2
            ? (root.hasTargetPlayer && !Serp.lyrics.loading)
            : (bottomSectionSwitch.currentIndex === 1
                ? (Math.abs(root.balanceSlider.value) >= 0.005 || root.eqData.mono === true || root.eqData.swap === true || String(root.eqData.dynamics || "off") !== "off")
                : !(root.eqData && root.eqData.dyneq === true))
        opacity: bottomSectionSwitch.currentIndex === 2
            ? (root.hasTargetPlayer && !Serp.lyrics.loading ? 1.0 : 0.45)
            : (enabled ? 1.0 : 0.45)
        Behavior on opacity { NumberAnimation { duration: 250 } }
        Behavior on accentColor { ColorAnimation { duration: 250 } }
        Behavior on textColor { ColorAnimation { duration: 250 } }
        onClicked: {
            if (bottomSectionSwitch.currentIndex === 2) {
                root.lyricsPickerPopup.targetScreen = (root.Window && root.Window.window) ? root.Window.window.screen : null;
                root.lyricsPickerPopup.openPicker();
            } else if (bottomSectionSwitch.currentIndex === 1) {
                root.resetAudio();
            } else if (root.eqData && root.eqData.pending) {
                var temp = Object.assign({}, root.eqData);
                temp.pending = false;
                root.eqData = temp;
                root.savedEqData = Object.assign({}, temp);
                root.lastEqUpdate = Date.now();
                root.triggerEqLightning();
                root.execCmd(Serp.theme.serpDir + "/media/equalizer.sh apply");
            }
        }
    }

    Item {
        id: presetTextContainer
        Layout.preferredHeight: root.s(26)
        Layout.preferredWidth: (presetLabelText.implicitWidth + root.s(12)) * Math.max(0.0, 1.0 - root.presetSlideProgress)
        implicitWidth: Layout.preferredWidth
        visible: root.presetSlideProgress < 0.99
        opacity: Math.max(0.0, 1.0 - root.presetSlideProgress)
        clip: true

        Text {
            textFormat: Text.PlainText
            id: presetLabelText
            anchors.verticalCenter: parent.verticalCenter
            x: root.s(12) + (root.s(24) * root.presetSlideProgress)
            text: root.eqData && root.eqData.preset ? Serp.tr("music.presets." + root.eqData.preset.toLowerCase()) : Serp.tr("music.presets.flat")
            color: Serp.theme.subtext0 || "#a6adc8"
            font.family: Serp.theme.fontFamily
            font.pixelSize: root.fs(13)
            font.bold: true
        }
    }
}
