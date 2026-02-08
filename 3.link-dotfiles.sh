#!/usr/bin/env bash
set -euo pipefail

# link-dotfiles.sh — Creates symlinks from ~/dotfiles to $HOME

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
HOME_DIR="$HOME"

# List of files/directories to symlink (add more as needed)
# Format: "source_path target_path_relative_to_home"
# If target_path is empty, uses same name as source (with dot prefix if needed)

declare -A LINKS=(
    ["bash/bashrc"]=".bashrc"
    ["bash/profile"]=".profile"
    ["git/gitconfig"]=".gitconfig"
    # Add more entries here, e.g.:
    # ["tmux/tmux.conf"]=".tmux.conf"
    # ["config/nvim"]="config/nvim"           # directories work too
    # ["ssh/config"]=".ssh/config"
)

echo "▶ Linking dotfiles from ${DOTFILES_DIR} to ${HOME_DIR}"
echo ""

for src_rel in "${!LINKS[@]}"; do
    src="${DOTFILES_DIR}/${src_rel}"
    tgt_rel="${LINKS[$src_rel]}"

    # If no explicit target given, derive it (e.g. bashrc → .bashrc)
    if [[ -z "$tgt_rel" ]]; then
        tgt_rel=".${src_rel##*/}"
    fi

    tgt="${HOME_DIR}/${tgt_rel}"

    # Create parent directories if needed (e.g. for .ssh/config)
    mkdir -p "$(dirname "$tgt")"

    if [[ -L "$tgt" ]]; then
        # Already a symlink — check if it points to the right place
        if [[ "$(readlink "$tgt")" == "$src" ]]; then
            echo "  ↳ ${tgt_rel} already linked correctly"
            continue
        else
            echo "  Removing stale symlink: ${tgt_rel}"
            rm "$tgt"
        fi
    elif [[ -e "$tgt" ]]; then
        echo "  Warning: ${tgt_rel} exists and is not a symlink."
        echo "           Backing up to ${tgt}.backup"
        mv "$tgt" "${tgt}.backup"
    fi

    echo "  Creating symlink: ${tgt_rel} → ${src_rel}"
    ln -s "$src" "$tgt"
done

echo ""
echo "──────────────────────────────────────────────"
echo "Dotfiles linking complete."
echo "You may need to source ~/.bashrc or restart your shell."
echo "Review any backup files (*.backup) if created."
echo "──────────────────────────────────────────────"