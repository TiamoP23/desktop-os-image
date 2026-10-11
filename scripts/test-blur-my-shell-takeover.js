#!/usr/bin/env gjs
import SystemGLib from 'gi://GLib';
import { Connections } from '../vendor/extensions/blur-my-shell/src/conveniences/connections.js';

const idleCallbacks = [];
const timeouts = [];
const createdBackgrounds = [];
let nextSignalId = 1;

class SignalActor {
    constructor(name = undefined, position = [0, 0], size = [0, 0]) {
        this.name = name;
        this.position = position;
        this.size = size;
        this.children = [];
        this.styleClasses = new Set();
        this._signals = new Map();
    }

    connect(signal, callback) {
        const id = nextSignalId++;
        this._signals.set(id, { signal, callback });
        return id;
    }

    disconnect(id) {
        this._signals.delete(id);
    }

    emit(signal, ...args) {
        for (const { signal: connectedSignal, callback } of [...this._signals.values()]) {
            if (connectedSignal === signal)
                callback(this, ...args);
        }
    }

    countSignal(signal) {
        return [...this._signals.values()].filter(
            connection => connection.signal === signal
        ).length;
    }

    get_parent() {
        return this.parent;
    }

    get_position() {
        return [...this.position];
    }

    get_size() {
        return [...this.size];
    }

    get_name() {
        return this.name;
    }

    get_children() {
        return [...this.children];
    }

    get_n_children() {
        return this.children.length;
    }

    get_child_at_index(index) {
        return this.children[index];
    }

    insert_child_at_index(child, index) {
        this.children.splice(index, 0, child);
        child.parent = this;
    }

    remove_child(child) {
        this.children = this.children.filter(existing => existing !== child);
        child.parent = null;
    }

    destroy_all_children() {
        this.children = [];
    }

    destroy() {
        this.destroyed = true;
        this.emit('destroy');
    }

    add_style_class_name(style) {
        this.styleClasses.add(style);
    }

    remove_style_class_name(style) {
        this.styleClasses.delete(style);
    }

    has_style_class_name(style) {
        return this.styleClasses.has(style);
    }
}

const Main = {
    panel: new SignalActor('main-panel'),
    extensionManager: new SignalActor('extension-manager'),
    layoutManager: null,
    uiGroup: new SignalActor('ui-group'),
    overview: new SignalActor('overview'),
    sessionMode: new SignalActor('session-mode'),
};
Main.overview.visible = false;
Main.overview._overview = {
    _controls: { _appDisplay: new SignalActor('app-display') },
};

const global = {
    dashToPanel: null,
    display: new SignalActor('display'),
    window_group: new SignalActor('window-group'),
    window_manager: new SignalActor('window-manager'),
};

globalThis.setTimeout = callback => {
    timeouts.push(callback);
    return timeouts.length;
};

const GLib = {
    PRIORITY_DEFAULT_IDLE: 0,
    SOURCE_REMOVE: 0,
    idle_add(_priority, callback) {
        idleCallbacks.push(callback);
        return idleCallbacks.length;
    },
};

const Meta = {
    BackgroundGroup: class BackgroundGroup extends SignalActor {
        constructor(properties) {
            super(properties.name);
            this.properties = properties;
        }
    },
};

class Pipeline {
    constructor() {}

    create_background_with_effects(monitorIndex, managerList, group, name) {
        const background = makeBackground(name);
        const bgManager = makeBackgroundManager(monitorIndex);
        managerList.push(bgManager);
        group.insert_child_at_index(background, 0);
        createdBackgrounds.push({ background, bgManager });
        return background;
    }
}

class DummyPipeline {
    constructor(_effectsManager, _settings) {}

    create_background_with_effect(group, name) {
        const background = makeBackground(name);
        const bgManager = makeBackgroundManager(undefined);
        group.insert_child_at_index(background, 0);
        createdBackgrounds.push({ background, bgManager });
        return [background, bgManager];
    }
}

class PaintSignals {
    constructor() {}
    disconnect_all() {}
    connect() {}
}

const utils = {
    static_blur_clip_inset() {
        return 0;
    },
    subpixel_stage_offset() {
        return 0;
    },
};

function makeBackground(name) {
    const background = new SignalActor(name);
    background.set_clip = (...clip) => {
        background.clip = clip;
    };
    background.show = () => {
        background.visible = true;
    };
    background.hide = () => {
        background.visible = false;
    };
    return background;
}

function makeBackgroundManager(monitorIndex) {
    return {
        _monitorIndex: monitorIndex,
        _bms_pipeline: {
            destroy() {
                this.destroyed = true;
            },
        },
        destroy() {
            this.destroyed = true;
        },
    };
}

