# Evaluate and Implement Minimal Quake Terminal

## Goal

Provide a minimal top drop-down terminal for development workflows without adopting a heavy terminal manager UI.

## Requirements

- [x] Use classic top drop-down behavior as the target interaction model.
- [x] Use full screen width.
- [x] Use roughly 35-45% screen height.
- [x] Use the physical QWERTZ key labeled `^` and `°` with `Super` as the toggle keybinding.
- [x] Require both modern shortcuts and PuTTY-style copy/paste behavior if possible.
- [ ] Compare Ghostty, Ptyxis, Kitty, WezTerm, Guake, and GNOME extension-based approaches.
- [ ] Use Ghostty as the leading candidate unless comparison shows a better fit.
- [ ] Confirm whether Ghostty supports the required copy/paste behavior cleanly.
- [ ] Confirm whether the chosen terminal can support minimal Quake behavior without visual clutter.
- [ ] Prefer active/current monitor behavior if the implementation supports it.
- [ ] Decide whether this should be implemented through terminal config, a GNOME extension, a wrapper script, or an existing Quake terminal app.
- [ ] Package and configure the selected implementation in the image.
- [ ] Verify keybinding behavior on QWERTZ layouts.

## Copy/Paste Target

- `Ctrl+C` and `Ctrl+V` should behave like modern copy/paste when text is selected or paste is intended.
- Terminal interrupt behavior must remain usable.
- Selecting text should copy immediately if supported.
- Right-click should paste if supported.

## Notes

The owner has not found an existing Quake terminal that feels fully right. Treat this as an evaluation and prototype issue, not a pre-decided package install.
