#!/usr/bin/env bash

read -r -p 'Enter your GitHub email  : ' gh_email
read -r -p 'Enter your GitHub username  : ' gh_username
read -r -p 'Enter a GitHub access token : ' -s gh_token

apt-get update
apt upgrade -y -o Dpkg::Options::=--force-confdef
apt-get install ca-certificates curl git gnupg lsb-release jq unattended-upgrades screen -y

# Authenticate to Github
cat <<EOL >> ~/.netrc
machine github.com
login $gh_username
password $gh_token
EOL

# Set Github profile
git config --global user.email "$gh_email"
git config --global user.name  "$gh_username"

# Keys & Repos

## Tailscale
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.noarmor.gpg | \
  tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/jammy.tailscale-keyring.list | \
  tee /etc/apt/sources.list.d/tailscale.list

## Docker
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update and install packages
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin tailscale -y

# Install Docker Compose
tag=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r '.tag_name')
curl -sSL "https://github.com/docker/compose/releases/download/$tag/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Configure sshd & restart service
echo "
Include /etc/ssh/sshd_config.d/*.conf
Port 11989
SyslogFacility AUTH
LogLevel INFO
PermitRootLogin no
AllowUsers ubuntu
MaxAuthTries 3
MaxSessions 1
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication no
PermitEmptyPasswords no
ChallengeResponseAuthentication no
UsePAM yes
X11Forwarding no
PrintMotd no
ClientAliveInterval 600
ClientAliveCountMax 1
AcceptEnv LANG LC_*
Subsystem sftp /usr/lib/openssh/sftp-server
" > /etc/ssh/sshd_config

systemctl restart sshd
