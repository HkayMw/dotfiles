#!/usr/bin/env bash
set -euo pipefail

# ──────────────────────────────────────────────────────────────────────────────
#   install.sh — Provisions packages based on profile (pc | server)
#   Strict mode: requires profile-specific files — no fallback allowed
# ──────────────────────────────────────────────────────────────────────────────

if [[ $# -ne 1 ]]; then
    echo "Usage: ./install.sh pc|server"
    echo "       ./install.sh --help"
    exit 1
fi

PROFILE="$1"

if [[ "$PROFILE" == "--help" || "$PROFILE" == "-h" ]]; then
    cat << 'EOF'
Supported profiles:
  pc      → workstation / development machine
  server  → headless server environment

Profile files (in install/ directory):
  profile-pc.txt
  profile-server.txt

These files contain one section name per line, for example:
  apt-core
  apt-dev
  snap

Corresponding package lists (strict — profile suffix required):
  apt-core-pc.txt      / apt-core-server.txt
  apt-dev-pc.txt       / apt-dev-server.txt
  apt-optional-pc.txt  / apt-optional-server.txt
  snap-pc.txt          / snap-server.txt
  flatpak-pc.txt       / flatpak-server.txt     (currently unused)

If a required file is missing, the script will fail.
EOF
    exit 0
fi

if [[ "$PROFILE" != "pc" && "$PROFILE" != "server" ]]; then
    echo "Error: Unknown profile '$PROFILE'. Use 'pc' or 'server'."
    exit 1
fi

INSTALL_DIR="$(cd "$(dirname "$0")/install" && pwd)"
PROFILE_FILE="$INSTALL_DIR/profile-${PROFILE}.txt"

if [[ ! -f "$PROFILE_FILE" ]]; then
    echo "Error: Profile file not found: $PROFILE_FILE"
    exit 1
fi

# ──────────────────────────────────────────────────────────────────────────────
#   Helper functions
# ──────────────────────────────────────────────────────────────────────────────

get_required_file() {
    local base="$1"
    local file="${INSTALL_DIR}/${base}-${PROFILE}.txt"

    if [[ ! -f "$file" ]]; then
        echo "Error: Required file missing for profile '${PROFILE}': ${file}"
        echo "       Create it or remove section '${base}' from profile-${PROFILE}.txt"
        exit 1
    fi

    echo "$file"
}

install_apt_file() {
    local base="$1"
    local file
    file=$(get_required_file "$base")

    echo "▶ Installing APT packages from $(basename "$file")"
    # --no-install-recommends → leaner installs
    # -r on xargs → do not run if file is empty
    xargs -r -a "$file" sudo apt install -y --no-install-recommends
}

install_snap_file() {
    local base="$1"
    local file
    file=$(get_required_file "$base")

    if [[ ! -x "$(command -v snap)" ]]; then
        echo "Error: snap command not found, but section 'snap' is requested."
        exit 1
    fi

    echo "▶ Installing Snap packages from $(basename "$file")"
    while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue

        if snap list "${pkg%% *}" >/dev/null 2>&1; then
            echo "  ↳ ${pkg} already installed"
        else
            echo "  Installing ${pkg}"
            sudo snap install ${pkg}
        fi
    done < "$file"
}

install_flatpak_file() {
    local base="$1"
    local file
    file=$(get_required_file "$base")

    if [[ ! -x "$(command -v flatpak)" ]]; then
        echo "Error: flatpak command not found, but section 'flatpak' is requested."
        exit 1
    fi

    echo "▶ Installing Flatpak packages from $(basename "$file")"
    while IFS= read -r pkg; do
        [[ -z "$pkg" || "$pkg" =~ ^[[:space:]]*# ]] && continue

        if flatpak list --app | grep -q "^${pkg}[[:space:]]"; then
            echo "  ↳ ${pkg} already installed"
        else
            echo "  Installing ${pkg}"
            flatpak install -y flathub "${pkg}"
        fi
    done < "$file"
}

# ──────────────────────────────────────────────────────────────────────────────
#   Main logic
# ──────────────────────────────────────────────────────────────────────────────

echo "▶ Profile: ${PROFILE}"
echo "▶ Reading sections from: $(basename "$PROFILE_FILE")"
echo ""

sudo apt update -qq

while IFS= read -r section || [[ -n "$section" ]]; do
    # Skip empty lines and comments
    [[ -z "$section" || "$section" =~ ^[[:space:]]*# ]] && continue

    echo "→ Section: ${section}"

    case "$section" in
        apt-core)      install_apt_file    "apt-core"      ;;
        apt-dev)       install_apt_file    "apt-dev"       ;;
        apt-optional)  install_apt_file    "apt-optional"  ;;
        snap)          install_snap_file   "snap"          ;;
        flatpak)       install_flatpak_file "flatpak"      ;;
        *)
            echo "  ⚠  Unknown section '${section}' — skipping"
            ;;
    esac

    echo ""
done < "$PROFILE_FILE"

echo "──────────────────────────────────────────────"
echo "Base installation complete."
echo "Review install/manual.md for remaining manual steps."
echo "──────────────────────────────────────────────"