const sourcePath = ARGV[0];
if (!sourcePath)
    throw new Error('Usage: test-blur-my-shell-takeover.js <panel.js> [--mutate-blur-panel]');

const [ok, sourceBytes] = SystemGLib.file_get_contents(sourcePath);
if (!ok)
    throw new Error(`Unable to read PanelBlur source: ${sourcePath}`);

let source = new TextDecoder().decode(sourceBytes);
if (ARGV.includes('--mutate-blur-panel')) {
    const method = '    blur_panel(panel) {';
    if (!source.includes(method))
        throw new Error('Cannot inject blur_panel mutation: method marker was not found');
    source = source.replace(
        method,
        `${method}\n        throw new Error('Injected test mutation: blur_panel must execute');`
    );
}
source = source
    .replace(/^import .*;\s*$/gm, '')
    .replace('export const PanelBlur = class PanelBlur', 'const PanelBlur = class PanelBlur');
eval(`${source}\nglobalThis.__PanelBlur = PanelBlur;`);

function assert(condition, message) {
    if (!condition)
        throw new Error(`Assertion failed: ${message}`);
}

function defaultSettings() {
    return {
        DEBUG: false,
        HACKS_LEVEL: 0,
        panel: {
            STATIC_BLUR: true,
            BLUR: false,
            UNBLUR_IN_OVERVIEW: false,
            OVERRIDE_BACKGROUND: false,
            OVERRIDE_BACKGROUND_DYNAMICALLY: false,
            FORCE_LIGHT_TEXT: false,
        },
        dash_to_panel: { BLUR_ORIGINAL_PANEL: true },
        hidetopbar: { COMPATIBILITY: false },
    };
}

function makePanel(name) {
    return new SignalActor(name, [0, 0], [2560, 48]);
}

function setMonitors() {
    const monitors = [
        { index: 0, x: 2560, y: 0, width: 2560, height: 1440 },
        { index: 1, x: 0, y: 0, width: 2560, height: 1440 },
    ];
    Main.layoutManager = new SignalActor('layout-manager');
    Main.layoutManager.monitors = monitors;
    Main.layoutManager.primaryMonitor = monitors[0];
    Main.layoutManager.findMonitorForActor = actor =>
        monitors.find(monitor => monitor.index === actor.monitor?.index) ?? monitors[0];
    return monitors;
}

function makeTopology(panel, monitorIndex, monitorX) {
    const root = new SignalActor(`monitor-root-${monitorIndex}`, [0, 0], [5120, 1440]);
    const panelBox = new SignalActor('panelBox', [monitorX, 0], [2560, 1440]);
    panelBox._dtpIndex = monitorIndex;
    panelBox.parent = root;

    const wrapper = new SignalActor(undefined, [0, 0], [2560, 1440]);
    wrapper.panel = panel;
    wrapper.monitor = Main.layoutManager.monitors[monitorIndex];
    wrapper.parent = panelBox;

    panel.position = [0, 1392];
    panel.size = [2560, 48];
    panel.monitor = Main.layoutManager.monitors[monitorIndex];
    panel.parent = wrapper;

    return { panel, wrapper, panelBox, root, monitorIndex, monitorX };
}

function makeDashToPanel(topologies) {
    const dtp = new SignalActor('dash-to-panel');
    dtp.panels = topologies.map(topology => topology.wrapper);
    return dtp;
}

function makeStoredBlur(topology, wrapper, staticBlur, backgroundMonitorIndex) {
    const backgroundGroup = new Meta.BackgroundGroup({ name: 'old-panel-background-group' });
    const background = makeBackground('old-panel-background');
    topology.panelBox.insert_child_at_index(backgroundGroup, 0);
    backgroundGroup.insert_child_at_index(background, 0);
    const bgManager = makeBackgroundManager(backgroundMonitorIndex);
    return {
        widgets: {
            panel: topology.panel,
            wrapper,
            panel_box: topology.panelBox,
            background,
            background_group: backgroundGroup,
            geometry_actor: topology.panel,
        },
        static_blur: staticBlur,
        monitor: { index: topology.monitorIndex },
        bg_manager: bgManager,
        is_dtp_panel: Boolean(wrapper),
    };
}

function setup() {
    idleCallbacks.length = 0;
    timeouts.length = 0;
    createdBackgrounds.length = 0;
    nextSignalId = 1;
    Main.panel = makePanel('main-panel');
    Main.extensionManager = new SignalActor('extension-manager');
    Main.uiGroup = new SignalActor('ui-group');
    Main.overview = new SignalActor('overview');
    Main.overview.visible = false;
    Main.overview._overview = {
        _controls: { _appDisplay: new SignalActor('app-display') },
    };
    Main.sessionMode = new SignalActor('session-mode');
    setMonitors();
    global.dashToPanel = null;
    global.blur_my_shell = { _pipelines_manager: {} };
    global.display = new SignalActor('display');
    global.window_group = new SignalActor('window-group');
    global.window_manager = new SignalActor('window-manager');

    return new globalThis.__PanelBlur(new Connections(), defaultSettings(), {});
}

