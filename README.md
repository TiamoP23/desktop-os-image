# desktop-os-image

Manifest-driven BlueBuild repository for a personal Bazzite GNOME 50 image.

## Layout

- `bluebuild/` contains the BlueBuild recipe tree and image filesystem inputs.
- `.github/workflows/` contains CI validation and image publish workflows.
- `.githooks/` stores the versioned Git hooks that `just setup` installs.
- `.work/` is transient local state used by render and component edit helpers.
- `vendor/` is reserved for upstream Git submodules.
- `patches/` stores local patch queues for vendored components.
- `manifests/components.yml` is the source of truth for rendered components.
- `scripts/` contains deterministic local and CI helpers.

## Image base

The image builds from `ghcr.io/ublue-os/bazzite-gnome-nvidia:44.20260902` and layers the generated GNOME Shell extensions plus the existing desktop and DX customizations from this repository.

## Included extensions

- Dash to Panel
- Blur My Shell
- Coverflow Alt-Tab
- Clipboard Indicator
- Next PIP

The repository tracks upstream sources under `vendor/extensions/` and applies local patch queues from `patches/extensions/` before rendering them into `bluebuild/files/generated/`.

## Local workflow

Use the `justfile` entrypoints:

- Install the host-side prepare prerequisites first: `git`, `gettext`, `glib-compile-schemas`, `gnome-extensions`, `zip`, and `unzip`.
- `just setup` installs the git hook, syncs submodules, and prepares the generated tree.
- `just prepare [component]` rerenders all components or a single component.
- `just component-edit <component>` starts an edit session against a vendored component.
- `just component-finish <component>` exports the patch queue and rerenders that component.
- `just build` and `just switch` defer to the local BlueBuild CLI.

### Test a GNOME extension locally

Render Next PIP and package the generated extension for user-level testing:

```bash
bash ./scripts/prepare-components.sh nextpinp
mkdir -p artifacts
rm -f artifacts/nextpinp@leonid.nasedkin-patched.zip
(
  cd bluebuild/files/generated/usr/share/gnome-shell/extensions/nextpinp@leonid.nasedkin
  zip -qr "$OLDPWD/artifacts/nextpinp@leonid.nasedkin-patched.zip" .
)
gnome-extensions install --force artifacts/nextpinp@leonid.nasedkin-patched.zip
gnome-extensions enable nextpinp@leonid.nasedkin
```

GNOME Shell caches extension modules by UUID. Log out and back in before
retesting same-UUID code changes on Wayland. Remove the user copy with
`gnome-extensions uninstall nextpinp@leonid.nasedkin` before testing the copy
shipped by an installed image, because user extensions override system ones.

## Blur My Shell rounded blur helper

The upstream Blur My Shell guide is installed at `/usr/share/doc/blur-my-shell/GUIDE.md`, and the helper script is installed as `/usr/local/bin/rounded_blur_build.sh`.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading `cosign.pub` from this repo and running:

```bash
cosign verify --key cosign.pub ghcr.io/tiamop23/desktop-os-image
```
