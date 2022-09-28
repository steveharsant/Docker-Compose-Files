#!/usr/bin/with-contenv bash

# shellcheck shell=bash

# Ensures cifs-utils is installed and mounts a samba share to
# a directory with the same name to root. It is expected that
# this file is in the containers /config/custom-services.d/ path.

if [ ! -f '/smb_initalised' ]; then
  apt update && apt install cifs-utils -y
  mkdir /media
  echo "//$SMB_HOSTNAME/$SMB_SHARENAME /$SMB_SHARENAME cifs user=$SMB_USERNAME,password=$SMB_PASSWORD,uid=1000,gid=1000,vers=2.0  0  0" \
    >> /etc/fstab
  touch '/smb_initalised'
fi

mount -a
