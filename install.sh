#!/usr/bin/env bash
set -e

PROFILE="$1"

if [[ -z "$PROFILE" ]]; then
  echo "Usage: ./install.sh [pc|server]"
  exit 1
fi

INSTALL_DIR="$(cd "$(dirname "$0")/install" && pwd)"

echo "▶ Using profile: $PROFILE"
echo "▶ Install directory: $INSTALL_DIR"

sudo apt update

install_apt_file() {
  local file="$1"
  if [[ -f "$INSTALL_DIR/$file" ]]; then
    echo "▶ Installing APT packages from $file"
    xargs -a "$INSTALL_DIR/$file" sudo apt install -y
  fi
}

install_snap_file() {
  local file="$1"
  if command -v snap >/dev/null && [[ -f "$INSTALL_DIR/$file" ]]; then
    echo "▶ Installing Snap packages from $file"
    while read -r pkg; do
      [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
      sudo snap install "$pkg"
    done < "$INSTALL_DIR/$file"
  fi
}

install_flatpak_file() {
  local file="$1"
  if command -v flatpak >/dev/null && [[ -f "$INSTALL_DIR/$file" ]]; then
    echo "▶ Installing Flatpak packages from $file"
    while read -r pkg; do
      [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
      flatpak install -y flathub "$pkg"
    done < "$INSTALL_DIR/$file"
  fi
}

PROFILE_FILE="$INSTALL_DIR/profile-$PROFILE.txt"

if [[ ! -f "$PROFILE_FILE" ]]; then
  echo "❌ Unknown profile: $PROFILE"
  exit 1
fi

while read -r section; do
  case "$section" in
    apt-core)
      install_apt_file "apt-core.txt"
      ;;
    apt-dev)
      install_apt_file "apt-dev.txt"
      ;;
    apt-optional)
      install_apt_file "apt-optional.txt"
      ;;
    snap)
      install_snap_file "snap.txt"
      ;;
    flatpak)
      install_flatpak_file "flatpak.txt"
      ;;
  esac
done < "$PROFILE_FILE"

echo "✅ Base installation complete."
echo "ℹ️  Review install/manual.md for remaining manual steps."

