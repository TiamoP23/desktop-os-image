# Extension Refresh and Branch Consolidation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce a reproducible Bazzite GNOME 50 image candidate containing the newest appropriate upstream components and only the personal extension patches that upstream has not superseded.

**Architecture:** Work on `consolidate-extension-refresh`, which starts at `origin/main` plus the approved design commit. Update immutable base, action, and submodule pins first; then rebuild each retained patch queue against its new upstream base through the repository's component-edit workflow. Source-level regression tests validate the personal behavior after deterministic component rendering, while a full BlueBuild build establishes candidate readiness and owner runtime testing remains the final verification gate.

**Tech Stack:** Git submodules, mail-style Git patch queues, Bash regression tests, GNOME Shell 50/GJS, GSettings/dconf, BlueBuild, GitHub Actions, Bazzite Atomic Desktop

## Global Constraints

- Start from branch `consolidate-extension-refresh` at design commit `f43a640`.
- Keep all pre-existing branches, worktrees, stashes, and the previous bootable deployment intact until the owner approves the installed candidate.
- Treat automated success only as build-candidate readiness; only the owner's post-install, post-reboot approval establishes owner verification.
- Never edit `bluebuild/files/generated/` directly; regenerate it with `bash scripts/prepare-components.sh`.
- Pin Bazzite base image `ghcr.io/ublue-os/bazzite-gnome-nvidia` to `44.20260902`.
- Pin `actions/checkout` v7.0.1 to `3d3c42e5aac5ba805825da76410c181273ba90b1`.
- Pin `blue-build/github-action` v1.12.0 to `836161eb076426a451e6a0054f722b1153b8b3ad`.
- Pin Dash to Panel to `df8a15bac1e5e9fb2b4c5f2407981bd8365a72c4`.
- Pin Blur My Shell to `b689b991c9a60098818f0dd3772bc9c7a83bbbcb`.
- Pin Coverflow Alt-Tab v87 to `189ee9c5fcf5a2a84914fb337f4d53a705060532`.
- Keep Clipboard Indicator v71 at `c880c7fb88dc7232a61a5864d125989a4f375daa`.
- Keep Next PIP at `b6d29fa278cd8e509d8521f578aebeed0864bfbb`.
- Do not update GitHub issues, pull requests, or remote branches in this plan.
- Stage and commit only the files listed by each task; leave unrelated working-tree content untouched.

---

## File Structure

- Modify `.gitignore` to keep repository-local worktrees out of status output.
- Modify `bluebuild/recipes/main.yml` for the stable Bazzite base pin.
- Modify `.github/workflows/build.yml` and `.github/workflows/pr-validate.yml` for immutable action pins and regression-test execution.
- Modify submodule gitlinks under `vendor/extensions/` for selected upstream versions.
- Reduce and regenerate patch queues under `patches/extensions/dash-to-panel/`, `patches/extensions/blur-my-shell/`, and `patches/extensions/nextpinp/`.
- Create focused source tests under `scripts/test-*-source.sh` and a pin test at `scripts/test-component-pins.sh`.
- Modify `manifests/components.yml` to render Next PIP as a source-only component.
- Modify `bluebuild/files/static/system/etc/dconf/db/local.d/00-zorin-like-shell` for the correct Next PIP schema and defaults.
- Modify `README.md` for Next PIP inclusion and reliable local testing instructions.
- Use `docs/superpowers/specs/2026-09-06-extension-refresh-consolidation-design.md` as the runtime acceptance source of truth.

### Task 1: Pin the Base, Actions, and Upstream Extensions

**Files:**
- Create: `scripts/test-component-pins.sh`
- Modify: `.gitignore`
- Modify: `bluebuild/recipes/main.yml`
- Modify: `.github/workflows/build.yml`
- Modify: `.github/workflows/pr-validate.yml`
- Modify: `vendor/extensions/dash-to-panel`
- Modify: `vendor/extensions/blur-my-shell`
- Modify: `vendor/extensions/coverflow-alt-tab`
- Verify unchanged: `vendor/extensions/clipboard-indicator`
- Verify unchanged: `vendor/extensions/nextpinp`

**Interfaces:**
- Consumes: immutable upstream commit IDs from the approved design.
- Produces: exact component pins consumed by every later patch and render task; executable test `scripts/test-component-pins.sh`.

- [ ] **Step 1: Write the failing pin regression test**

