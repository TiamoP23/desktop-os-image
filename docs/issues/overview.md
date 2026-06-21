# Desktop OS Image Issue Overview

This directory tracks approved local issue drafts for the personal Bazzite GNOME image. GitHub issues should be created only after the owner approves the local draft content.

## Scope

The image targets a Windows/Zorin-like GNOME desktop for gaming and software development. It should mostly preserve the owner's current Bazzite GNOME workflow, while making selected behaviors reproducible in the image.

This is a personal-use image, not a public distro.

## Draft Issues

Checked items in the issue drafts mean the behavior is already present in the repo or host state, or the requirement has been explicitly decided. Unchecked items are implementation, evaluation, or verification work that remains.

| Local Draft | Title | GitHub Issue | Status |
| --- | --- | --- | --- |
| `01-windows-like-dash-to-panel-taskbar.md` | Configure Windows-like Dash to Panel taskbar | Not created | Draft |
| `02-compact-windows-like-tray-overflow.md` | Configure compact Windows-like tray overflow | Not created | Draft |
| `03-gnome-shell-translucency-theme-polish.md` | Configure GNOME shell translucency and theme polish | Not created | Draft |
| `04-next-pip-monitor-corner-snapping.md` | Patch Next PIP for remembered monitor/corner and improved snapping | Not created | Draft |
| `05-minimal-quake-terminal.md` | Evaluate and implement minimal Quake terminal | Not created | Draft |
| `06-quick-settings-app-volume-mixer.md` | Evaluate Quick Settings Audio Panel for Windows-like app volume mixer | Not created | Draft |

## Reference Decisions

- Prefer a Windows 11-like GNOME workflow over stock GNOME behavior.
- Use Bazzite defaults where they already work well.
- Do not explicitly restate Bazzite defaults unless overriding behavior or making required configuration reproducible.
- Vendor or patch only extensions that are modified or must be guaranteed by the image.
- Keep the taskbar translucent, with dynamic opacity near windows.
- Keep tray icons compact, with important items visible and the rest in an overflow/collapsed group where possible.
- Use Ghostty as the leading terminal candidate, but compare alternatives before deciding.
