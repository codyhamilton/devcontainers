#!/usr/bin/env bash
# Validates that the base devcontainer image satisfies key requirements.
# Usage: ./test.sh [image-name]
#   image-name defaults to devcontainers-base:local

set -euo pipefail

IMAGE="${1:-devcontainers-base:local}"

PASS=0
FAIL=0

pass() { printf '  \033[32mPASS\033[0m %s\n' "$1"; ((PASS++)) || true; }
fail() { printf '  \033[31mFAIL\033[0m %s\n' "$1"; ((FAIL++)) || true; }

section() { printf '\n%s\n' "$1"; }

# ── Image existence ───────────────────────────────────────────────────────────
section "Image"

if docker image inspect "$IMAGE" &>/dev/null; then
    pass "image $IMAGE exists"
else
    fail "image $IMAGE not found — run 'make build' first"
    echo ""
    echo "0 passed, 1 failed"
    exit 1
fi

# ── OCI label (devcontainer.metadata) ────────────────────────────────────────
section "devcontainer.metadata label"

METADATA=$(docker inspect "$IMAGE" --format '{{index .Config.Labels "devcontainer.metadata"}}')

if [[ -n "$METADATA" ]]; then
    pass "label present"
else
    fail "label missing"
    METADATA="[]"
fi

if echo "$METADATA" | jq '.' &>/dev/null; then
    pass "label is valid JSON"
else
    fail "label is not valid JSON"
    METADATA="[]"
fi

check_label() {
    local desc="$1"
    local jq_query="$2"
    if echo "$METADATA" | jq -e "$jq_query" &>/dev/null; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

check_label '~/.claude bind mount declared' \
    '[.mounts[]? | select(contains("/.claude,"))] | length > 0'

check_label '~/.claude.json bind mount declared' \
    '[.mounts[]? | select(contains("/.claude.json,"))] | length > 0'

check_label '~/.gitconfig bind mount declared' \
    '[.mounts[]? | select(contains("/.gitconfig,"))] | length > 0'

check_label '~/.codex bind mount declared' \
    '[.mounts[]? | select(contains("/.codex,"))] | length > 0'

check_label 'codex-skills volume mount declared' \
    '[.mounts[]? | select(contains("codex-skills,"))] | length > 0'

check_label 'ANTHROPIC_API_KEY in remoteEnv' \
    '.remoteEnv.ANTHROPIC_API_KEY != null'

check_label 'OPENAI_API_KEY in remoteEnv' \
    '.remoteEnv.OPENAI_API_KEY != null'

check_label 'postCreateCommand absent (install baked into image)' \
    '.postCreateCommand == null'

check_label 'postStartCommand references fix-mount-ownership.sh' \
    '.postStartCommand | (type == "string") and contains("fix-mount-ownership.sh")'

check_label 'postStartCommand references sync-codex-skills.sh' \
    '.postStartCommand | (type == "string") and contains("sync-codex-skills.sh")'

check_label 'postStartCommand references git safe.directory' \
    '.postStartCommand | (type == "string") and contains("safe.directory")'

check_label 'postStartCommand runs claude update' \
    '.postStartCommand | (type == "string") and contains("claude update")'

check_label 'postStartCommand runs npm install -g @openai/codex' \
    '.postStartCommand | (type == "string") and contains("npm install -g @openai/codex")'

# ── In-container checks ───────────────────────────────────────────────────────
section "Container internals (running as dev)"

run() {
    docker run --rm --user dev "$IMAGE" bash -c "$1" 2>/dev/null
}

check() {
    local desc="$1"
    local cmd="$2"
    if run "$cmd" &>/dev/null; then
        pass "$desc"
    else
        fail "$desc"
    fi
}

check 'user is dev'                           '[ "$(whoami)" = dev ]'
check 'WORKDIR is /workspaces'                '[ "$(pwd)" = /workspaces ]'
check '/home/dev/.claude exists'              '[ -d /home/dev/.claude ]'
check '/home/dev/.codex exists'               '[ -d /home/dev/.codex ]'
check 'passwordless sudo works'               'sudo true'
check 'node v22'                              'node --version | grep -q "^v22\."'
check 'npm available'                         'which npm'
check 'git available'                         'which git'
check 'curl available'                        'which curl'
check 'jq available'                          'which jq'
check 'bwrap (bubblewrap) available'          'which bwrap'
check 'claude CLI available'                  'which claude'
check 'codex CLI available'                   'which codex'
check 'fix-mount-ownership.sh executable'     '[ -x /usr/local/lib/devcontainer/fix-mount-ownership.sh ]'
check 'sync-codex-skills.sh executable'       '[ -x /usr/local/lib/devcontainer/sync-codex-skills.sh ]'

# ── sync-codex-skills.sh fails fast without CODEX_SKILL_PREFIX ───────────────
section "Script behaviour"

no_prefix_out=$(docker run --rm --user dev "$IMAGE" \
    bash /usr/local/lib/devcontainer/sync-codex-skills.sh 2>&1) || true
if echo "$no_prefix_out" | grep -q "CODEX_SKILL_PREFIX"; then
    pass "sync-codex-skills.sh errors with clear message when CODEX_SKILL_PREFIX unset"
else
    fail "sync-codex-skills.sh did not error as expected without CODEX_SKILL_PREFIX"
fi

if docker run --rm --user dev \
    -e CODEX_SKILL_PREFIX=test__ \
    "$IMAGE" \
    bash /usr/local/lib/devcontainer/sync-codex-skills.sh 2>&1; then
    pass "sync-codex-skills.sh exits cleanly with CODEX_SKILL_PREFIX set and no skills dir"
else
    fail "sync-codex-skills.sh failed unexpectedly with CODEX_SKILL_PREFIX set"
fi

# ── Summary ───────────────────────────────────────────────────────────────────
printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
