#!/usr/bin/env bash

set -euo pipefail

SOURCE_ROOT="${HOME}/.claude/skills"
TARGET_ROOT="${HOME}/.codex/skills"

if [[ -z "${CODEX_SKILL_PREFIX:-}" ]]; then
    echo "ERROR: CODEX_SKILL_PREFIX is not set. Set it in your repo's devcontainer.json remoteEnv." >&2
    exit 1
fi

PREFIX="${CODEX_SKILL_PREFIX}"

mkdir -p "$TARGET_ROOT"

find "$TARGET_ROOT" -mindepth 1 -maxdepth 1 -name "${PREFIX}*" -print0 2>/dev/null | while IFS= read -r -d '' entry_path; do
    rm -rf "$entry_path"
done

if [[ ! -d "$SOURCE_ROOT" ]]; then
    exit 0
fi

find "$SOURCE_ROOT" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' skill_dir; do
    [[ -f "$skill_dir/SKILL.md" ]] || continue

    skill_name="$(basename "$skill_dir")"
    target_dir="${TARGET_ROOT}/${PREFIX}${skill_name}"

    rm -rf "$target_dir"
    cp -a "$skill_dir" "$target_dir"
done
