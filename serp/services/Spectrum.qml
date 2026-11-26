import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root
    visible: false

    property var mpris: null

    property int barCount: 64
    readonly property var emptyLevels: {
        let arr = [];
        for (let i = 0; i < barCount; i++) arr.push(0.0);
        return Object.freeze(arr);
    }
    property var barLevels: emptyLevels
    property int activeConsumers: 0
    property bool isPlaying: !!mpris && mpris.isPlaying
    property bool isDecaying: false
    property bool isRestarting: false
    property int consecutiveCrashes: 0
    property bool processEnabled: activeConsumers > 0 && (isPlaying || isDecaying) && !isRestarting

    function registerConsumer() {
        activeConsumers++;
    }

    function unregisterConsumer() {
        activeConsumers = Math.max(0, activeConsumers - 1);
    }

    function resetBars() {
        root.barLevels = root.emptyLevels;
    }

    function restartVisualizer() {
        if (!processEnabled || consecutiveCrashes >= 5) return;
        consecutiveCrashes++;
        isRestarting = true;
        restartTimer.restart();
    }

    onActiveConsumersChanged: {
        if (activeConsumers === 0) {
            root.isDecaying = false;
            decayTimer.stop();
        }
    }

    onIsPlayingChanged: {
        if (isPlaying) {
            root.isDecaying = false;
            decayTimer.stop();
        } else if (activeConsumers > 0) {
            root.isDecaying = true;
            decayTimer.restart();
        } else {
            root.isDecaying = false;
            decayTimer.stop();
            resetBars();
        }
    }

    onProcessEnabledChanged: {
        if (!processEnabled) {
            if (!root.isRestarting) root.consecutiveCrashes = 0;
            resetBars();
        }
    }

    Timer {
        id: decayTimer
        interval: 1200
        repeat: false
        onTriggered: root.isDecaying = false
    }

    Timer {
        id: restartTimer
        interval: 500
        repeat: false
        onTriggered: root.isRestarting = false
    }

    Process {
        id: visualizerProcess
        running: root.processEnabled
        onExited: root.restartVisualizer()
        command: ["sh", "-c", "PATH=\"$PATH:$HOME/.local/bin\" exec serpantinum-audio visualizer --bars \"$1\" --framerate 60 --sensitivity 150", "sh", String(root.barCount)]
        stdout: SplitParser {
            onRead: data => {
                if (!root.processEnabled) return;
                let levels;
                try {
                    levels = JSON.parse(data);
                } catch (e) {
                    return;
                }
                if (!Array.isArray(levels) || levels.length !== root.barCount) return;
                root.consecutiveCrashes = 0;
                root.barLevels = levels;
            }
        }
    }
}
