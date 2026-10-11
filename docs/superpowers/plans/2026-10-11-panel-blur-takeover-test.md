# Panel Blur Takeover Test Implementation Plan

> **For agentic workers:** Execute task-by-task with the executing-plans workflow. Keep the existing isolated `consolidate-extension-refresh` worktree.

**Goal:** Rebuild stale stock-panel blur when Dash to Panel takes ownership, build a local test image, and establish why Next PIP customizations are inactive.

**Architecture:** Keep the existing monitor resolver. Before reusing blur actors for Dash to Panel, compare their wrapper identity and static-background monitor binding with the current panel. A mismatch triggers one full PanelBlur reset so background managers and geometry signal connections are recreated together. Reconnect `panels-created` when enabling against an already-present Dash to Panel instance.

**Tech Stack:** GNOME Shell 50, GJS, BlueBuild, Podman, Bash, vendored mail patches.

## Global Constraints

- Keep base `ghcr.io/ublue-os/bazzite-gnome-nvidia:44.20260902` and all existing extension pins.
- Edit patch queues and tests, never generated files directly.
- Do not stage a deployment, reboot, or alter live extension settings. The owner subsequently authorized committing, opening a PR, addressing CodeRabbit feedback, and merging after CodeRabbit approval.
- Preserve Next PIP's three patches and all user dconf preferences.
- User-approved runtime fixture: primary panel monitor 0, stored blur monitor 0, background monitor 1, `is_dtp_panel=false`; secondary correctly bound to monitor 1.

## Task 1: Reproduce and fix Dash to Panel takeover

**Files:**
- Create `scripts/test-blur-my-shell-takeover.js`.
- Modify `scripts/test-blur-my-shell-source.sh` to run the behavioral regression using GJS.
- Add `patches/extensions/blur-my-shell/0002-fix-rebuild-blur-on-dash-to-panel-takeover.patch`.

**Interfaces:** Consume the rendered `PanelBlur` class and actual methods, substituting only unavailable GNOME Shell/actor services in a headless GJS harness. Produce a regression executable through the existing source-test entrypoint.

- [x] Add a test that seeds an existing stock-panel blur matching the owner's dump, then calls the actual `blur_dtp_panels()` callback. Assert the stale background and stock-wrapper binding are discarded before reuse.
- [x] Run `bash scripts/test-blur-my-shell-source.sh`; require an assertion failure reproducing stale reuse.
- [x] Add a patch that checks existing bindings before the panel loop:

```javascript
const needs_reset = global.dashToPanel.panels.some(panel =>
    this.actors_list.some(actors =>
        actors.widgets.panel === panel.panel &&
        (actors.widgets.wrapper !== panel ||
            (actors.static_blur &&
                actors.bg_manager._monitorIndex !== panel.monitor.index))
    )
);
if (needs_reset) {
    this.reset();
    return GLib.SOURCE_REMOVE;
}
```

- [x] Centralize `panels-created` subscription in `blur_existing_panels()`, track the subscribed Dash to Panel object, and clear that reference on disable. Keep one subscription per active object, including after reset and object replacement.
- [x] Cover already-correct panels, wrong static background on an otherwise-correct wrapper, dynamic blur without `_monitorIndex`, repeated calls, disable-before-idle, reset/re-enable subscription, and replacement Dash to Panel objects.
- [x] Regenerate only through `PATH="$PWD/.work/gnu-make/usr/bin:$PATH" bash scripts/prepare-components.sh blur-my-shell` and rerun the test.

## Task 2: Verify Next PIP provenance

**Files:** Read only: system/user extension directories, `patches/extensions/nextpinp/`, generated Next PIP, and dconf path `/org/gnome/shell/extensions/auto-pip-manager/`.

- [x] Confirm active extension path using `gnome-extensions info nextpinp@leonid.nasedkin`.
- [x] Compare user, system, vendor, and generated sources. Check remembered placement, snapping, diagonal throw, taskbar hiding, minimize-close and schema keys.
- [x] Read journal duplicate-extension messages and effective preferences. Report override separately from any actual missing patch or lost preference.
- [x] Give a backup-preserving relocation command for the user copy, followed by a fresh login; do not modify live preferences.

## Task 3: Review and build the candidate

- [x] Run the five component/source/metadata tests, `test-render-determinism.sh`, strict Next PIP schema check, Bash syntax, and `git diff --check`.
- [x] Review patch application and behavioral tests for signal leaks/reset loops and unchanged existing customizations.
- [x] Build with `just build` in this worktree. Tag the concrete amd64 image `localhost/desktop-os-image:local-test-panel-takeover-20261011` rather than relying on the commit tag of an uncommitted build.
- [x] Inspect image source to confirm takeover handling and patched Next PIP are packaged, and run the behavioral test against the image's shipped panel source.
- [x] Report exact install commands using rootful Podman transfer and `rpm-ostree rebase`, with reboot left to the owner.
- [x] Obtain owner runtime acceptance: on 2026-10-11 the owner reported that the candidate appears to work and authorized preparing the PR. The host confirms the candidate is booted and Next PIP loads from `/usr/share`.

Runtime checklist used for the candidate: verify the primary panel immediately after fresh login, before locking (`dtp=true`, panel/blur/background monitor 0), then lock/unlock and monitor reconnect. Verify Next PIP's system path and custom settings. The owner's general acceptance does not constitute a separate recorded result for every checklist item.

Final PR review also identified a CI dependency requirement: explicitly install `gjs` in PR validation so the behavioral regression does not rely on incidental runner packages.
