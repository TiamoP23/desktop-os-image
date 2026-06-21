# Configure Compact Windows-like Tray Overflow

## Goal

Make the right side of the taskbar feel like Windows: important tray icons remain visible with tight spacing, while less-used icons are available from a compact overflow/collapsed group where possible.

## Requirements

- [x] Use Bazzite's existing tray/AppIndicator support rather than replacing it unnecessarily.
- [x] Enable AppIndicator compact mode when configuring the host-style default.
- [x] Preserve legacy tray support for apps that still need it.
- [x] Keep tray icons visually compact.
- [ ] Decide which tray icons should be considered curated/important enough to stay visible.
- [ ] Determine whether the existing AppIndicator extension can provide a Windows-like overflow/collapsed group.
- [ ] If overflow is unsupported, evaluate whether patching AppIndicator support is practical.
- [ ] Keep the tray styling consistent with the translucent taskbar theme.
- [ ] Verify behavior with common gaming/dev apps such as Steam, Discord, GSConnect, Caffeine, and background utilities.

## Current Evidence

The host has `appindicatorsupport@rgcjonas.gmail.com` enabled with `compact-mode-enabled=true`, `legacy-tray-enabled=true`, and custom icon opacity settings. Bazzite already provides the tray extension, so the image should avoid redundant installation unless configuration or patching is required.
