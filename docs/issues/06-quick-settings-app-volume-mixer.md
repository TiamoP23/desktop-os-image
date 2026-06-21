# Evaluate Quick Settings Audio Panel for Windows-like App Volume Mixer

## Goal

Add a Windows 11-like application volume mixer to GNOME Quick Settings.

## Requirements

- [x] Use Quick Settings Audio Panel as the first candidate to evaluate.
- [x] Keep the mixer inside or near GNOME Quick Settings rather than as a separate full app.
- [x] Prefer a compact UI that matches the translucent GNOME shell style.
- [ ] Confirm whether Quick Settings Audio Panel exposes per-application volume streams, not only output devices and media controls.
- [ ] Review the extension's available settings before deciding to patch it.
- [ ] Decide whether the default UI is acceptable after configuration tweaks.
- [ ] If the UI is not acceptable, evaluate patching the extension before building a replacement.
- [ ] If patching is required, define the target compact Windows-like layout.
- [ ] Package and enable the selected mixer implementation in the image if it proves useful.
- [ ] Verify behavior with multiple active audio sources such as browser, game, Discord, and media player.

## Candidate Extension

Name: Quick Settings Audio Panel

GNOME Extensions page: `https://extensions.gnome.org/extension/5940/quick-settings-audio-panel/`

Upstream: `https://github.com/Rayzeq/quick-settings-audio-panel`

The extension supports GNOME Shell 44 through current versions according to the GNOME Extensions page, making it a plausible candidate for this image.
