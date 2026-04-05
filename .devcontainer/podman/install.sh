#!/usr/bin/env bash

set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    echo "Script must be run as root. Use sudo or add 'USER root' to your Dockerfile."
    exit 1
fi

# ---------------------------------------------------------------------------
# Determine the non-root user that will run inside the container.
# _REMOTE_USER is injected by the devcontainer CLI when running install.sh.
# ---------------------------------------------------------------------------
USERNAME="${_REMOTE_USER:-}"
if [ -z "${USERNAME}" ] || [ "${USERNAME}" = "root" ]; then
    USERNAME="$(awk -F ":" '$3==1000{print $1; exit}' /etc/passwd || true)"
    USERNAME="${USERNAME:-root}"
fi

echo "Configuring Podman feature for user: ${USERNAME}"

export DEBIAN_FRONTEND=noninteractive

apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* 2>/dev/null | wc -l)" = "0" ]; then
        apt-get update -y
    fi
}

check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get install -y --no-install-recommends "$@"
    fi
}

check_packages podman socat

# The podman group is used by the runtime entrypoint when proxying the socket.
if ! grep -qE '^podman:' /etc/group; then
    groupadd --system podman
fi

if [ "${USERNAME}" != "root" ]; then
    usermod -aG podman "${USERNAME}"
fi

install -m 0755 ./podman-init.sh /usr/local/share/podman-init.sh

rm -rf /var/lib/apt/lists/*

echo "Done! Podman installed: $(podman --version)"