Create `scripts/test-component-pins.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

assert_head() {
  local path="$1"
  local expected="$2"
  local actual
  actual="$(git -C "$path" rev-parse HEAD)"
  if [[ "$actual" != "$expected" ]]; then
    printf '%s: expected %s, found %s\n' "$path" "$expected" "$actual" >&2
    exit 1
  fi
}

assert_file_contains() {
  local path="$1"
  local expected="$2"
  if ! grep -Fq "$expected" "$path"; then
    printf '%s: missing %s\n' "$path" "$expected" >&2
    exit 1
  fi
}

assert_head vendor/extensions/dash-to-panel df8a15bac1e5e9fb2b4c5f2407981bd8365a72c4
assert_head vendor/extensions/blur-my-shell b689b991c9a60098818f0dd3772bc9c7a83bbbcb
assert_head vendor/extensions/coverflow-alt-tab 189ee9c5fcf5a2a84914fb337f4d53a705060532
assert_head vendor/extensions/clipboard-indicator c880c7fb88dc7232a61a5864d125989a4f375daa
assert_head vendor/extensions/nextpinp b6d29fa278cd8e509d8521f578aebeed0864bfbb

assert_file_contains bluebuild/recipes/main.yml 'image-version: "44.20260902"'
assert_file_contains .github/workflows/build.yml 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1'
assert_file_contains .github/workflows/pr-validate.yml 'actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1'
assert_file_contains .github/workflows/build.yml 'blue-build/github-action@836161eb076426a451e6a0054f722b1153b8b3ad # v1.12.0'
```

- [ ] **Step 2: Resolve and confirm the complete Coverflow v87 object ID**

Run:

```bash
git -C vendor/extensions/coverflow-alt-tab rev-parse v87^{commit}
```

Expected: `189ee9c5fcf5a2a84914fb337f4d53a705060532`.

- [ ] **Step 3: Run the pin test to verify it fails**

Run:

```bash
bash scripts/test-component-pins.sh
```

Expected: exit 1 at the first old pin, before any component update.

- [ ] **Step 4: Update fixed configuration pins**

Apply these exact changes:

```diff
diff --git a/.gitignore b/.gitignore
@@
 .work/
+.worktrees/
 .superpowers/
diff --git a/bluebuild/recipes/main.yml b/bluebuild/recipes/main.yml
@@
-image-version: "44.20260608"
+image-version: "44.20260902"
diff --git a/.github/workflows/build.yml b/.github/workflows/build.yml
@@
-        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
+        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
@@
-        uses: blue-build/github-action@v1
+        uses: blue-build/github-action@836161eb076426a451e6a0054f722b1153b8b3ad # v1.12.0
diff --git a/.github/workflows/pr-validate.yml b/.github/workflows/pr-validate.yml
@@
-        uses: actions/checkout@de0fac2e4500dabe0009e67214ff5f5447ce83dd # v6
+        uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
```

- [ ] **Step 5: Move each submodule to its approved detached commit**

Run each command independently and stop if any object is unavailable:

```bash
git -C vendor/extensions/dash-to-panel switch --detach df8a15bac1e5e9fb2b4c5f2407981bd8365a72c4
git -C vendor/extensions/blur-my-shell switch --detach b689b991c9a60098818f0dd3772bc9c7a83bbbcb
git -C vendor/extensions/coverflow-alt-tab switch --detach 189ee9c5fcf5a2a84914fb337f4d53a705060532
git -C vendor/extensions/clipboard-indicator switch --detach c880c7fb88dc7232a61a5864d125989a4f375daa
git -C vendor/extensions/nextpinp switch --detach b6d29fa278cd8e509d8521f578aebeed0864bfbb
```

Expected: each command reports detached HEAD at the requested commit and leaves its vendor repository clean.

- [ ] **Step 6: Run the pin regression test**

Run:

```bash
bash scripts/test-component-pins.sh
```

Expected: exit 0 with no output.

- [ ] **Step 7: Commit the immutable pin refresh**

Run:

```bash
git add .gitignore bluebuild/recipes/main.yml .github/workflows/build.yml .github/workflows/pr-validate.yml scripts/test-component-pins.sh vendor/extensions/dash-to-panel vendor/extensions/blur-my-shell vendor/extensions/coverflow-alt-tab vendor/extensions/clipboard-indicator vendor/extensions/nextpinp
git commit -m "chore: refresh image and extension pins"
```

Expected: only the listed pins, configuration files, and pin test are committed.

### Task 2: Rebase the Dash to Panel Personal Behavior

**Files:**
- Create: `scripts/test-dash-to-panel-source.sh`
- Modify: `patches/extensions/dash-to-panel/0001-fix-keep-secondary-monitor-taskbars-visible-when-ove.patch`
- Delete: `patches/extensions/dash-to-panel/0002-fix-restore-hide-overview-on-startup-on-GNOME-50.patch`

**Interfaces:**
- Consumes: Dash to Panel pin `df8a15b` and generated path `bluebuild/files/generated/usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com`.
- Produces: one-patch Dash to Panel queue and executable source test `scripts/test-dash-to-panel-source.sh`.

- [ ] **Step 1: Remove the superseded startup patch**

Delete only:

```text
patches/extensions/dash-to-panel/0002-fix-restore-hide-overview-on-startup-on-GNOME-50.patch
```

The upstream source at `df8a15b` already contains `Config.PACKAGE_VERSION >= '50'` and `Main.overview.hide()` from commit `19f0c64`.

- [ ] **Step 2: Render unpatched upstream and write the failing source test**

