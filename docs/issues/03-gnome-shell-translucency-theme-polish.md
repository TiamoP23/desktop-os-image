# Configure GNOME Shell Translucency and Theme Polish

## Goal

Create a restrained Windows 11 Dark-inspired visual style with selected gaming-style accents, focused on translucency and polish rather than flashy effects.

## Requirements

- [x] Prefer dark color scheme by default.
- [x] Use Blur My Shell as the blur/translucency foundation.
- [x] Configure a translucent Dash to Panel taskbar.
- [x] Make the taskbar less transparent when a window is near it.
- [x] Configure dynamic taskbar opacity behavior.
- [x] Use translucent or rounded Blur My Shell popup pipelines where available.
- [ ] Define the exact target GTK/libadwaita theme approach.
- [ ] Decide whether `user-theme@gnome-shell-extensions.gcampax.github.com` should be configured explicitly or left as a host preference.
- [ ] Make GNOME shell popup menus translucent in the image defaults.
- [ ] Add selected translucent backgrounds in app windows where practical and stable.
- [ ] Keep any gaming-style accents subtle and non-distracting.
- [ ] Verify the theme does not reduce readability, especially in quick settings and context menus.

## Current Evidence

The repo already sets `color-scheme='prefer-dark'`, installs Blur My Shell, and configures Dash to Panel transparency. The host currently uses `trans-panel-opacity=0.0`, `trans-use-dynamic-opacity=true`, `trans-dynamic-anim-target=0.8`, and `trans-dynamic-distance=20`, which better matches the target than the repo's current opacity values.

## Style Direction

Baseline: Windows 11 Dark.

Accent: small amount of darker gaming-style personality only where it improves the desktop without making it noisy.
