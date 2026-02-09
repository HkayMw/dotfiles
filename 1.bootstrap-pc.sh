#!/usr/bin/env bash
set -euo pipefail

# bootstrap-pc.sh — Workstation bootstrap (Ubuntu 24.04 Desktop)
# Run as normal user after fresh install

echo "=== PC Bootstrap started ($(date)) ==="

# 1. Update and upgrade base system
echo "→ Updating and upgrading system"
sudo apt update && sudo apt full-upgrade -y
sudo apt autoremove -y

# 2. Set timezone
echo "→ Setting timezone to Africa/Blantyre"
sudo timedatectl set-timezone Africa/Blantyre

# 3. Enable SSH (useful for remote access or Ansible later)
echo "→ Configuring SSH (socket activation)"
sudo apt install -y openssh-server
sudo systemctl enable --now ssh.socket 2>/dev/null || sudo systemctl enable --now ssh

# 4. Install Docker via official repository (recommended method)
echo "→ Installing Docker (official repository)"
sudo apt install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo usermod -aG docker "$USER"

# 5. Basic firewall (allow SSH only; desktop users often leave ufw disabled)
echo "→ Installing and configuring ufw"
sudo apt install -y ufw
sudo ufw allow OpenSSH
sudo ufw --force enable

# 6. Optional: enable automatic security updates (recommended for desktops)
echo "→ Enabling unattended-upgrades"
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure --frontend=noninteractive unattended-upgrades

echo "=== PC Bootstrap complete ==="
echo "Next steps:"
echo "  1. Log out and log back in (for Docker group membership)"
echo "  2. Run: chmod +x 2.install-pc.sh && ./2.install-pc.sh"
echo "  3. Run: chmod +x 3.stow.sh && ./3.stow.sh"
echo ""
echo "Recommended reboot after first run."