Move `patches/extensions/dash-to-panel/0001-fix-keep-secondary-monitor-taskbars-visible-when-ove.patch`
to `.work/dash-to-panel-overview.patch` with `apply_patch`, then run:

```bash
bash scripts/prepare-components.sh dash-to-panel
```

Create `scripts/test-dash-to-panel-source.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

source_dir="bluebuild/files/generated/usr/share/gnome-shell/extensions/dash-to-panel@jderose9.github.com"
extension_file="$source_dir/extension.js"
panel_file="$source_dir/panel.js"

require_source() {
  local path="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -Fq "$pattern" "$path"; then
    printf 'Missing Dash to Panel behavior: %s\n' "$description" >&2
    exit 1
  fi
}

require_source "$extension_file" "Config.PACKAGE_VERSION >= '50'" 'detect GNOME 50 startup behavior'
require_source "$extension_file" 'Main.overview.hide()' 'use the upstream startup overview fix'
require_source "$panel_file" 'let isShown = !isOverview || isOverviewFocusedMonitor || !this.isPrimary' 'keep secondary panels visible in overview'
```

The temporary move is limited to the tracked Dash to Panel patch and must be
reversed in Step 4. Do not move any user file.

- [ ] **Step 3: Run the test to verify the retained behavior fails**

Run:

```bash
bash scripts/test-dash-to-panel-source.sh
```

Expected: exit 1 with `Missing Dash to Panel behavior: keep secondary panels visible in overview`; the two upstream startup assertions pass.

- [ ] **Step 4: Restore and replay the retained patch**

Move `.work/dash-to-panel-overview.patch` back to
`patches/extensions/dash-to-panel/0001-fix-keep-secondary-monitor-taskbars-visible-when-ove.patch`
with `apply_patch`, then run:

```bash
just component-edit dash-to-panel patch/dash-to-panel-refresh
just component-finish dash-to-panel
```

Expected: the old one-line behavior replays onto `df8a15b`, the queue exports as one patch, and the generated component renders.

- [ ] **Step 5: Run the Dash to Panel source test**

Run:

```bash
bash scripts/test-dash-to-panel-source.sh
```

Expected: exit 0 with no output.

- [ ] **Step 6: Commit the rebased Dash to Panel queue**

Run:

```bash
git add patches/extensions/dash-to-panel scripts/test-dash-to-panel-source.sh
git commit -m "fix: retain secondary panels in overview"
```

### Task 3: Replace Blur Geometry Patches With Upstream and Retain Monitor Selection

**Files:**
- Create: `scripts/test-blur-my-shell-source.sh`
- Create: `patches/extensions/blur-my-shell/0001-fix-select-panel-blur-monitor-from-dash-to-panel.patch`
- Delete: `patches/extensions/blur-my-shell/0001-fix-size-panel-blur-against-dash-to-panel-panel-box.patch`
- Delete: `patches/extensions/blur-my-shell/0002-fix-refresh-dash-to-panel-blur-layout-after-startup.patch`
- Modify through patch branch: `vendor/extensions/blur-my-shell/src/components/panel.js`

**Interfaces:**
- Consumes: Blur My Shell pin `b689b99` and Dash to Panel parent property `_dtpIndex`.
- Produces: `PanelBlur.find_panel_monitor(panel)`, one-patch Blur My Shell queue, and executable source test `scripts/test-blur-my-shell-source.sh`.

- [ ] **Step 1: Remove both superseded Blur My Shell patches**

Delete these files:

```text
patches/extensions/blur-my-shell/0001-fix-size-panel-blur-against-dash-to-panel-panel-box.patch
patches/extensions/blur-my-shell/0002-fix-refresh-dash-to-panel-blur-layout-after-startup.patch
```

- [ ] **Step 2: Render upstream and write the failing monitor-selection test**

Run:

```bash
bash scripts/prepare-components.sh blur-my-shell
```

Create `scripts/test-blur-my-shell-source.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

extension_file="${BLUR_MY_SHELL_SOURCE_FILE:-bluebuild/files/generated/usr/share/gnome-shell/extensions/blur-my-shell@aunetx/components/panel.js}"

require_source() {
  local pattern="$1"
  local description="$2"
  if ! grep -Fq "$pattern" "$extension_file"; then
    printf 'Missing Blur My Shell behavior: %s\n' "$description" >&2
    exit 1
  fi
}

require_source 'find_panel_monitor(panel) {' 'central monitor resolver'
require_source 'panel.get_parent()?._dtpIndex' 'Dash to Panel monitor assignment'
require_source 'Main.layoutManager.monitors[monitor_index]' 'assigned monitor lookup'
require_source 'Main.layoutManager.findMonitorForActor(panel)' 'non-Dash-to-Panel fallback'

resolver_calls="$(grep -Fc 'this.find_panel_monitor(panel)' "$extension_file")"
if [[ "$resolver_calls" -ne 2 ]]; then
  printf 'Expected two monitor resolver calls, found %s\n' "$resolver_calls" >&2
  exit 1
fi
```

