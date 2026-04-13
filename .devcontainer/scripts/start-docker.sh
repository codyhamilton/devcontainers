#!/usr/bin/env bash
# Starts the Docker daemon inside the container if it is not already running.
# Requires the container to have been started with --privileged.
set -euo pipefail

if docker info &>/dev/null 2>&1; then
    exit 0
fi

sudo dockerd \
    --host=unix:///var/run/docker.sock \
    --log-level=error \
    &>/tmp/dockerd.log &

# Wait up to 20 seconds for dockerd to be ready
timeout 20 bash -c 'until docker info &>/dev/null 2>&1; do sleep 0.5; done' \
    || { echo "dockerd failed to start — check /tmp/dockerd.log"; exit 1; }
