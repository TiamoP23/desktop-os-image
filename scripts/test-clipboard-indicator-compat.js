#!/usr/bin/env gjs
import GLib from 'gi://GLib';

function load(name, exported, dependencies) {
    const [, bytes] = GLib.file_get_contents(`${ARGV[0]}/${name}`);
    const source = new TextDecoder().decode(bytes)
        .replace(/^import .*;\s*$/gm, '').replace(/^export /gm, '');
    return new Function(...Object.keys(dependencies), `${source}\nreturn ${exported};`)(
        ...Object.values(dependencies));
}

function assert(condition, message) {
    if (!condition)
        throw new Error(message);
}

const Clutter = {
    Orientation: { VERTICAL: 1, HORIZONTAL: 0 },
    InputDeviceType: { KEYBOARD_DEVICE: 1 },
};
const St = { BoxLayout: class {} };
const orientation = load('compat.js', 'boxLayoutOrientation', { Clutter, St });
assert(orientation(true).vertical === true, 'Older shells must retain vertical layout');
St.BoxLayout.prototype.orientation = 0;
assert(orientation(true).orientation === 1 && orientation(false).orientation === 0,
    'GNOME 51 must use orientation for both directions');
assert(!Object.hasOwn(orientation(true), 'vertical'), 'Do not pass vertical on GNOME 51');

let devices = 0;
const backend = {
    get_default_seat: () => ({ create_virtual_device: () => { devices++; return {}; } }),
};
const global = { stage: { context: { get_backend: () => backend } } };
const Main = { inputMethod: { connectObject() {} } };
const Keyboard = load('keyboard.js', 'Keyboard', { Clutter, global, Main });
new Keyboard();
assert(devices === 1, 'GNOME 51 must create the virtual keyboard through stage context');
Clutter.get_default_backend = () => backend;
new Keyboard();
assert(devices === 2, 'Older shells must still create their virtual keyboard');
print('Clipboard Indicator GNOME 51 compatibility checks passed');