- [ ] **Step 3: Run the test to verify it fails**

Run:

```bash
bash scripts/test-blur-my-shell-source.sh
```

Expected: exit 1 with `Missing Blur My Shell behavior: central monitor resolver`.

- [ ] **Step 4: Start a clean Blur My Shell patch session**

Run:

```bash
just component-edit blur-my-shell patch/blur-my-shell-monitor-refresh
```

Expected: the session starts at `b689b99` with no old local patches replayed.

- [ ] **Step 5: Implement the monitor resolver against the upstream geometry model**

Apply this focused change to `vendor/extensions/blur-my-shell/src/components/panel.js`:

```diff
@@
     maybe_blur_panel(panel) {
@@
     }
+
+    /// Find the monitor assigned to a panel.
+    find_panel_monitor(panel) {
+        const monitor_index = panel.get_parent()?._dtpIndex;
+        return Main.layoutManager.monitors[monitor_index]
+            ?? Main.layoutManager.findMonitorForActor(panel);
+    }

     /// Blur a panel
     blur_panel(panel) {
@@
-        let monitor = Main.layoutManager.findMonitorForActor(panel);
+        let monitor = this.find_panel_monitor(panel);
         if (!monitor)
             return;
@@
     update_size(actors) {
+        let panel = actors.widgets.panel;
         let geometry_actor = actors.widgets.geometry_actor;
@@
         let [geometry_width, geometry_height] = geometry_actor.get_size();
+        let monitor = this.find_panel_monitor(panel);

-        if (!width || !height || !geometry_width || !geometry_height) {
+        if (!width || !height || !geometry_width || !geometry_height || !monitor) {
             this.queue_update_size(actors);
             return;
         }
@@
         // if static blur, need to clip the background
         if (actors.static_blur) {
-            let monitor = Main.layoutManager.findMonitorForActor(geometry_actor);
-            if (!monitor) {
-                this.queue_update_size(actors);
-                return;
-            }
-
@@
-        actors.monitor = Main.layoutManager.findMonitorForActor(geometry_actor);
+        actors.monitor = monitor;
```

This preserves upstream's `geometry_actor`, `wrapper`, `queue_update_size()`, dynamic-length handling, and static-blur clipping.

- [ ] **Step 6: Commit inside the submodule and export the queue**

Run:

```bash
git -C vendor/extensions/blur-my-shell add src/components/panel.js
git -C vendor/extensions/blur-my-shell commit -m "fix: select panel blur monitor from Dash to Panel"
just component-finish blur-my-shell
```

Expected: one patch is exported as `patches/extensions/blur-my-shell/0001-fix-select-panel-blur-monitor-from-dash-to-panel.patch` and rendering succeeds.

- [ ] **Step 7: Run the Blur My Shell source test**

Run:

```bash
bash scripts/test-blur-my-shell-source.sh
```

Expected: exit 0 with no output.

- [ ] **Step 8: Commit the reduced Blur My Shell queue**

Run:

```bash
git add patches/extensions/blur-my-shell scripts/test-blur-my-shell-source.sh
git commit -m "fix: retain panel blur monitor selection"
```

### Task 4: Finalize Next PIP Packaging and Defaults

**Files:**
- Modify: `manifests/components.yml`
- Modify: `bluebuild/files/static/system/etc/dconf/db/local.d/00-zorin-like-shell`
- Modify: `README.md`
- Create: `scripts/test-nextpinp-source.sh`

**Interfaces:**
- Consumes: Next PIP UUID `nextpinp@leonid.nasedkin` and schema `org.gnome.shell.extensions.auto-pip-manager`.
- Produces: source-only component rendering, image defaults, local test instructions, and executable behavior test `scripts/test-nextpinp-source.sh`.

- [ ] **Step 1: Write the failing Next PIP packaging and behavior test**

Create `scripts/test-nextpinp-source.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

source_dir="bluebuild/files/generated/usr/share/gnome-shell/extensions/nextpinp@leonid.nasedkin"
extension_file="$source_dir/extension.js"
prefs_file="$source_dir/prefs.js"
schema_file="$source_dir/schemas/org.gnome.shell.extensions.auto-pip-manager.gschema.xml"
defaults_file="bluebuild/files/static/system/etc/dconf/db/local.d/00-zorin-like-shell"

require_source() {
  local path="$1"
  local pattern="$2"
  local description="$3"
  if ! grep -Fq "$pattern" "$path"; then
    printf 'Missing Next PIP behavior: %s\n' "$description" >&2
    exit 1
  fi
}

require_source "$schema_file" 'name="remember-monitor"' 'remember-monitor schema key'
require_source "$schema_file" 'name="snap-animation"' 'snap-animation schema key'
require_source "$prefs_file" "'velocity-throw'" 'velocity preference'
require_source "$extension_file" 'get_work_area_for_monitor(remembered)' 'workspace monitor work area'
require_source "$extension_file" 'DIAGONAL_AXIS_RATIO' 'diagonal velocity classification'
require_source "$extension_file" 'hide_from_window_list' 'window-list hiding'
require_source "$extension_file" "window.connect('notify::minimized'" 'minimize lifecycle handling'
require_source "$extension_file" 'window.delete(global.get_current_time())' 'minimize-to-close behavior'
require_source "$defaults_file" '[org/gnome/shell/extensions/auto-pip-manager]' 'correct dconf schema path'
require_source "$defaults_file" 'remember-monitor=true' 'remember-monitor image default'

if grep -Fq 'build_output: .' manifests/components.yml; then
  printf 'Next PIP must render through source-tree mode, not build_output=.\n' >&2
  exit 1
fi
```

