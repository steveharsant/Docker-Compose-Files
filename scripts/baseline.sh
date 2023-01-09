#!/usr/bin/env bash

apt update
apt upgrade -y

apt-get install \
  apt-transport-https cifs-utils curl git gnupg2 \
  htop lsb-release iotop jq ncdu screen unzip vim zip -y

pushd /srv/ || return

# Download repositories
git clone https://github.com/steveharsant/dotfiles.git
git clone github.com/steveharsant/local-Infrastructure.git

# Install dotfiles
cat <<EOF >> /root/.bashrc
# Source personal customisations from github.com/steveharsant/dotfiles
dotfiles_path='/srv/dotfiles'
dotfiles=( \$( ls \$dotfiles_path -a | grep bash ) )
for dotfile in "\${dotfiles[@]}"; do
  source "\$dotfiles_path/\$dotfile"
done
EOF

# Install Tailscale
distro=$(lsb_release -is); distro=${distro,,}
codename=$(lsb_release -cs)

case "$distro" in
  'debian')
    curl -fsSL "https://pkgs.tailscale.com/stable/$distro/$codename.gpg" | apt-key add -
    curl -fsSL "https://pkgs.tailscale.com/stable/$distro/$codename.list" | tee /etc/apt/sources.list.d/tailscale.list
  ;;

  'ubuntu')
    curl -fsSL "https://pkgs.tailscale.com/stable/$distro/$codename.noarmor.gpg" | tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL "https://pkgs.tailscale.com/stable/$distro/$codename.tailscale-keyring.list" | tee /etc/apt/sources.list.d/tailscale.list
  ;;

  *)
    echo 'Unsuported distribution'
    exit 1
  ;;
esac

apt-get update -o Dir::Etc::sourcelist="sources.list.d/tailscale.list" \
  -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"

apt-get install tailscale -y
