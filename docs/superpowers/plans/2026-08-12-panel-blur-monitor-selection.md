# Panel Blur Monitor Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure every Dash-to-Panel blur uses its assigned monitor's wallpaper at login and after monitor reconnects.

**Architecture:** Add a monitor resolver to Blur My Shell's panel component that prefers Dash-to-Panel's `_dtpIndex` and falls back to GNOME Shell actor geometry for other panels. Use the resolver for both static-background creation and monitor-relative geometry; retain the existing monitor-change reset so backgrounds are recreated after reconnects.

**Tech Stack:** GNOME Shell JavaScript (GJS), Blur My Shell patch queue, Bash source regression test, BlueBuild component renderer, GitHub Actions

## Global Constraints

- Do not edit `bluebuild/files/generated/` manually; render it with `scripts/prepare-components.sh`.
- Preserve actor-based monitor lookup for panels not managed by Dash-to-Panel.
- Do not add startup delays or change blur appearance and settings.
- Do not modify unrelated existing worktree changes.
- Do not create a repository commit unless the user explicitly requests one.

---

### Task 1: Resolve Panel Blur From Its Assigned Monitor

**Files:**
- Create: `scripts/test-blur-my-shell-source.sh`
- Create: `patches/extensions/blur-my-shell/0003-fix-select-panel-blur-monitor-from-dash-to-panel.patch`
- Modify: `.github/workflows/pr-validate.yml:36-43`
- Render: `bluebuild/files/generated/usr/share/gnome-shell/extensions/blur-my-shell@aunetx/components/panel.js`

**Interfaces:**
- Consumes: Dash-to-Panel's numeric `panel.get_parent()._dtpIndex` and `Main.layoutManager.monitors`.
- Produces: `PanelBlur.find_panel_monitor(panel)`, returning a GNOME Shell monitor object or the existing fallback result.

- [ ] **Step 1: Write the failing rendered-source regression test**

Create `scripts/test-blur-my-shell-source.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

extension_file="bluebuild/files/generated/usr/share/gnome-shell/extensions/blur-my-shell@aunetx/components/panel.js"

require_source() {
  local pattern="$1"
  local description="$2"

  if ! grep -Eq "$pattern" "$extension_file"; then
    printf 'Missing Blur My Shell behavior: %s\n' "$description" >&2
    exit 1
  fi
}

require_source "find_panel_monitor\\(panel\\)" "centralize panel monitor selection"
require_source "panel\\.get_parent\\(\\)\\?\\._dtpIndex" "read Dash-to-Panel's assigned monitor index"
require_source "Main\\.layoutManager\\.monitors\\[monitor_index\\]" "prefer the assigned monitor"
require_source "Main\\.layoutManager\\.findMonitorForActor\\(panel\\)" "retain the non-Dash-to-Panel fallback"

resolver_calls="$(grep -Ec 'this\\.find_panel_monitor\\(panel\\)' "$extension_file")"
if [[ "$resolver_calls" -ne 2 ]]; then
  printf 'Expected panel monitor resolver at creation and geometry update; found %s calls\n' "$resolver_calls" >&2
  exit 1
fi
```

- [ ] **Step 2: Run the test and verify the current rendered extension fails**

Run:

```bash
bash scripts/test-blur-my-shell-source.sh
```

Expected: exit status 1 with `Missing Blur My Shell behavior: centralize panel monitor selection`.

- [ ] **Step 3: Add the focused Blur My Shell patch**

Create `patches/extensions/blur-my-shell/0003-fix-select-panel-blur-monitor-from-dash-to-panel.patch` with a mail-style patch that makes these exact changes to `src/components/panel.js` after patches 0001 and 0002:

```diff
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
@@
-            let monitor = Main.layoutManager.findMonitorForActor(panel);
+            let monitor = this.find_panel_monitor(panel);
@@
-        actors.monitor = Main.layoutManager.findMonitorForActor(panel);
+        actors.monitor = monitor;
```

The patch header must identify this as `Subject: [PATCH 3/3] fix: select panel blur monitor from Dash to Panel` and target only `src/components/panel.js`.

- [ ] **Step 4: Render the patched component**

Run:

```bash
bash scripts/prepare-components.sh blur-my-shell
```

Expected: exit status 0; the generated `components/panel.js` contains `find_panel_monitor(panel)` and no generated files outside the Blur My Shell install directory change.

- [ ] **Step 5: Run the regression test and verify it passes**

Run:

```bash
bash scripts/test-blur-my-shell-source.sh
```

Expected: exit status 0 with no output.

- [ ] **Step 6: Add the regression test to CI**

In `.github/workflows/pr-validate.yml`, add this step after `Prepare generated tree` and before `Check shell scripts`:

```yaml
      - name: Test Blur My Shell source
        run: bash ./scripts/test-blur-my-shell-source.sh
```

- [ ] **Step 7: Run syntax and component validation**

Run:

```bash
bash -n scripts/*.sh bluebuild/files/static/scripts/*.sh
bash scripts/check-active-edit-sessions.sh
bash scripts/prepare-components.sh blur-my-shell
bash scripts/test-blur-my-shell-source.sh
```

Expected: every command exits 0. The second render must produce no additional diff, proving deterministic output.

- [ ] **Step 8: Inspect the final diff without disturbing unrelated changes**

Run:

```bash
git status --short
git diff --check
git diff -- .github/workflows/pr-validate.yml scripts/test-blur-my-shell-source.sh patches/extensions/blur-my-shell bluebuild/files/generated/usr/share/gnome-shell/extensions/blur-my-shell@aunetx/components/panel.js docs/superpowers
```

Expected: `git diff --check` exits 0. Intended changes are limited to the listed test, workflow, patch queue, rendered extension, and design/plan documents; pre-existing `.gitignore` and NextPIP work remains untouched.

- [ ] **Step 9: Record manual GNOME verification requirements**

After the updated image is installed, verify both behaviors:

```text
1. Reboot and log in without first locking the session.
2. Confirm each taskbar blur matches the wallpaper on its own monitor.
3. Disconnect and reconnect the secondary monitor.
4. Confirm both recreated taskbar blurs still match their own monitor wallpapers.
```

No repository commit is part of this task unless the user requests one after reviewing the diff.