- [ ] **Step 2: Render current upstream and verify the test fails**

Run:

```bash
bash scripts/prepare-components.sh nextpinp
bash scripts/test-nextpinp-source.sh
```

Expected: rendering succeeds; the test exits 1 because upstream lacks `remember-monitor`.

- [ ] **Step 3: Correct the source-only manifest and dconf defaults**

Apply these exact changes:

```diff
diff --git a/manifests/components.yml b/manifests/components.yml
@@
 - id: nextpinp
   type: gnome-extension
   install_dir: usr/share/gnome-shell/extensions/nextpinp@leonid.nasedkin
-  build_output: .
   post_install_command: glib-compile-schemas "$COMPONENT_DEST/schemas"
diff --git a/bluebuild/files/static/system/etc/dconf/db/local.d/00-zorin-like-shell b/bluebuild/files/static/system/etc/dconf/db/local.d/00-zorin-like-shell
@@
-[org/gnome/shell/extensions/nextpinp]
+[org/gnome/shell/extensions/auto-pip-manager]
+always-on-all-workspaces=true
+always-on-top=true
 corner='top-right'
+offset=20
+remember-corner=true
+remember-monitor=true
+snap-animation=true
+snap-animation-duration=180
+velocity-throw=true
```

- [ ] **Step 4: Add reliable local Next PIP test instructions**

First update the overview and included-extension list:

```diff
@@
-Manifest-driven BlueBuild repository for a personal Bazzite GNOME 44 image.
+Manifest-driven BlueBuild repository for a personal Bazzite GNOME 50 image.
@@
-The image builds from `ghcr.io/ublue-os/bazzite-gnome-nvidia:44` and layers the generated GNOME Shell extensions plus the existing desktop and DX customizations from this repository.
+The image builds from `ghcr.io/ublue-os/bazzite-gnome-nvidia:44.20260902` and layers the generated GNOME Shell extensions plus the existing desktop and DX customizations from this repository.
@@
 - Clipboard Indicator
+- Next PIP
```

Then add this section before `## Blur My Shell rounded blur helper` in
`README.md`:

````markdown
### Test a GNOME extension locally

Render Next PIP and package the generated extension for user-level testing:

```bash
bash ./scripts/prepare-components.sh nextpinp
mkdir -p artifacts
rm -f artifacts/nextpinp@leonid.nasedkin-patched.zip
(
  cd bluebuild/files/generated/usr/share/gnome-shell/extensions/nextpinp@leonid.nasedkin
  zip -qr "$OLDPWD/artifacts/nextpinp@leonid.nasedkin-patched.zip" .
)
gnome-extensions install --force artifacts/nextpinp@leonid.nasedkin-patched.zip
gnome-extensions enable nextpinp@leonid.nasedkin
```

GNOME Shell caches extension modules by UUID. Log out and back in before
retesting same-UUID code changes on Wayland. Remove the user copy with
`gnome-extensions uninstall nextpinp@leonid.nasedkin` before testing the copy
shipped by an installed image, because user extensions override system ones.
````

- [ ] **Step 5: Verify source-only upstream rendering still succeeds**

Run:

```bash
bash scripts/prepare-components.sh nextpinp
test -f bluebuild/files/generated/usr/share/gnome-shell/extensions/nextpinp@leonid.nasedkin/extension.js
test -f bluebuild/files/generated/usr/share/gnome-shell/extensions/nextpinp@leonid.nasedkin/schemas/gschemas.compiled
```

Expected: all commands exit 0. The behavior test still fails because the custom queue is added in Task 5.

- [ ] **Step 6: Commit packaging, defaults, docs, and the failing regression test**

Run:

```bash
git add manifests/components.yml bluebuild/files/static/system/etc/dconf/db/local.d/00-zorin-like-shell README.md scripts/test-nextpinp-source.sh
git commit -m "feat: finalize next pip image integration"
```

### Task 5: Rebuild the Tested Next PIP Behavior as Three Patches

