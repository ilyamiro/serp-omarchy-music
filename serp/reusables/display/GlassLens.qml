import QtQuick

Item {
    readonly property bool glassActive: false
    property var backdropOverride: null
    property bool followBackdropHover: false
    property bool forceClear: false
    property bool instant: false
    property int fastDuration: 0
    property int slowDuration: 0
    property real press: 0
    property real restPress: 0
    property real radius: 0
    property real shadow: 0
    property real targetX: 0
    property real targetY: 0
    property real targetWidth: 0
    property real targetHeight: 0
    property real tintAmount: 0
    property color tintColor: "transparent"
    property real tintStrength: 0
    visible: false
}
