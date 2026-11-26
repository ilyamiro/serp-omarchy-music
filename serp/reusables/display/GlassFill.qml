import QtQuick

Item {
    readonly property bool active: false
    property var backdrop: null
    property var backdropOverride: null
    property bool allowed: false
    property bool followBackdropHover: false
    property bool forceClear: false
    property real press: 0
    property real pulse: 0
    property real radius: 0
    property real topLeftRadius: radius
    property real topRightRadius: radius
    property real bottomLeftRadius: radius
    property real bottomRightRadius: radius
    property real shadow: 0
    property real tintAmount: 0
    property color tintColor: "transparent"
    property real tintStrength: 0
    visible: false
}
