# Devcontainers — Agent Instructions

## Project
Builds a base devcontainer Docker image with AI CLIs (Claude Code, Codex), Node.js 22, `uv`,
and lifecycle helper scripts. The `.devcontainer/` at repo root uses the locally built image.

## Key Commands
- `make build` — build image (uses `devcontainer` CLI, image: `devcontainers-base:local`)
- `make test` or `./test.sh [image]` — run tests against built image (requires Docker + built image)
- `IMAGE=my-tag make build test` — build and test with custom tag

## Important Conventions
- npm global installs use `--before="$(date -u -d '7 days ago' +%F)"` — intentional supply-chain stability lag; do not remove
- Scripts are baked into `/usr/local/lib/devcontainer/` in the image (copied from `scripts/`)
- `devcontainer.metadata` OCI label must declare all bind mounts and `remoteEnv` — tests validate this label
- `CODEX_SKILL_PREFIX` env var is required by `sync-codex-skills.sh`; set in repo's `devcontainer.json` `remoteEnv`

## devcontainer.metadata OCI Label
**Not all devcontainer.json properties map to the image label.** Only properties marked with 🏷️
in the spec are included in `devcontainer.metadata`. Before assuming a config key will be baked
into the image, check the authoritative reference:
https://containers.dev/implementors/json_reference/

## Git Conventions
- Use conventional commit syntax: `type(scope): description` (e.g. `feat:`, `fix:`, `chore:`, `docs:`)
- Auto-commit changes after completing work — do not wait to be asked
- Decide whether to amend the last commit or create a new one:
  - **Amend** if the current change directly resolves an issue introduced in the immediate prior commit
  - **New commit** otherwise

## Structure
- `Dockerfile` — image definition (debian:bookworm-slim base)
- `scripts/fix-mount-ownership.sh` — repairs bind-mount ownership at container start (reads `/proc/mounts`)
- `scripts/sync-codex-skills.sh` — symlinks `.claude/skills/` into `~/.codex/skills/` with a prefix
- `test.sh` — validates image internals and OCI labels via `docker run`
