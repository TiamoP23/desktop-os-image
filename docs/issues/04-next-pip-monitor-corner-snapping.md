# Patch Next PIP for Remembered Monitor/Corner and Improved Snapping

## Goal

Ship Next PIP enabled by default and patch it into a more polished Picture-in-Picture window manager.

## Requirements

- [x] Use Next PIP / Auto PiP Manager as the starting point.
- [x] Keep the scope focused on PiP behavior at first, not a general-purpose floating window manager.
- [x] Decide that the patched extension should be enabled by default once integrated.
- [x] Start from upstream behavior and test real PiP windows before expanding scope.
- [x] Confirm the host currently has Next PIP enabled.
- [ ] Enable the patched extension by default in the image.
- [ ] Add an option to remember the global last-used corner.
- [ ] Add support for remembering the last-used monitor.
- [ ] Place new PiP windows on the remembered monitor and corner when possible.
- [ ] Add a smooth snap animation when the PiP window snaps into a corner.
- [ ] Prototype velocity-aware throw behavior where fling direction affects the target corner.
- [ ] Prototype full inertia only after velocity-aware snapping feels useful.
- [ ] Add preferences UI/settings for the new behavior where appropriate.
- [ ] Package the patched extension through the repo's vendored component workflow.
- [ ] Verify behavior on Wayland and across multiple monitors.

## Current Evidence

The host already has `nextpinp@leonid.nasedkin` enabled and `corner='top-right'` under `org.gnome.shell.extensions.auto-pip-manager`. The upstream extension supports pinning PiP windows above other windows, making them visible on every workspace, placing them in a chosen corner, and snapping to the nearest corner after moving.

## Candidate Upstream

Repository: `https://github.com/EvilX/nextpinp`

Extension UUID: `nextpinp@leonid.nasedkin`
