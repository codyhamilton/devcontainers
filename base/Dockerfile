FROM debian:bookworm-slim

# ── System packages ──────────────────────────────────────────────────────────
# bubblewrap: required for codex sandboxing
# jq: JSON wrangling in devcontainer scripts
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
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

# ── AI CLIs ──────────────────────────────────────────────────────────────────
# Pinned to packages published at least 7 days ago for supply-chain stability.
RUN npm install -g @anthropic-ai/claude-code @openai/codex \
    --before="$(date -u -d '7 days ago' +%F)"

# ── uv ───────────────────────────────────────────────────────────────────────
RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh

# ── Devcontainer scripts ──────────────────────────────────────────────────────
# Baked into the image at a stable path so per-repo hooks can reference them
# without knowing the workspace checkout location.
COPY scripts/ /usr/local/lib/devcontainer/
RUN chmod +x /usr/local/lib/devcontainer/*.sh

WORKDIR /workspaces
USER dev

# Pre-create bind-mount targets so Docker does not materialize root-owned
# placeholders at runtime.
RUN mkdir -p \
    /home/dev/.claude \
    /home/dev/.codex \
    /home/dev/.cursor
