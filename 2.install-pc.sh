#!/usr/bin/env bash
set -euo pipefail

# install-pc.sh — Provisions packages for PC / workstation

INSTALL_DIR="$(cd "$(dirname "$0")/install" && pwd)"

# All required files for PC profile
REQUIRED_FILES=(
    "${INSTALL_DIR}/apt-core.txt"
    "${INSTALL_DIR}/apt-dev.txt"
    "${INSTALL_DIR}/apt-optional.txt"
    "${INSTALL_DIR}/snap.txt"
)

echo "▶ Starting PC installation"
echo "▶ Using files from: ${INSTALL_DIR}"
echo ""

# Pre-check: all files must exist
for file in "${REQUIRED_FILES[@]}"; do
    if [[ ! -f "$file" ]]; then
        echo "Error: Missing required file: ${file}"
        echo "       Please create it before continuing."
        exit 1
    fi
done

sudo apt update -qq

# Install in logical order
echo "→ Core system utilities (apt-core.txt)"
xargs -r -a "${INSTALL_DIR}/apt-core.txt" sudo apt install -y --no-install-recommends
echo ""

echo "→ Development tools (apt-dev.txt)"
xargs -r -a "${INSTALL_DIR}/apt-dev.txt" sudo apt install -y --no-install-recommends
echo ""

echo "→ Optional / convenience tools (apt-optional.txt)"
xargs -r -a "${INSTALL_DIR}/apt-optional.txt" sudo apt install -y --no-install-recommends
echo ""

echo "→ Snap-packaged GUI applications (snap.txt)"
while IFS= read -r pkg; do
    [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue
    if command -v snap >/dev/null && snap list "${pkg%% *}" >/dev/null 2>&1; then
        echo "  ↳ ${pkg} already installed"
    else
        echo "  Installing ${pkg}"
        sudo snap install ${pkg}
    fi
done < "${INSTALL_DIR}/snap.txt"
echo ""

echo "──────────────────────────────────────────────"
echo "PC installation complete."
echo "Review install/manual.md for remaining manual steps."
echo "──────────────────────────────────────────────"