**Files:**
- Create: `patches/extensions/nextpinp/0001-feat-add-remembered-PiP-placement-settings.patch`
- Create: `patches/extensions/nextpinp/0002-feat-improve-PiP-placement-and-snapping.patch`
- Create: `patches/extensions/nextpinp/0003-fix-manage-PiP-window-lifecycle.patch`
- Modify through patch branch: `vendor/extensions/nextpinp/prefs.js`
- Modify through patch branch: `vendor/extensions/nextpinp/extension.js`
- Modify through patch branch: `vendor/extensions/nextpinp/schemas/org.gnome.shell.extensions.auto-pip-manager.gschema.xml`

**Interfaces:**
- Consumes: the five tested patches stored in commit `1df23c3` and clean Next PIP base `b6d29fa`.
- Produces: the same final source as the locally installed test copy, represented by three coherent commits and three exported patches.

- [ ] **Step 1: Start a clean Next PIP edit session before restoring old patches**

Run:

```bash
just component-edit nextpinp patch/nextpinp-refresh
```

Expected: the edit branch starts at `b6d29fa` and no patches are replayed.

- [ ] **Step 2: Restore the five tested source patches from the prior branch commit**

Run:

```bash
git restore --source=1df23c3 -- patches/extensions/nextpinp
```

Expected: exactly five old patch files appear under `patches/extensions/nextpinp/`; no other file is restored.

- [ ] **Step 3: Apply and commit the settings patch**

Run:

```bash
git -C vendor/extensions/nextpinp apply ../../../patches/extensions/nextpinp/0001-feat-add-remembered-PiP-placement-settings.patch
git -C vendor/extensions/nextpinp add prefs.js schemas/org.gnome.shell.extensions.auto-pip-manager.gschema.xml
git -C vendor/extensions/nextpinp commit -m "feat: add remembered PiP placement settings"
```

Expected: one commit changes only `prefs.js` and the schema.

- [ ] **Step 4: Apply and commit placement, work-area, and diagonal fixes together**

Run:

```bash
git -C vendor/extensions/nextpinp apply ../../../patches/extensions/nextpinp/0002-feat-improve-PiP-snap-placement-behavior.patch
git -C vendor/extensions/nextpinp apply ../../../patches/extensions/nextpinp/0003-fix-use-workspace-monitor-work-area-lookup.patch
```

Apply the diagonal classification fix directly to
`vendor/extensions/nextpinp/extension.js` so it belongs to the placement commit:

```diff
@@
 const THROW_DISTANCE_THRESHOLD = 80;
 const THROW_SPEED_THRESHOLD = 0.6;
+const DIAGONAL_AXIS_RATIO = 0.5;
@@
-    const horizontalDominates = Math.abs(dx) > Math.abs(dy);
-    const verticalDominates = Math.abs(dy) > Math.abs(dx);
-    const diagonal = !horizontalDominates && !verticalDominates;
+    const absDx = Math.abs(dx);
+    const absDy = Math.abs(dy);
+    const diagonal = Math.min(absDx, absDy) / Math.max(absDx, absDy) >= DIAGONAL_AXIS_RATIO;
+    const horizontalDominates = !diagonal && absDx > absDy;
+    const verticalDominates = !diagonal && absDy > absDx;
```

Then run:

```bash
git -C vendor/extensions/nextpinp add extension.js
git -C vendor/extensions/nextpinp commit -m "feat: improve PiP placement and snapping"
```

Expected: one commit contains remembered-monitor placement,
`get_work_area_for_monitor(remembered)`, snap animation, and
`DIAGONAL_AXIS_RATIO`.

- [ ] **Step 5: Apply and commit lifecycle handling**

Run:

```bash
git -C vendor/extensions/nextpinp apply ../../../patches/extensions/nextpinp/0004-fix-hide-and-close-minimized-PiP-windows.patch
git -C vendor/extensions/nextpinp add extension.js
git -C vendor/extensions/nextpinp commit -m "fix: manage PiP window lifecycle"
```

Expected: one commit adds existing-window management, window-list hiding, settings-change reapplication, `notify::minimized`, and minimize-to-close behavior.

- [ ] **Step 6: Validate the patch-branch source before export**

Run:

```bash
glib-compile-schemas --strict --dry-run vendor/extensions/nextpinp/schemas
git -C vendor/extensions/nextpinp diff --check b6d29fa..HEAD
git -C vendor/extensions/nextpinp log --oneline b6d29fa..HEAD
```

Expected: schema and diff checks exit 0; the log contains exactly the three commits created in Steps 3-5.

- [ ] **Step 7: Export the three-patch queue and render Next PIP**

Run:

```bash
just component-finish nextpinp
```

Expected: old patch files are replaced by exactly three numbered patches, the submodule returns to detached `b6d29fa`, and rendering succeeds.

- [ ] **Step 8: Run the behavior test and compare with the locally tested source**

Run:

