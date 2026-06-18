# desktop-os-image

Manifest-driven BlueBuild scaffold for a custom Bazzite 44 GNOME image.

## Layout

- `bluebuild/` contains the BlueBuild recipe tree and image-facing filesystem inputs.
- `.github/workflows/` contains CI validation and image publish workflows.
- `.githooks/` stores the versioned Git hook that `just setup` installs.
- `.work/` is transient local state used by render and component edit helpers.
- `vendor/` is a local cache for extension source checkouts.
- `patches/` stores local patch queues for vendored components.
- `manifests/components.yml` is the source of truth for pinned extension sources.
- `scripts/` contains deterministic local and CI helpers.

## Components

The image prepares and builds these GNOME Shell extensions:

- Dash to Panel
- Blur my Shell
- Coverflow Alt-Tab
- Clipboard Indicator

Existing custom patch queues are stored under `patches/extensions/`.

## Local Workflow

Use the `justfile` entrypoints:

- `just setup` installs the git hook and prepares the generated tree.
- `just prepare [component]` refreshes the generated extension source tree from the manifest and patch queue.
- `just component-list`, `just component-status`, `just component-edit`, `just component-finish`, `just component-abort`, and `just refresh-patches` manage local patch queues.
- `just generate`, `just build`, and `just switch` defer to the local BlueBuild CLI.

## Installation

To rebase an existing installation to the latest build:

```bash
rpm-ostree rebase ostree-unverified-registry:ghcr.io/tiamop23/desktop-os-image:latest
systemctl reboot
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/tiamop23/desktop-os-image:latest
systemctl reboot
```

## Blur my Shell rounded blur helper

The image includes the upstream helper assets from `aunetx/blur-my-shell`:

- Guide: `/usr/share/blur-my-shell/scripts/GUIDE.md`
- Install: `sudo /usr/local/bin/install-rounded-blur-helper -i`
- Uninstall: `sudo /usr/local/bin/install-rounded-blur-helper -u`

Re-run the helper after GNOME Shell or mutter updates because the library is built against the currently installed GNOME stack.

## Verification

These images are signed with Sigstore cosign:

```bash
cosign verify --key bluebuild/cosign.pub ghcr.io/tiamop23/desktop-os-image
```
