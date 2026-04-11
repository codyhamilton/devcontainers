#!/usr/bin/env bash

set -euo pipefail

TARGET_USER="${TARGET_USER:-dev}"
TARGET_GROUP="${TARGET_GROUP:-$TARGET_USER}"

decode_mount_path() {
    local path="$1"
    path="${path//\\040/ }"
    path="${path//\\011/$'\t'}"
    path="${path//\\012/$'\n'}"
    path="${path//\\134/\\}"
    printf '%s\n' "$path"
}

is_workspace_mount() {
    local path="$1"
    [[ "$path" == /workspaces || "$path" == /workspaces/* ]]
}

repair_mountpoint() {
    local mount_path="$1"

    [[ -n "$mount_path" ]] || return 0
    [[ -e "$mount_path" ]] || return 0

    echo "Repairing ownership for mountpoint: $mount_path"
    if ! sudo chown "${TARGET_USER}:${TARGET_GROUP}" "$mount_path"; then
        echo "Warning: unable to repair mountpoint ownership for $mount_path; continuing" >&2
    fi
}

mapfile -t raw_mounts < <(awk '{ print $2 }' /proc/mounts)
mount_targets=()

for raw_path in "${raw_mounts[@]}"; do
    path="$(decode_mount_path "$raw_path")"
    if is_workspace_mount "$path"; then
        mount_targets+=("$path")
    fi
done

while IFS= read -r mount_path; do
    repair_mountpoint "$mount_path"
done < <(printf '%s\n' "${mount_targets[@]}" | awk '!seen[$0]++' | sort)

# Explicitly repair known volume mounts inside the home directory.
# These are not bind mounts and won't appear as workspace mounts, but Docker
# creates them root-owned and the container user needs write access.
for dir in /home/dev/.claude/plugins /home/dev/.codex/skills; do
    repair_mountpoint "$dir"
done
