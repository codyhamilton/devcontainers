#!/usr/bin/env bash
# Runs inside the container on every devcontainer start.
# Each step is independent — a failure is reported but never aborts the script.

set -uo pipefail

PASS="\033[32m✔\033[0m"
FAIL="\033[33m⚠\033[0m"

run_step() {
    local label="$1"; shift
    local err
    if err=$("$@" 2>&1); then
        echo -e "  ${PASS} ${label}"
    else
        echo -e "  ${FAIL} ${label} — ${err}"
    fi
}

echo "==> base devcontainer post-start"

run_step "fix mount ownership"  bash /usr/local/lib/devcontainer/fix-mount-ownership.sh
run_step "sync codex skills"    bash /usr/local/lib/devcontainer/sync-codex-skills.sh
run_step "start docker daemon"  bash /usr/local/lib/devcontainer/start-docker.sh

echo "==> ready"
