#!/usr/bin/env bash

set -euo pipefail

# Fix workspace mounts
for mount_path in $(cat /proc/mounts | awk '/.*\/workspaces.*/ { print $2 }'); do
    if [[ -n "$mount_path" ]] && [[ -e "$mount_path" ]]; then
        sudo chown 1000:1000 "$mount_path"
    fi
done

# Fix known volume mounts
for dir in /home/dev/.claude/plugins /home/dev/.codex/skills; do
    if [[ -e "$dir" ]]; then
        sudo chown 1000:1000 "$dir"
    fi
done
