#!/usr/bin/env bash
# Creates a symlink from the host user's home path to /home/dev so that
# absolute paths baked into ~/.claude config (e.g. known_marketplaces) resolve
# correctly inside the container.
#
# The host home is derived from /proc/self/mountinfo — no env var needed.

set -euo pipefail

TARGET_USER="${TARGET_USER:-dev}"
CONTAINER_HOME="/home/${TARGET_USER}"
CLAUDE_MOUNT="${CONTAINER_HOME}/.claude"

# Field 4 in mountinfo is the source root within the filesystem (the host path),
# field 5 is the mount target inside the container.
HOST_CLAUDE=$(awk -v target="$CLAUDE_MOUNT" '$5 == target { print $4; exit }' /proc/self/mountinfo)

if [[ -z "$HOST_CLAUDE" ]]; then
    echo "No bind mount found for ${CLAUDE_MOUNT}; skipping host-home symlink." >&2
    exit 0
fi

HOST_HOME=$(dirname "$HOST_CLAUDE")

if [[ "$HOST_HOME" == "$CONTAINER_HOME" ]]; then
    echo "Host home matches container home (${CONTAINER_HOME}); no symlink needed."
    exit 0
fi

PARENT=$(dirname "$HOST_HOME")
sudo mkdir -p "$PARENT"
sudo ln -sfn "$CONTAINER_HOME" "$HOST_HOME"
echo "Symlinked ${HOST_HOME} -> ${CONTAINER_HOME}"
