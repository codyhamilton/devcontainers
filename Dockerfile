FROM debian:bookworm-slim

# ── System packages ──────────────────────────────────────────────────────────
# bubblewrap: required for codex sandboxing
# jq: JSON wrangling in devcontainer scripts
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    gh \
    ca-certificates \
    gnupg \
    lsb-release \
    procps \
    vim \
    sudo \
    zip \
    unzip \
    jq \
    bubblewrap \
    && rm -rf /var/lib/apt/lists/*

# ── Node.js 22 ───────────────────────────────────────────────────────────────
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ── dev user ─────────────────────────────────────────────────────────────────
RUN useradd -m -s /bin/bash dev \
    && echo "dev ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/dev \
    && chmod 0440 /etc/sudoers.d/dev

# ── uv ───────────────────────────────────────────────────────────────────────
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# ── Devcontainer scripts ──────────────────────────────────────────────────────
# Baked into the image at a stable path so per-repo hooks can reference them
# without knowing the workspace checkout location.
COPY .devcontainer/scripts/ /usr/local/lib/devcontainer/
RUN chmod +x /usr/local/lib/devcontainer/*.sh

ENV SSH_AUTH_SOCK=/ssh-agent

# Mark /workspaces as safe for all users — avoids git's dubious ownership
# error when the workspace is bind-mounted from the host. Set at system level
# so the per-user ~/.gitconfig bind-mount doesn't shadow it.
RUN git config --system safe.directory /workspaces

WORKDIR /workspaces
USER dev

# ── GitHub CLI authentication ────────────────────────────────────────────────────
# Optional: authenticate gh CLI at build time using a build arg.
# Token is consumed once during build and never persisted in the image.
# Usage: devcontainer build --build-arg GITHUB_TOKEN=$GITHUB_TOKEN
ARG GITHUB_TOKEN=""
RUN if [ -n "$GITHUB_TOKEN" ]; then \
      echo "$GITHUB_TOKEN" | gh auth login --with-token --hostname github.com && \
      gh auth status; \
    fi

# Pre-create bind-mount targets so Docker does not materialize root-owned
# placeholders at runtime.
RUN mkdir -p \
    /home/dev/.claude \
    /home/dev/.codex \
    /home/dev/.cursor

# ── AI CLIs ──────────────────────────────────────────────────────────────────
# Installed as the dev user so both tools can self-update without elevated
# privileges.
#
# claude: native installer — no npm dependency, supports `claude update`.
#         Installs to ~/.local/bin.
#
# codex: npm is still the only install method; prefix set to ~/.npm-global
#        so the dev user owns the package tree and can run `npm i -g` updates.
#        Pinned to packages published at least 7 days ago for supply-chain
#        stability; postStartCommand refreshes to latest on each container
#        start.
ENV PATH="/home/dev/.local/bin:/home/dev/.npm-global/bin:${PATH}"

RUN curl -fsSL https://claude.ai/install.sh | bash

RUN npm config set prefix /home/dev/.npm-global && \
    npm install -g @openai/codex \
    --before="$(date -u -d '7 days ago' +%F)"
