# Configure Windows-like Dash to Panel Taskbar

## Goal

Make the default GNOME panel behave like a polished Windows-style taskbar while preserving the owner's current Bazzite GNOME workflow.

## Requirements

- [x] Use Dash to Panel as the taskbar extension.
- [x] Enable user GNOME extensions by default.
- [x] Place the app/show-applications button on the left side of the panel.
- [x] Hide the GNOME Activities button from the primary taskbar layout.
- [x] Keep running and pinned app icons in the central taskbar area.
- [x] Keep the date menu, system menu, and status area on the right side.
- [x] Support multi-monitor panel behavior.
- [x] Hide the overview on startup for a desktop-first boot experience.
- [x] Use app icon spacing that is tighter than the current repo default where appropriate.
- [x] Keep favorites aligned with the owner workflow: Files, Zen Browser, and Code on the host.
- [ ] Persist the final desired favorites in image defaults once the browser/application list is finalized.
- [ ] Replace monitor-serial-specific panel layout settings with a durable default if possible.
- [ ] Verify the final layout after rebasing onto the built image.

## Current Evidence

The repo already ships Dash to Panel settings in `bluebuild/files/static/system/etc/dconf/db/local.d/00-zorin-like-shell`. The host currently has Dash to Panel enabled and uses a similar Windows-style panel, with tighter `appicon-margin=4` and `appicon-padding=6`.

## Notes

Avoid broad desktop behavior extensions unless they are needed for this explicit taskbar target.
