import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "serp"
import "serp/media"

BarWidget {
  id: root
  moduleName: "ilyamiro.serpantinum-music"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property bool popupOpen: false
  function close() { popupOpen = false }
  function open() {
    serpCtx.activate()
    popupOpen = true
  }
  function toggle() { popupOpen ? close() : open() }

  Commons.Translations { id: strings; directory: Qt.resolvedUrl("i18n") }

  SerpContext {
    id: serpCtx
    popupActive: root.popupOpen
    sounds: root.setting("sounds", true)
    onCloseRequested: root.close()
  }

  ShellIpc {
    target: root.moduleName

    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
  }

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: serpCtx.mpris.isPlaying ? "󰎈" : "󰝚"
    tooltipText: strings.t("tooltip")
    onPressed: function(mouseButton) { root.toggle() }
  }

  PopupCard {
    id: popup
    anchorItem: root
    bar: root.bar
    owner: root
    open: root.popupOpen
    padding: 0
    borderSpec: Border.none()
    contentWidth: popup.fittedContentWidth(serpCtx.s(625))
    contentHeight: popup.fittedContentHeight(serpCtx.s(565))

    Item {
      anchors.fill: parent

      Loader {
        anchors.fill: parent
        active: popup.visible
        sourceComponent: MusicPopup {
          visible: true
          active: root.popupOpen
        }
      }

      Shortcut {
        sequence: "Escape"
        enabled: root.popupOpen
        onActivated: root.close()
      }
    }
  }
}