```bash
bash scripts/test-nextpinp-source.sh
diff -u /home/tiamop23/.local/share/gnome-shell/extensions/nextpinp@leonid.nasedkin/extension.js bluebuild/files/generated/usr/share/gnome-shell/extensions/nextpinp@leonid.nasedkin/extension.js
diff -u /home/tiamop23/.local/share/gnome-shell/extensions/nextpinp@leonid.nasedkin/prefs.js bluebuild/files/generated/usr/share/gnome-shell/extensions/nextpinp@leonid.nasedkin/prefs.js
diff -u /home/tiamop23/.local/share/gnome-shell/extensions/nextpinp@leonid.nasedkin/schemas/org.gnome.shell.extensions.auto-pip-manager.gschema.xml bluebuild/files/generated/usr/share/gnome-shell/extensions/nextpinp@leonid.nasedkin/schemas/org.gnome.shell.extensions.auto-pip-manager.gschema.xml
```

Expected: the source test exits 0 and all three diffs produce no output.

- [ ] **Step 9: Commit the rebuilt Next PIP queue**

Run:

```bash
git add patches/extensions/nextpinp
git commit -m "feat: preserve tested next pip behavior"
```

### Task 6: Add Regression Tests to CI and Validate GNOME 50 Metadata

**Files:**
- Modify: `.github/workflows/pr-validate.yml`
- Create: `scripts/test-extension-metadata.sh`

**Interfaces:**
- Consumes: all rendered extension directories and test scripts from Tasks 1-5.
- Produces: one CI verification entrypoint per retained behavior and metadata validation for GNOME 50 compatibility.

- [ ] **Step 1: Write the metadata validation test**

Create `scripts/test-extension-metadata.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

extension_root="bluebuild/files/generated/usr/share/gnome-shell/extensions"

for metadata in "$extension_root"/*/metadata.json; do
  if ! grep -Eq '"50"|"50"[[:space:]]*,' "$metadata"; then
    printf '%s does not declare GNOME Shell 50 support\n' "$metadata" >&2
    exit 1
  fi
done

expected_count=5
actual_count="$(find "$extension_root" -mindepth 2 -maxdepth 2 -name metadata.json | wc -l)"
if [[ "$actual_count" -ne "$expected_count" ]]; then
  printf 'Expected %s rendered extensions, found %s\n' "$expected_count" "$actual_count" >&2
  exit 1
fi
```

- [ ] **Step 2: Run all source tests locally**

Run:

```bash
bash scripts/prepare-components.sh
bash scripts/test-component-pins.sh
bash scripts/test-dash-to-panel-source.sh
bash scripts/test-blur-my-shell-source.sh
bash scripts/test-nextpinp-source.sh
bash scripts/test-extension-metadata.sh
```

Expected: all commands exit 0.

- [ ] **Step 3: Add all focused tests to PR validation**

Insert this step after `Prepare generated tree` and before `Check shell scripts`:

```yaml
      - name: Test extension sources and pins
        run: |
          bash ./scripts/test-component-pins.sh
          bash ./scripts/test-dash-to-panel-source.sh
          bash ./scripts/test-blur-my-shell-source.sh
          bash ./scripts/test-nextpinp-source.sh
          bash ./scripts/test-extension-metadata.sh
```

- [ ] **Step 4: Validate shell syntax and workflow whitespace**

Run:

```bash
bash -n scripts/*.sh bluebuild/files/static/scripts/*.sh
git diff --check
```

Expected: both commands exit 0.

- [ ] **Step 5: Commit CI coverage**

Run:

```bash
git add .github/workflows/pr-validate.yml scripts/test-extension-metadata.sh
git commit -m "ci: validate patched extension behavior"
```

### Task 7: Establish Build-Candidate Readiness

**Files:**
- Verify: all tracked files changed by Tasks 1-6
- Regenerate only: `bluebuild/files/generated/`
- Read acceptance criteria: `docs/superpowers/specs/2026-09-06-extension-refresh-consolidation-design.md`

**Interfaces:**
- Consumes: the complete consolidated source tree.
- Produces: automated evidence that the branch is a build candidate, not owner verification.

- [ ] **Step 1: Confirm no component edit session remains active**

Run:

```bash
bash scripts/check-active-edit-sessions.sh
git submodule foreach --recursive 'test -z "$(git status --porcelain)"'
```

Expected: both commands exit 0 and every submodule reports a clean detached checkout.

- [ ] **Step 2: Render all components twice and prove determinism**

Run:

```bash
bash scripts/prepare-components.sh
git status --short bluebuild/files/generated
bash scripts/prepare-components.sh
git status --short bluebuild/files/generated
```

Expected: both status commands produce no tracked changes because generated content is ignored; the second render exits 0 without altering source or patch files.

- [ ] **Step 3: Run the complete local validation suite**

Run:

```bash
bash scripts/test-component-pins.sh
bash scripts/test-dash-to-panel-source.sh
bash scripts/test-blur-my-shell-source.sh
bash scripts/test-nextpinp-source.sh
bash scripts/test-extension-metadata.sh
bash -n scripts/*.sh bluebuild/files/static/scripts/*.sh
glib-compile-schemas --strict --dry-run bluebuild/files/generated/usr/share/gnome-shell/extensions/nextpinp@leonid.nasedkin/schemas
git diff --check origin/main...HEAD
```

