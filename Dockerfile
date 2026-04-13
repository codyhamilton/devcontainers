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

# ── Docker CE ────────────────────────────────────────────────────────────────
# Install the full Docker engine (client + daemon + buildx + compose) so the
# container can run Docker-in-Docker when started with --privileged.
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/debian/gpg \
       | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && printf 'deb [arch=%s signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian %s stable\n' \
       "$(dpkg --print-architecture)" \
       "$(. /etc/os-release && echo "$VERSION_CODENAME")" \
       > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y \
       docker-ce \
       docker-ce-cli \
       containerd.io \
       docker-buildx-plugin \
       docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/* \
    && usermod -aG docker dev

# ── Devcontainer scripts ──────────────────────────────────────────────────────
# Baked into the image at a stable path so per-repo hooks can reference them
# without knowing the workspace checkout location.
COPY .devcontainer/scripts/ /usr/local/lib/devcontainer/
RUN chmod +x /usr/local/lib/devcontainer/*.sh

ENV SSH_AUTH_SOCK=/ssh-agent

# Mark /workspaces as safe for all users — avoids git's dubious ownership
# error when the workspace is bind-mounted from the host. Set at system level
# so the per-user ~/.gitconfig bind-mount doesn't shadow it.
RUN git config --system safe.directory "*"

WORKDIR /workspaces
USER dev

# Pre-create bind-mount targets so Docker does not materialize root-owned
# placeholders at runtime.
RUN mkdir -p \
    /home/dev/.claude \
    /home/dev/.codex \
    /home/dev/.cursor

ARG GH_PAT
ENV GH_TOKEN=$GH_PAT

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
    npm install -g @openai/codex pnpm \
    --before="$(date -u -d '7 days ago' +%F)"