function trackResets(blur) {
    let count = 0;
    const reset = blur.reset.bind(blur);
    blur.reset = () => {
        count++;
        reset();
    };
    return () => count;
}

function drainWorkQueue(maxSteps = 100) {
    let steps = 0;
    while (idleCallbacks.length || timeouts.length) {
        if (++steps > maxSteps) {
            throw new Error(
                `Work queue exceeded ${maxSteps} callbacks ` +
                `(idle=${idleCallbacks.length}, timeout=${timeouts.length})`
            );
        }

        const callback = idleCallbacks.length ? idleCallbacks.shift() : timeouts.shift();
        callback();
    }
    return steps;
}

function assertBindings(blur, topologies, messagePrefix) {
    assert(blur.actors_list.length === topologies.length,
        `${messagePrefix}: expected one blur actor per Dash to Panel panel`);

    for (const topology of topologies) {
        const actors = blur.actors_list.find(
            item => item.widgets.panel === topology.panel
        );
        assert(actors, `${messagePrefix}: missing panel blur actor`);
        assert(actors.widgets.wrapper === topology.wrapper,
            `${messagePrefix}: blur actor must bind the current DTP wrapper`);
        assert(actors.is_dtp_panel,
            `${messagePrefix}: rebuilt blur must be marked as a DTP panel`);
        assert(actors.bg_manager._monitorIndex === topology.monitorIndex,
            `${messagePrefix}: background must be constructed for the assigned monitor`);
        assert(actors.widgets.background.clip?.[0] === 0 &&
            actors.widgets.background.clip?.[1] === 1391 &&
            actors.widgets.background.clip?.[2] === 2560 &&
            actors.widgets.background.clip?.[3] === 49,
        `${messagePrefix}: update_size must clip the 48px panel at the monitor edge`);
    }
}

function assertSingleDtpListener(dtp, message) {
    assert(dtp.countSignal('panels-created') === 1, message);
}

function testTakeoverRebuildsAndRemainsStable() {
    const blur = setup();
    const primary = Main.panel;
    const secondary = makePanel('secondary-panel');
    const topologies = [
        makeTopology(primary, 0, 2560),
        makeTopology(secondary, 1, 0),
    ];
    const oldPrimary = makeStoredBlur(topologies[0], null, true, 1);
    oldPrimary.widgets.background.clip = [0, 1391, 2560, 49];
    oldPrimary.widgets.panel_position = [2560, 1392];
    const oldSecondary = makeStoredBlur(topologies[1], topologies[1].wrapper, true, 1);
    blur.actors_list = [oldPrimary, oldSecondary];
    const dtp = makeDashToPanel(topologies);
    global.dashToPanel = dtp;
    const resets = trackResets(blur);

    blur.enable();
    drainWorkQueue();

    assert(resets() === 1, 'takeover must perform exactly one complete reset');
    assert(oldPrimary.bg_manager.destroyed && oldSecondary.bg_manager.destroyed,
        'reset must destroy both old background managers');
    assertBindings(blur, topologies, 'takeover rebuild');
    assert(createdBackgrounds.length === 2,
        'actual blur_panel must construct backgrounds for both primary and secondary panels');
    assertSingleDtpListener(dtp, 'reset/re-enable must install one panels-created listener');
    assert(Main.extensionManager.countSignal('extension-state-changed') === 1,
        're-enable must retain one extension state listener');

    const primaryActors = blur.actors_list.find(actor => actor.widgets.panel === primary);
    primary.position = [0, 1391];
    primary.emit('notify::position');
    drainWorkQueue();
    assert(primaryActors.widgets.background.clip[1] === 1390,
        'real actor geometry notification must run update_size and move the clip');
    primary.position = [0, 1392];
    primary.emit('notify::position');
    drainWorkQueue();
    assertBindings(blur, topologies, 'geometry signal restore');

    const stableActors = [...blur.actors_list];
    dtp.emit('panels-created');
    drainWorkQueue();
    assert(resets() === 1,
        'an unchanged panels-created event after reset must not trigger another reset');
    assert(blur.actors_list.length === stableActors.length &&
        blur.actors_list.every(actor => stableActors.includes(actor)),
    'unchanged panels-created event must not duplicate blur actors');
    assertSingleDtpListener(dtp,
        'an unchanged panels-created event must not duplicate its subscription');

    const remappedTopologies = topologies.map(topology =>
        makeTopology(topology.panel, topology.monitorIndex, topology.monitorX)
    );
    const replacementDtp = makeDashToPanel(remappedTopologies);
    global.dashToPanel = replacementDtp;
    blur.blur_existing_panels();
    drainWorkQueue();

    assert(resets() === 2,
        'replacement DTP wrappers must trigger one reset to remap existing actors');
    assert(stableActors.every(actor => actor.bg_manager.destroyed),
        'wrapper remapping must destroy the pre-replacement background managers');
    assertBindings(blur, remappedTopologies, 'replacement wrapper rebuild');
    assert(dtp.countSignal('panels-created') === 0,
        'replacement DTP object must disconnect the old panels-created listener');
    assertSingleDtpListener(replacementDtp,
        'replacement DTP object must have exactly one panels-created listener');

    const remappedActors = [...blur.actors_list];
    replacementDtp.emit('panels-created');
    drainWorkQueue();
    assert(resets() === 2,
        'unchanged replacement wrappers must remain stable after their event');
    assert(blur.actors_list.length === remappedActors.length &&
        blur.actors_list.every(actor => remappedActors.includes(actor)),
    'replacement DTP event must not duplicate remapped actors');
    assertSingleDtpListener(replacementDtp,
        'replacement DTP event must not add another listener');
}

