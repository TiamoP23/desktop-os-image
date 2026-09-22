# Extension Refresh and Branch Consolidation Design

## Goal

Consolidate the currently useful desktop changes from local branches, worktrees,
stashes, and the locally tested GNOME extensions onto the newest appropriate
upstream component versions. Preserve tested behavior, remove local patches that
upstream has superseded, and produce a reproducible Bazzite GNOME 50 image.

The result is only a build candidate after automated verification. It becomes
owner-verified only after the owner installs the image, reboots into it, performs
the runtime checks in this document, and explicitly approves it.

## Integration Strategy

Create an isolated consolidation branch from the current `origin/main`. Recover
approved behavior and files selectively rather than merging obsolete branch
ancestry. This keeps the final history focused and avoids reintroducing stale
submodule pins, generated artifacts, old workflow experiments, and superseded
implementation plans.

Do not delete or rewrite existing branches, worktrees, or stashes while the
consolidated branch is a build candidate. They remain recovery sources until the
owner has verified the installed image. Do not edit files under
`bluebuild/files/generated/` directly and do not modify GitHub issues or pull
requests as part of this work.

## Version Policy

Use the newest stable release for each component by default. When a relevant
upstream fix landed after that release and replaces a local patch, pin the
specific newer upstream commit containing that fix. Every source remains pinned
to an immutable version or commit for reproducibility.

Update the base image from `44.20260608` to the current stable Bazzite GNOME
NVIDIA image, `44.20260902`. Pin `actions/checkout` v7.0.1 at
`3d3c42e5aac5ba805825da76410c181273ba90b1` and `blue-build/github-action`
v1.12.0 at `836161eb076426a451e6a0054f722b1153b8b3ad`.

## Extension Decisions

### Dash to Panel

Pin upstream commit `df8a15b`, which follows v73 and contains the GNOME 50
startup animation timing fix from upstream commit `19f0c64`. Remove local patch
`0002-fix-restore-hide-overview-on-startup-on-GNOME-50.patch`, whose behavior is
now upstream.

Retain and rebase the secondary-monitor overview behavior from
`0001-fix-keep-secondary-monitor-taskbars-visible-when-ove.patch`. Current
upstream still hides panels on non-focused monitors while the overview is open,
so this personal workflow override remains necessary.

### Blur My Shell

Pin upstream commit `b689b99`, which follows v72 and contains the newer Dash to
Panel geometry and deferred-layout fixes. Remove the existing geometry and
startup refresh patches:

- `0001-fix-size-panel-blur-against-dash-to-panel-panel-box.patch`
- `0002-fix-refresh-dash-to-panel-blur-layout-after-startup.patch`

Upstream commits `900c257`, `df0193c`, and `48d207f` supersede those patches with
more complete handling for geometry actors, allocation races, and dynamic panel
length.

Retain the later monitor-selection behavior from the
`fix-panel-blur-monitor` branch. Reimplement it against the new upstream panel
architecture so Dash to Panel's assigned `_dtpIndex` selects the wallpaper for
each static blur, with `findMonitorForActor()` retained as the fallback for
other panels. Adapt and retain its source regression test.

### Coverflow Alt-Tab

Pin release v87, which supports GNOME 50. Do not retain the older `8dfa64c` pin
from `update-coverflow-alt-tab-gnome-50`; it predates v87 and later upstream
crash and teardown fixes. Coverflow requires no local patch queue.

### Clipboard Indicator

Retain v71 because the repository already pins the newest upstream release and
there are no remaining local modifications to recover.

### Next PIP

Retain upstream commit `b6d29fa`, which is still the upstream default-branch
head. Upstream has not absorbed the locally tested functionality or fixes.

Regenerate the current five-patch behavior as a smaller coherent queue:

1. Persistent placement settings and preferences.
2. Remembered-monitor placement, correct workspace work-area lookup, animated
   snapping, and velocity-aware corner selection with ratio-based diagonal
   detection.
3. Existing-window management, window-list hiding, setting reapplication, and
   minimize-to-close lifecycle handling.

Retain the corrected `org.gnome.shell.extensions.auto-pip-manager` dconf path,
the component manifest cleanup, local testing documentation, and the source
regression test. Update that test to validate behavior rather than old patch
filenames.

## Superseded Work

Do not carry the obsolete history from `fix-corner-blur`,
`feat/compile-from-git`, `fix/blur-my-shell-popup`, or `add-agents-md`; their
useful outcomes are already merged or replaced. Do not carry the older
four-patch Next PIP worktree queue, stale generated/browser artifacts, the
one-line rounded-blur experiment, the removed ISO workflow experiment, or the
old `extensions.dconf` snapshot.

Planning documents that describe obsolete component names, old patch bases, or
already completed implementation steps are not part of the consolidated result.
Accurate operational documentation and regression tests are retained.

## Automated Candidate Verification

Before presenting the branch as a build candidate:

- Apply and render every retained patch queue successfully.
- Render all components twice and confirm that the second render is
  deterministic.
- Run shell syntax checks and all extension-specific source regression tests.
- Validate GSettings schemas and extension metadata.
- Confirm every shipped extension declares GNOME 50 support.
- Build the complete BlueBuild image successfully.
- Run applicable repository CI checks.
- Inspect the final diff for generated files, stale patches, obsolete stash
  content, and unrelated changes.

Passing these checks means only that the branch is a build candidate. It must not
be called owner-verified or fully verified at this stage.

## Owner Runtime Verification

The owner installs the candidate image and reboots into it. Before testing Next
PIP, remove or temporarily relocate the user-installed copy at
`~/.local/share/gnome-shell/extensions/nextpinp@leonid.nasedkin`, because a user
extension overrides the system extension shipped by the image.

Verify the following on the booted deployment:

- The deployment uses Bazzite base `44.20260902`.
- Dash to Panel, Blur My Shell, Coverflow Alt-Tab, Clipboard Indicator, and Next
  PIP load without GNOME Shell errors.
- Dash to Panel suppresses the startup overview and keeps the intended
  secondary-monitor panels visible in overview.
- Blur My Shell uses correct panel geometry and each monitor's own wallpaper
  after cold login and after disconnecting and reconnecting a monitor.
- Coverflow Alt-Tab is active on GNOME 50 rather than reported as `OUT OF DATE`.
- Next PIP remembers corner and monitor, uses the correct work area, animates
  snaps, recognizes diagonal velocity throws, hides managed PiP windows from the
  window list, and closes them when minimized.

Only the owner's explicit approval after these runtime checks changes the branch
state from build candidate to owner-verified.

## Failure Handling

If automated or runtime verification fails, keep the branch in candidate state,
record the failing behavior and relevant logs, make the smallest correction on
the same consolidation branch, rebuild, and repeat the affected checks. Existing
branches, worktrees, stashes, and the previous bootable deployment remain
untouched so recovery and comparison stay possible.
