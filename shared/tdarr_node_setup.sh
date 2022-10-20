#!/usr/bin/env bash

# shellcheck disable=SC2116
# shellcheck disable=SC2129

# TODO: Add logic to permanently shutdown server after 30 days via cron

read -r -p 'Samba server IP : ' smb_share_ip && \
read -r -p 'Samba username : ' smb_username && \
read -r -p 'Samba password : ' -s smb_password; echo '' && \
read -r -p 'Tdarr server IP : ' tdarr_share_ip && \
read -r -p 'Tailscale Auth key : ' -s tailscale_key; echo ''

apt-get update
apt-get upgrade -y -o Dpkg::Options::=--force-confdef
apt-get install apt-transport-https cifs-utils curl git handbrake handbrake-cli lsb-release vim unzip -y

pushd /srv/ || return

# Download & source dotfile
git clone https://github.com/steveharsant/dotfiles.git

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
tailscale up --authkey "$tailscale_key"

# Configure shares
cat <<EOF > /root/.sambalogin
username=$smb_username
password=$smb_password
EOF

mkdir /mnt/lun1
mkdir /mnt/lun2
mkdir /mnt/rd0

echo "//$smb_share_ip/lun1 /mnt/lun1 cifs credentials=/root/.sambalogin,vers=3.0 0 0" >> /etc/fstab
echo "//$smb_share_ip/lun2 /mnt/lun2 cifs credentials=/root/.sambalogin,vers=3.0 0 0" >> /etc/fstab
echo "//$smb_share_ip/rd0  /mnt/rd0  cifs credentials=/root/.sambalogin,vers=3.0 0 0" >> /etc/fstab

mount -a

# Install Tdarr Node
architecture=$(uname -m)
case "$architecture" in
  'aarch64')
    tdarr_package='https://f000.backblazeb2.com/file/tdarrs/versions/2.00.15/linux_arm64/Tdarr_Updater.zip'
    tdarr_platform_arch='linux_arm64_docker_false'
  ;;
  'x86_64')
    tdarr_package='https://f000.backblazeb2.com/file/tdarrs/versions/2.00.15/linux_x64/Tdarr_Updater.zip'
    tdarr_platform_arch='linux_x64_docker_false'
  ;;
  *)
    echo 'Unsuported architecture'
    exit 1
  ;;
esac

curl $tdarr_package -o /opt/tdarr.zip
unzip /opt/tdarr.zip -d /opt/
/opt/Tdarr_Updater

cat <<EOF > /opt/configs/Tdarr_Node_Config.json
{
  "nodeID": "$(hostname)",
  "serverIP": "$tdarr_share_ip",
  "serverPort": "8266",
  "handbrakePath": "",
  "ffmpegPath": "",
  "mkvpropeditPath": "",
  "pathTranslators": [
    {
      "server": "/lun1",
      "node": "/mnt/lun1"
    },
    {
      "server": "/lun2",
      "node": "/mnt/lun2"
    },
    {
      "server": "/hdd1",
      "node": "/mnt/rd0"
    }
  ],
  "platform_arch": "$tdarr_platform_arch",
  "logLevel": "INFO"
}
EOF

cat <<EOF > /etc/systemd/system/tdarr_node.service
[Unit]
Description=Tdarr node worker service
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/opt/Tdarr_Node/Tdarr_Node
Type=simple
User=root
Group=root
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl enable tdarr_node.service
systemctl start tdarr_node.service
systemctl status tdarr_node.service
