pragma Singleton

import QtQuick
import Quickshell
import "ActivityLogic.js" as ActivityLogic

Singleton {
    id: root

    property var providerActivities: ({})
    property var activities: []
    readonly property int activeCount: root.activities.length

    signal actionRequested(string provider, string activityId, string actionId)

    function rebuild() {
        root.activities = ActivityLogic.flattenProviders(root.providerActivities);
    }

    function publish(providerValue, suppliedValue) {
        var provider = ActivityLogic.normalizedProvider(providerValue);
        var supplied = suppliedValue || ({});
        var id = ActivityLogic.normalizedId(supplied.id);
        var state = ActivityLogic.normalizedState(supplied.state);
        if (id === "" || state === "")
            return false;

        var providers = Object.assign({}, root.providerActivities);
        var entries = Object.assign({}, providers[provider] || ({}));
        var entry = ActivityLogic.normalizeEntry(provider, supplied, entries[id], Date.now());
        if (entry)
            entries[id] = entry;
        else
            delete entries[id];

        providers[provider] = entries;
        root.providerActivities = providers;
        root.rebuild();
        return entry !== null;
    }

    function replaceProvider(providerValue, suppliedEntries) {
        var provider = ActivityLogic.normalizedProvider(providerValue);
        var providers = Object.assign({}, root.providerActivities);
        var previous = providers[provider] || ({});
        var next = ({});
        var source = Array.isArray(suppliedEntries) ? suppliedEntries : [];
        var now = Date.now();

        for (var i = 0; i < source.length; i++) {
            var supplied = source[i] || ({});
            var id = ActivityLogic.normalizedId(supplied.id);
            var entry = ActivityLogic.normalizeEntry(provider, supplied, previous[id], now);
            if (entry)
                next[id] = entry;
        }

        providers[provider] = next;
        root.providerActivities = providers;
        root.rebuild();
    }

    function clear(providerValue, activityIdValue) {
        var provider = ActivityLogic.normalizedProvider(providerValue);
        var activityId = ActivityLogic.normalizedId(activityIdValue);
        var providers = Object.assign({}, root.providerActivities);
        var entries = Object.assign({}, providers[provider] || ({}));
        if (!Object.prototype.hasOwnProperty.call(entries, activityId))
            return false;

        delete entries[activityId];
        providers[provider] = entries;
        root.providerActivities = providers;
        root.rebuild();
        return true;
    }

    function clearProvider(providerValue) {
        var provider = ActivityLogic.normalizedProvider(providerValue);
        if (!Object.prototype.hasOwnProperty.call(root.providerActivities, provider))
            return;
        var providers = Object.assign({}, root.providerActivities);
        delete providers[provider];
        root.providerActivities = providers;
        root.rebuild();
    }

    function requestAction(providerValue, activityIdValue, actionIdValue) {
        var provider = ActivityLogic.normalizedProvider(providerValue);
        var activityId = ActivityLogic.normalizedId(activityIdValue);
        var actionId = ActivityLogic.normalizedId(actionIdValue);
        var entries = root.providerActivities[provider] || ({});
        var entry = entries[activityId];
        if (!entry)
            return false;

        for (var i = 0; i < entry.actions.length; i++) {
            if (entry.actions[i].id === actionId) {
                root.actionRequested(provider, activityId, actionId);
                return true;
            }
        }
        return false;
    }

    function elapsedText(startedAt, now) {
        return ActivityLogic.elapsedText(startedAt, now);
    }

    function listJson() {
        return JSON.stringify(root.activities);
    }
}
