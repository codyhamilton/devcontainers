#!/usr/bin/env bash

set -euo pipefail

WORKSPACE_DIR="${containerWorkspaceFolder:-$(pwd)}"
SOURCE_ROOT="${WORKSPACE_DIR}/.claude/skills"
TARGET_ROOT="${HOME}/.codex/skills"

if [[ -z "${CODEX_SKILL_PREFIX:-}" ]]; then
    echo "ERROR: CODEX_SKILL_PREFIX is not set. Set it in your repo's devcontainer.json remoteEnv." >&2
    exit 1
fi

PREFIX="${CODEX_SKILL_PREFIX}"

mkdir -p "$TARGET_ROOT"

find "$TARGET_ROOT" -maxdepth 1 -xtype l -name "${PREFIX}*" -print0 2>/dev/null | while IFS= read -r -d '' link_path; do
    rm -f "$link_path"
done

if [[ ! -d "$SOURCE_ROOT" ]]; then
    exit 0
fi

find "$SOURCE_ROOT" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' skill_dir; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue

    skill_name="$(basename "$skill_dir")"
    target_link="${TARGET_ROOT}/${PREFIX}${skill_name}"

    rm -rf "$target_link"
    ln -s "$skill_dir" "$target_link"
done
