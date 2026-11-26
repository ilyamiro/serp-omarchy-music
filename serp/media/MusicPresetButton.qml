import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import "../Serp.js" as Serp
import "../reusables"

ClickButton {
    required property var root
    property string name: ""
    bgOpacity: Serp.theme.elementOpacity
    Layout.fillWidth: true
    Layout.preferredWidth: 1
    implicitHeight: root.s(28)
    cornerRadius: Serp.theme.borderRadius
    buttonText: Serp.tr("music.presets." + name.toLowerCase())
    textFontSize: root.fs(11.5)
    horizontalPadding: 0
    property bool isActivePreset: root.eqData && root.eqData.preset === name
    accentColor: isActivePreset ? (Serp.theme.mauve || "#cba6f7") : (Serp.theme.surface0 || "#313244")
    textColor: isActivePreset ? (Serp.theme.base || "#1e1e2e") : (Serp.theme.subtext0 || "#a6adc8")
    onClicked: root.applyPresetOptimistically(name)
}