function testCorrectStaticBindingIsReusedForMainPanel() {
    const blur = setup();
    const topology = makeTopology(Main.panel, 0, 2560);
    const existing = makeStoredBlur(topology, topology.wrapper, true, 0);
    blur.actors_list = [existing];
    blur.enabled = true;
    const dtp = makeDashToPanel([topology]);
    global.dashToPanel = dtp;

    blur.blur_existing_panels();
    drainWorkQueue();

    assert(blur.actors_list.length === 1 && blur.actors_list[0] === existing,
        'correct primary-panel wrapper and monitor binding must be reused');
    assert(!existing.bg_manager.destroyed && createdBackgrounds.length === 0,
        'reusing a correct main-panel binding must not rebuild its blur');
    assertSingleDtpListener(dtp, 'reusing a correct binding must retain one listener');
}

function testWrongStaticMonitorResetsEvenWithCorrectWrapper() {
    const blur = setup();
    const topology = makeTopology(Main.panel, 0, 2560);
    const existing = makeStoredBlur(topology, topology.wrapper, true, 1);
    blur.actors_list = [existing];
    blur.enabled = true;
    const dtp = makeDashToPanel([topology]);
    global.dashToPanel = dtp;
    const resets = trackResets(blur);

    blur.blur_existing_panels();
    drainWorkQueue();

    assert(resets() === 1 && existing.bg_manager.destroyed,
        'static background bound to the wrong monitor must force a full reset');
    assertBindings(blur, [topology], 'static monitor mismatch rebuild');
    assertSingleDtpListener(dtp,
        'static monitor mismatch reset must reconnect exactly one DTP listener');
}

function testDynamicBlurDoesNotRequireMonitorIndex() {
    const blur = setup();
    const topology = makeTopology(Main.panel, 0, 2560);
    const existing = makeStoredBlur(topology, topology.wrapper, false, undefined);
    blur.actors_list = [existing];
    blur.enabled = true;
    const dtp = makeDashToPanel([topology]);
    global.dashToPanel = dtp;
    const resets = trackResets(blur);

    blur.blur_existing_panels();
    drainWorkQueue();

    assert(resets() === 0 && blur.actors_list[0] === existing,
        'dynamic blur with a correct wrapper must be reused without monitor metadata');
    assert(existing.bg_manager._monitorIndex === undefined &&
        !existing.bg_manager.destroyed && createdBackgrounds.length === 0,
    'dynamic background without _monitorIndex must not trigger a reset');
}

function testPendingIdleDoesNothingAfterDisable() {
    const blur = setup();
    const topology = makeTopology(Main.panel, 0, 2560);
    global.dashToPanel = makeDashToPanel([topology]);

    blur.enable();
    assert(idleCallbacks.length === 1,
        'enable must queue the Dash to Panel idle callback before the disable');
    blur.disable();
    drainWorkQueue();

    assert(blur.actors_list.length === 0 && createdBackgrounds.length === 0,
        'disabled pending callback must not call blur_panel or create backgrounds');
    assert(global.dashToPanel.countSignal('panels-created') === 0,
        'disable must disconnect its real panels-created signal handler');
}

testTakeoverRebuildsAndRemainsStable();
testCorrectStaticBindingIsReusedForMainPanel();
testWrongStaticMonitorResetsEvenWithCorrectWrapper();
testDynamicBlurDoesNotRequireMonitorIndex();
testPendingIdleDoesNothingAfterDisable();
print('Blur My Shell Dash to Panel takeover regression tests passed');
