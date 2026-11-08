#!/usr/bin/env gjs
import SystemGLib from 'gi://GLib';

// Headless checks of the shipped v76 methods. These do not simulate Mutter's
// allocation/monitor selection; fresh-login and monitor-hotplug tests remain manual.
const sourceDir = ARGV[0];
if (!sourceDir || !ARGV[1])
    throw new Error('Usage: test-blur-my-shell-takeover.js <extension-directory> <dconf-defaults>');

function load(relativePath, exports, dependencies = {}) {
    const [, bytes] = SystemGLib.file_get_contents(`${sourceDir}/${relativePath}`);
    const source = new TextDecoder().decode(bytes)
        .replace(/^import[\s\S]*?;\s*$/gm, '')
        .replace(/^export /gm, '');
    return new Function(...Object.keys(dependencies), `${source}\nreturn {${exports.join(',')}};`)(
        ...Object.values(dependencies));
}

function assert(condition, message) {
    if (!condition)
        throw new Error(message);
}

const monitors = [
    { index: 0, x: 2560, y: 0, width: 2560, height: 1440 },
    { index: 1, x: 0, y: 0, width: 2560, height: 1440 },
];
const Main = {
    layoutManager: {
        findMonitorForActor: actor => monitors[actor.monitorIndex],
    },
};

const { place_panel_background } = load(
    'components/panel/panel_background.js', ['place_panel_background'], { Main });
const { PanelBlur } = load('components/panel/index.js', ['PanelBlur']);

function actor(x, y, width, height, parent = null) {
    return {
        x, y, width, height, parent,
        get_position() { return [this.x, this.y]; },
        get_size() { return [this.width, this.height]; },
        get_allocation_box() {},
        get_parent() { return this.parent; },
        get_stage() { return true; },
    };
}

// A 48px taskbar inside a full-height DTP container must clip all 48px, on
// either monitor. Also check a subsequent height change and dynamic mode.
for (const monitor of monitors) {
    const root = actor(0, 0, 5120, 1440);
    const panelBox = actor(monitor.x, 0, 2560, 1440, root);
    const wrapper = actor(0, 1392, 2560, 48, panelBox);
    const panel = actor(0, 0, 2560, 48, wrapper);
    panel.monitorIndex = monitor.index;
    const background = { set_clip(...clip) { this.clip = clip; } };
    const actors = {
        widgets: { panel, panel_box: panelBox, wrapper, background },
        is_dtp_panel: true,
        static_blur: true,
    };
    assert(place_panel_background(actors), 'Allocated static panel must be placed');
    assert(background.clip.join(',') === '0,1392,2560,48',
        'Static blur must cover the full taskbar height on each monitor');
    panel.height = 64;
    wrapper.y = 1376;
    assert(place_panel_background(actors) && background.clip[3] === 64,
        'Static blur must follow taskbar height changes');
    actors.static_blur = false;
    assert(place_panel_background(actors) && background.height === 64 && background.y === 1376,
        'Dynamic blur must follow taskbar height and wrapper position');
    panel.height = 0;
    assert(!place_panel_background(actors), 'Unallocated panels must defer placement');
}

// The old bug retained stock-panel actors (and their wrong-monitor background)
// after DTP took ownership. Exercise v76's actual parent-set handler. Background
// creation/destruction are mocked: this checks lifecycle, not rendered wallpaper.
const callbacks = new Map();
const panel = actor(0, 0, 2560, 48);
const blur = Object.create(PanelBlur.prototype);
blur.watched_panels = new WeakSet();
blur.actors_list = [];
blur.connections = {
    connect(target, signal, callback) {
        assert(target === panel && signal === 'parent-set', 'Watch panel reparenting');
        callbacks.set(signal, callback);
    },
};
let destroyed = 0;
let created = 0;
blur.blur_panel = currentPanel => {
    created++;
    blur.actors_list.push({ widgets: { panel: currentPanel } });
};
blur.destroy_blur = actors => {
    destroyed++;
    blur.actors_list.splice(blur.actors_list.indexOf(actors), 1);
};
blur.maybe_blur_panel(panel);
const staleActors = blur.actors_list[0];
callbacks.get('parent-set')();
assert(destroyed === 1 && created === 2 && !blur.actors_list.includes(staleActors),
    'Reparenting must discard the stale stock-panel background');
blur.maybe_blur_panel(panel);
assert(created === 2, 'Repeated discovery must not duplicate an existing blur');
panel.get_stage = () => false;
callbacks.get('parent-set')();
assert(destroyed === 2 && created === 2 && blur.actors_list.length === 0,
    'Detached panels must discard blur without recreating it');

// System dconf values are not user values, so v76's legacy migration cannot
// be relied on to translate the image's application brightness default.
const defaults = new SystemGLib.KeyFile();
defaults.load_from_file(ARGV[1], SystemGLib.KeyFileFlags.NONE);
const pipelines = SystemGLib.Variant.parse(
    new SystemGLib.VariantType('a{sa{sv}}'),
    defaults.get_value('org/gnome/shell/extensions/blur-my-shell', 'pipelines'),
    null, null).recursiveUnpack();
const applicationPipeline = SystemGLib.Variant.parse(
    new SystemGLib.VariantType('s'),
    defaults.get_value('org/gnome/shell/extensions/blur-my-shell/applications', 'pipeline'),
    null, null).deepUnpack();
const effect = pipelines[applicationPipeline].effects[0];
assert(effect.type === 'dual_kawase_blur' && effect.params.unscaled_radius === 60 &&
    effect.params.brightness === 0.9,
    'Application pipeline must preserve the image blur radius and brightness');
assert(pipelines.pipeline_default.effects[0].params.brightness === 0.6,
    'Application brightness must not change other components');

print('Blur My Shell v76 geometry and reparenting checks passed');
