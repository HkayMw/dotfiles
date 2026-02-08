#!/usr/bin/env bash
set -euo pipefail

# stow.sh — Automates Stow for your dotfiles packages

DOTFILES_DIR="$$   (cd "   $$(dirname "$0")" && pwd)"
cd "$DOTFILES_DIR" || exit 1

# List of packages (directories) to manage
PACKAGES=("bash" "git")
# Add more when needed: "tmux" "ssh" "nvim" etc.

echo "▶ Managing dotfiles with GNU Stow"
echo "▶ Repository: ${DOTFILES_DIR}"
echo "▶ Target: $HOME"
echo ""

# Optional: dry-run first (uncomment to test)
# STOW_CMD="stow --no --verbose"
STOW_CMD="stow --verbose"

for pkg in "${PACKAGES[@]}"; do
    if [[ ! -d "$pkg" ]]; then
        echo "Error: Package directory '${pkg}' not found"
        exit 1
    fi

    echo "→ Stowing package: ${pkg}"
    if $STOW_CMD "$pkg"; then
        echo "  Success"
    else
        echo "  Conflicts detected — review output above"
        echo "  Run 'stow --no $pkg' for dry-run or resolve manually"
    fi
    echo ""
done

echo "──────────────────────────────────────────────"
echo "Stow complete. Source your shell (e.g., source ~/.bashrc) if needed."
echo "To update: git pull && ./stow.sh"
echo "To remove a package: stow -D <package>"
echo "──────────────────────────────────────────────"