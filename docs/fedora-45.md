# Fedora 45 upgrade

This image uses GNOME 51 on the released Bazzite Fedora 45 stable base. It keeps
the existing Bazzite GNOME NVIDIA image variant.

The port was developed against a pinned Fedora 45 testing build and then moved
to the released stable tag. Runtime acceptance on the owner's desktop is still
required before treating the release upgrade as fully verified.

## Pinned inputs

| Input | Version / commit |
| --- | --- |
| Bazzite GNOME NVIDIA | `45.20261105` (`stable-45.20261105`) |
| Dash to Panel | v74, `db578c4f0061686609ed0bd1422967dfee2554d6` |
| Blur My Shell | v76, `19ce844b8ca36efe4a181b2cf81504063eb4ce4b` |
| Clipboard Indicator | v71, `c880c7fb88dc7232a61a5864d125989a4f375daa` |
| Coverflow Alt-Tab | `443f3ae98fc14598ed81e57c1b7f0ca15787b638` |
| Auto PiP Manager | version 8, `339692b689dffbafd4568b325bd2a1c518fbd38b` |

Coverflow's latest tag v88 still targets GNOME 50, so this uses a newer upstream
commit with the GNOME 51 shader port and teardown fixes. Auto PiP has no upstream
Git tags/releases. All other extension pins prefer released versions.

The dated Bazzite stable tag was verified in GHCR when preparing this upgrade.
Upstream versioned images have a limited retention period; availability must be
checked again before rebuilding an older candidate later.

## Local changes

- Retain Dash to Panel's secondary-taskbar overview patch.
- Retain all three Auto PiP customization patches.
- Add a narrow Clipboard Indicator compatibility patch for removed St layout and
  Clutter backend APIs, based on unmerged upstream PRs #641/#658.
- Use **unpatched Blur My Shell v76**. Do not carry the old monitor-selection or
  takeover patch forward unless the original symptoms reproduce.
- Do not backport post-v76 monitor fixes into this initial baseline.
- Remove the external rounded-blur library, build dependencies, helper, and guide.
  V76 handles rounded corners directly.
- Express application blur brightness 0.9 and the old sigma 30 (radius 60) in a
  dedicated pipeline. Preserve the legacy settings version so existing user
  settings can still migrate; do not reset user dconf values.

## Prepare, validate, and build

With the prerequisites in the README and the BlueBuild CLI/container engine:

```bash
git submodule update --init --recursive
just prepare
bash scripts/test-component-pins.sh
bash scripts/test-dash-to-panel-source.sh
bash scripts/test-blur-my-shell-source.sh
bash scripts/test-clipboard-indicator-source.sh
bash scripts/test-nextpinp-source.sh
bash scripts/test-extension-metadata.sh
bash scripts/test-render-determinism.sh
just build
```

Build before choosing any deployment command. Do not run `just switch` merely to
validate the build. Keep a known-good deployment available before testing on the
desktop. User-installed extension copies override the system copies and must be
accounted for when testing; Wayland requires a fresh login to reload modules.

## Desktop acceptance checks

- Fresh login, before any lock/unlock: blur covers the full taskbar height.
- Give the monitors visibly different wallpapers: the primary taskbar must show
  its own monitor's wallpaper, not the secondary monitor's background.
- Repeat after lock/unlock, taskbar resizing, and monitor disconnect/reconnect.
- Check static blur and any dynamic blur modes actually used by the owner.
- Check rounded corners, application blur brightness/opacity, and preferences.
- Open Clipboard Indicator with Super+V; copy text/images, select/paste an entry,
  edit an entry, and open confirmation dialogs.
- Exercise Coverflow switching, cancellation, minimized windows, and rapid reuse.
- Exercise PiP remembered monitor/corner, snapping, minimize-to-close, and cleanup
  when disabling the extension.
- Confirm NVIDIA acceleration, display layout, and the normal gaming workflow.

Headless geometry/reparenting checks cover the shipped v76 methods with mocked
Shell services. They do not prove Mutter monitor allocation, wallpaper rendering,
or absence of startup races. Runtime acceptance is still required.
