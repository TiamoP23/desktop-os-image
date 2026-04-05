#!/usr/bin/env bash

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Script must be run as root."
    exit 1
fi

VERSION="${VERSION:-latest}"

if command -v bluebuild >/dev/null 2>&1; then
    echo "BlueBuild already installed: $(bluebuild --version || true)"
    exit 0
fi

runtime() {
    if command -v podman >/dev/null 2>&1; then
        # Force podman to use the isolated storage config below during feature build.
        CONTAINERS_STORAGE_CONF=/tmp/bluebuild-storage.conf podman "$@"
    else
        echo "Podman is required to install BlueBuild."
        exit 1
    fi
}

configure_podman_for_nested_build() {
    # In this nested build environment, multi-ID mappings can fail.
    # Removing root mappings forces single-UID behavior.
    if [ -f /etc/subuid ]; then
        sed -i '/^root:/d' /etc/subuid
    fi
    if [ -f /etc/subgid ]; then
        sed -i '/^root:/d' /etc/subgid
    fi

    # Keep podman storage isolated from the container's default storage.
    mkdir -p /tmp/bluebuild-graphroot /tmp/bluebuild-runroot
    cat >/tmp/bluebuild-storage.conf <<'EOF'
[storage]
    driver = "vfs"
    graphroot = "/tmp/bluebuild-graphroot"
    runroot = "/tmp/bluebuild-runroot"

    # Allow pulling images that contain multiple UIDs in single-UID mode.
    [storage.options.vfs]
    ignore_chown_errors = "true"
EOF

    # Apply mapping/storage changes before pulling the installer image.
    podman system migrate >/dev/null 2>&1 || true
}

configure_podman_for_nested_build

if [ "${VERSION}" = "latest" ]; then
    IMAGE_TAG="latest"
else
    IMAGE_TAG="${VERSION#v}"
fi

INSTALLER_IMAGE="ghcr.io/blue-build/cli:${IMAGE_TAG}-installer"
CONTAINER_NAME="blue-build-installer"

cleanup() {
    # Best-effort cleanup: container may not exist if create failed.
    runtime rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
}

trap cleanup EXIT

runtime create --pull=always --name "${CONTAINER_NAME}" "${INSTALLER_IMAGE}" >/dev/null
runtime cp "${CONTAINER_NAME}":/out/bluebuild /tmp/bluebuild
install -m 0755 /tmp/bluebuild /usr/local/bin/bluebuild
rm -f /tmp/bluebuild

echo "BlueBuild installed: $(/usr/local/bin/bluebuild --version || true)"