Expected: every command exits 0.

- [ ] **Step 4: Build the complete image**

Run:

```bash
just build
```

Expected: BlueBuild exits 0 after building the complete image from `44.20260902`.

- [ ] **Step 5: Review the final branch and ensure superseded content is absent**

Run:

```bash
git status --short --branch
git diff --stat origin/main...HEAD
git log --oneline --decorate origin/main..HEAD
test ! -e patches/extensions/dash-to-panel/0002-fix-restore-hide-overview-on-startup-on-GNOME-50.patch
test ! -e patches/extensions/blur-my-shell/0001-fix-size-panel-blur-against-dash-to-panel-panel-box.patch
test ! -e patches/extensions/blur-my-shell/0002-fix-refresh-dash-to-panel-blur-layout-after-startup.patch
test "$(find patches/extensions/nextpinp -maxdepth 1 -name '*.patch' | wc -l)" -eq 3
```

Expected: the worktree has no unintended changes; the deleted patches are absent; Next PIP has exactly three patches; branch history contains the design and focused implementation commits only.

- [ ] **Step 6: Record candidate status without claiming owner verification**

Report the exact successful commands, resulting image reference, commit SHA, and remaining runtime checklist. Use the phrase `build candidate`; do not use `fully verified`, `owner-verified`, or equivalent success language.

### Task 8: Owner Installation, Reboot, and Runtime Approval

**Files:**
- No repository files change unless runtime testing reveals a defect.

**Interfaces:**
- Consumes: the image reference and commit SHA from Task 7.
- Produces: either explicit owner approval or a concrete failure report that returns execution to the affected implementation task.

- [ ] **Step 1: Prevent the user-installed Next PIP copy from masking the image copy**

Before rebooting into the candidate, the owner runs:

```bash
gnome-extensions uninstall nextpinp@leonid.nasedkin
```

Expected: `~/.local/share/gnome-shell/extensions/nextpinp@leonid.nasedkin` no longer overrides `/usr/share/gnome-shell/extensions/nextpinp@leonid.nasedkin`. Preserve the local source in Git and the patch queue; no behavior is lost.

- [ ] **Step 2: Install the candidate image and reboot into it**

Use the image reference produced by Task 7 through the owner's normal Atomic Desktop deployment flow. After reboot, run:

```bash
rpm-ostree status
gnome-shell --version
gnome-extensions list --enabled
```

Expected: the booted deployment is the candidate, GNOME Shell reports 50.x, and all intended extensions are enabled.

- [ ] **Step 3: Verify extension load state and logs**

Run:

```bash
gnome-extensions info dash-to-panel@jderose9.github.com
gnome-extensions info blur-my-shell@aunetx
gnome-extensions info CoverflowAltTab@palatis.blogspot.com
gnome-extensions info clipboard-indicator@tudmotu.com
gnome-extensions info nextpinp@leonid.nasedkin
journalctl --user -b --no-pager -g 'dash-to-panel|blur-my-shell|CoverflowAltTab|clipboard-indicator|nextpinp|JS ERROR'
```

Expected: all five extensions report active, Coverflow is not `OUT OF DATE`, and the journal has no related JavaScript errors.

- [ ] **Step 4: Perform the approved desktop behavior checks**

Verify manually:

```text
1. Login does not leave the startup overview open.
2. Opening overview keeps intended secondary-monitor taskbars visible.
3. Every taskbar blur uses its own monitor's wallpaper after cold login.
4. Disconnecting and reconnecting a monitor recreates correct taskbar blur.
5. Coverflow Alt-Tab switches windows normally without teardown glitches.
6. Next PIP remembers corner and monitor and respects monitor work areas.
7. Next PIP snap animation and diagonal velocity throws behave as tested.
8. Next PIP windows stay above, stay across workspaces, remain out of the window list, and close when minimized.
```

- [ ] **Step 5: Wait for explicit owner approval**

If every check passes, the owner explicitly approves the candidate. Only then may the branch be described as owner-verified. If any check fails, keep candidate status, collect the exact reproduction and relevant journal lines, fix the smallest affected component, rebuild, reinstall, reboot, and repeat the affected checks.

## Self-Review

- Spec coverage: version policy, upstream replacements, retained personal behavior, branch/stash preservation, deterministic rendering, full build, user-extension masking, reboot testing, and explicit owner approval all map to tasks.
- Patch ownership: Dash to Panel has one retained override; Blur My Shell has one retained monitor resolver; Next PIP has three coherent patches containing all five tested behaviors and follow-up fixes.
- Type and naming consistency: the component ID is `nextpinp`, UUID is `nextpinp@leonid.nasedkin`, schema is `org.gnome.shell.extensions.auto-pip-manager`, and monitor resolver is `find_panel_monitor(panel)` throughout.
- Verification boundary: Task 7 produces only a build candidate; Task 8 and explicit owner approval are required for owner verification.
- Recovery: no task deletes branches, worktrees, stashes, or the prior bootable deployment.
