#!/usr/bin/env bash
set -euo pipefail

# install-server.sh — Provisions packages for server profile

INSTALL_DIR="$(cd "$(dirname "$0")/install" && pwd)"

# Only one file required for server (minimal & strict)
REQUIRED_FILE="${INSTALL_DIR}/apt-core-server.txt"

echo "▶ Starting server installation"
echo "▶ Using file: ${REQUIRED_FILE}"
echo ""

if [[ ! -f "${REQUIRED_FILE}" ]]; then
    echo "Error: Missing required file: ${REQUIRED_FILE}"
    echo "       Please create it before continuing."
    exit 1
fi

sudo apt update -qq

echo "→ Server core packages (apt-core-server.txt)"
xargs -r -a "${REQUIRED_FILE}" sudo apt install -y --no-install-recommends
echo ""

echo "──────────────────────────────────────────────"
echo "Server installation complete."
echo "Review install/manual.md for remaining manual steps."
echo "──────────────────────────────────────────────"