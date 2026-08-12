# Panel Blur Monitor Selection Design

## Problem

At initial login, Blur My Shell can create the primary Dash-to-Panel blur from
the secondary monitor's wallpaper. Locking and unlocking fixes the panel because
Blur My Shell destroys and recreates its user-session components after monitor
geometry has stabilized.

The existing local patches refresh blur geometry after startup, but the static
blur's `BackgroundManager` retains the monitor index selected when it was
created. A later geometry refresh cannot change its wallpaper source.

## Root Cause

Blur My Shell selects a panel's monitor with
`Main.layoutManager.findMonitorForActor(panel)`. During login, GNOME Shell has
not necessarily allocated the panel at its final transformed position, so this
lookup can return the wrong monitor. Dash-to-Panel already stores the intended
monitor index on each panel's immediate parent as `_dtpIndex` before enabling
the panel.

## Design

Add one panel-monitor resolver to Blur My Shell's panel component. For a
Dash-to-Panel panel, resolve the monitor from the immediate parent actor's
`_dtpIndex`. For other panel implementations, preserve the existing
`findMonitorForActor()` behavior.

Use this resolver when:

- Creating the static blur background and its `BackgroundManager`.
- Calculating monitor-relative static blur geometry.
- Updating the monitor stored with the panel's blur actors.

The existing `monitors-changed` and `workareas-changed` reset path will recreate
panel blur actors after a monitor disconnect or reconnect. The resolver will
then use the new Dash-to-Panel monitor assignments rather than transient actor
geometry.

## Scope

This change affects only monitor selection for panel blur. It does not change
Dash-to-Panel layout, blur appearance, settings, startup delays, or non-panel
Blur My Shell components.

## Verification

Add a deterministic source-level regression test that verifies:

- Dash-to-Panel's `_dtpIndex` is preferred over transformed actor geometry.
- Non-Dash-to-Panel panels retain the actor-based fallback.
- Creation and geometry updates use the shared resolver.

Render generated components from the manifest and run the repository's existing
validation checks. Final behavioral verification requires a fresh GNOME login
and a monitor disconnect/reconnect because GNOME Shell cannot reload extensions
in place under the active Wayland session.
