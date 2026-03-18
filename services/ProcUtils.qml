// ProcUtils — Process lifecycle helpers
//
// Provides simple start()/stop() wrappers for Process objects.
// These exist to guard against starting a Process that is already
// running, or stopping one that has already finished, which can
// trigger warnings in QuickShell.

pragma Singleton

import QtQuick

QtObject {
    function start(proc) {
        if (proc && !proc.running)
            proc.running = true;
    }

    function stop(proc) {
        if (proc && proc.running)
            proc.running = false;
    }
}
