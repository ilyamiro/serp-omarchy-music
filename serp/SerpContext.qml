import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import "services"
import "Serp.js" as Serp

Item {
    id: root
    visible: false

    property bool popupActive: false
    property bool sounds: true
    property int musicTab: 0

    signal closeRequested()

    function activate() {
        Serp.use(root);
    }

    Component.onDestruction: Serp.drop(root)

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t, a.g + (b.g - a.g) * t, a.b + (b.b - a.b) * t, 1.0);
    }

    readonly property color _bg: Commons.Color.popups.background
    readonly property color _fg: Commons.Color.popups.text
    readonly property color _accent: Commons.Color.accent

    readonly property color base: Qt.rgba(_bg.r, _bg.g, _bg.b, 1.0)
    readonly property color mantle: Qt.darker(base, 1.12)
    readonly property color crust: Qt.darker(base, 1.3)
    readonly property color surface0: mix(base, _fg, 0.10)
    readonly property color surface1: mix(base, _fg, 0.18)
    readonly property color surface2: mix(base, _fg, 0.26)
    readonly property color overlay0: mix(base, _fg, 0.40)
    readonly property color overlay1: mix(base, _fg, 0.50)
    readonly property color overlay2: mix(base, _fg, 0.60)
    readonly property color text: _fg
    readonly property color subtext1: mix(base, _fg, 0.85)
    readonly property color subtext0: mix(base, _fg, 0.72)
    readonly property color mauve: _accent
    readonly property color blue: mix(_accent, _fg, 0.25)
    readonly property color lavender: Qt.lighter(_accent, 1.15)
    readonly property color pink: mix(_accent, Commons.Color.urgent, 0.35)
    readonly property color peach: mix(_accent, Commons.Color.urgent, 0.6)
    readonly property color red: Commons.Color.urgent

    readonly property string fontFamily: Style.font.family
    readonly property string iconFont: Style.font.family
    readonly property int frameRadius: Style.cornerRadius
    readonly property int borderRadius: Math.max(Style.cornerRadius, 8)
    readonly property int clampedBorderRadius: Math.min(borderRadius, 24)
    readonly property real elementOpacity: _bg.a
    readonly property bool liquidGlass: false
    readonly property bool blurBackground: false

    readonly property bool rtl: Commons.I18n.rightToLeft
    readonly property int layoutDirection: rtl ? Qt.RightToLeft : Qt.LeftToRight
    readonly property int textAlignment: rtl ? Text.AlignRight : Text.AlignLeft

    readonly property string serpDir: String(Qt.resolvedUrl(".")).replace(/^file:\/\//, "").replace(/\/+$/, "")
    readonly property string home: Quickshell.env("HOME")
    readonly property string runDir: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/serpantinum"

    readonly property real uiScale: 0.8
    readonly property real fontScale: 0.8
    readonly property real minFontSize: 9

    function s(value) {
        let n = Number(value);
        return (n < 0 ? -Style.spaceReal(-n) : Style.spaceReal(n)) * uiScale;
    }

    function fs(value) {
        let n = Number(value);
        return n > 0 ? Math.max(minFontSize, Style.spaceReal(n) * fontScale) : 0;
    }

    function tr(key, args) {
        let fallback = typeof args === "string" ? args : key;
        let text = strings.t(key, fallback);
        if (args && typeof args === "object") {
            for (let k in args) text = text.split("{" + k + "}").join(String(args[k]));
        }
        return text;
    }

    Commons.Translations {
        id: strings
        directory: Qt.resolvedUrl("../i18n")
    }

    property bool audioInstalled: true

    function checkAudio() {
        if (!audioCheck.running) audioCheck.running = true;
    }

    function playSfx(file, volume) {
        if (!root.sounds || !file) return;
        let vol = Math.max(0.0, Math.min(2.0, volume === undefined ? 1.0 : Number(volume)));
        Quickshell.execDetached(["pw-play", "-P", "{\"application.id\":\"serpantinum-sfx\",\"application.name\":\"serpantinum-sfx\",\"media.role\":\"event\"}", "--volume=" + vol, serpDir + "/assets/sounds/" + file]);
    }

    function installAudio() {
        root.closeRequested();
        Quickshell.execDetached(["omarchy-launch-floating-terminal-with-presentation", "bash " + Util.shellQuote(serpDir + "/scripts/install-audio.sh")]);
    }

    onPopupActiveChanged: if (popupActive) checkAudio()

    Process {
        id: audioCheck
        command: ["sh", "-c", "PATH=\"$PATH:$HOME/.local/bin\" command -v serpantinum-audio >/dev/null"]
        onExited: (exitCode) => root.audioInstalled = exitCode === 0
    }

    Timer {
        interval: 3000
        repeat: true
        running: root.popupActive && !root.audioInstalled
        onTriggered: root.checkAudio()
    }

    readonly property alias mpris: mprisController
    readonly property alias spectrum: spectrumService
    readonly property alias lyrics: lyricsService

    MprisController {
        id: mprisController
        serpDir: root.serpDir
        enabled: root.popupActive
    }

    Spectrum {
        id: spectrumService
        mpris: mprisController
    }

    Lyrics {
        id: lyricsService
        mpris: mprisController
        home: root.home
    }
}
