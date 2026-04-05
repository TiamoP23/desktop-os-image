#!/usr/bin/env bash
set -e

SOCAT_LOG=/tmp/vscr-podman-from-podman.log
SOCAT_PID=/tmp/vscr-podman-from-podman.pid

sudoIf() {
    if [ "$(id -u)" -ne 0 ]; then
        sudo "$@"
    else
        "$@"
    fi
}

# Resolve the Podman socket path from CONTAINER_HOST (strip unix:// prefix)
# or fall back to the default mount location.
SOURCE_SOCKET="${CONTAINER_HOST:-unix:///var/run/podman/podman.sock}"
SOURCE_SOCKET="${SOURCE_SOCKET#unix://}"
TARGET_SOCKET="/var/run/podman.sock"

if [ -S "${SOURCE_SOCKET}" ] && [ "$(id -u)" != "0" ]; then
    SOCKET_GID=$(stat -c '%g' "${SOURCE_SOCKET}")

    # Check whether the current user already belongs to the socket's GID.
    if echo " $(id -G) " | grep -qw "${SOCKET_GID}"; then
        # Direct access is already available; use the source socket as-is.
        :
    else
        # Bridge the socket via socat so we can set owner/permissions
        # without touching the host socket itself.
        if [ ! -f "${SOCAT_PID}" ] || ! kill -0 "$(cat "${SOCAT_PID}")" 2>/dev/null; then
            sudoIf rm -f "${TARGET_SOCKET}"
            (
                sudoIf socat \
                    UNIX-LISTEN:"${TARGET_SOCKET}",fork,mode=660,user="$(id -un)",group=podman \
                    UNIX-CONNECT:"${SOURCE_SOCKET}" \
                    > "${SOCAT_LOG}" 2>&1 \
                    & echo "$!" | sudoIf tee "${SOCAT_PID}" > /dev/null
            )
        fi

        export CONTAINER_HOST="unix://${TARGET_SOCKET}"
        export DOCKER_HOST="unix://${TARGET_SOCKET}"
    fi
fi

exec "$@"
