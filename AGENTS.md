# Agent Guide

## Project Motivation

This repository builds a personal Fedora Atomic desktop image based on Bazzite GNOME. The image is tuned for one user's gaming and software development workflow. It is not intended to become a public distro, a broadly supported remix, or a general-purpose community image.

Optimize for the owner's daily desktop experience, maintainability, and reproducible personal setup. Avoid adding generic features just because they might be useful to other users.

## Project Structure

- `bluebuild/recipes/main.yml` is the main BlueBuild recipe.
- `bluebuild/recipes/desktop.yml` contains desktop, GNOME, theme, extension, and shell customization modules.
- `bluebuild/recipes/dx.yml` contains developer experience tooling such as VS Code, Podman Desktop, and devcontainer setup.
- `bluebuild/files/static/` contains files copied into the image, including dconf defaults, scripts, docs, and skeleton user config.
- `bluebuild/files/generated/` contains rendered generated files and should not be edited directly.
- `manifests/components.yml` is the source of truth for rendered vendored components.
- `vendor/` contains upstream submodules, mainly GNOME extensions.
- `patches/` contains local patch queues for vendored components.
- `scripts/` contains deterministic helper scripts for preparing generated components and managing patch workflows.

## Planning Context

- The current desktop customization overview is tracked in issue #30: https://github.com/TiamoP23/desktop-os-image/issues/30
- Create implementation PRs against the individual issues linked from that overview.
- Create or update GitHub issues only after the owner approves the requirements.

## Working Guidelines

- Keep changes minimal and focused on the owner's explicit desktop goals.
- Prefer Bazzite defaults when they already provide the desired behavior.
- Do not duplicate Bazzite defaults in this repo unless overriding behavior or documenting required configuration.
- Vendor or patch GNOME extensions only when the image modifies them or must guarantee a specific version/behavior.
- Keep host-used extensions as useful reference, not automatic image requirements.
- Do not edit generated files under `bluebuild/files/generated/`; update manifests, vendored sources, patches, or static inputs instead.
- If running inside Distrobox, use `distrobox-host-exec` to inspect host GNOME settings, extensions, Flatpaks, and other host-only tools.

## Host State Inspection

Useful commands when running from a Distrobox container:

```bash
distrobox-host-exec gnome-extensions list --enabled
distrobox-host-exec dconf dump /org/gnome/shell/
distrobox-host-exec dconf dump /org/gnome/desktop/interface/
distrobox-host-exec dconf dump /org/gnome/desktop/wm/
distrobox-host-exec dconf dump /org/gnome/mutter/
```

Use these commands to compare live desktop behavior with repo defaults before proposing changes.
