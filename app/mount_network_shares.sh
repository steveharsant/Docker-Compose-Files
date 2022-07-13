#!/usr/bin/env bash

# This is one potential implementation for mounting cifs shares at boot.
# This implementation has been designed for a niche configuration which
# uses multiple iSCSI targets, and Greyhole (which distributes data at
# the object level, then exposes the unified object tree via samba).
#
# Traditionally the /etc/fstab file is used, however the mount is attempted
# too early in the boot process before the luns are known and mounted.
# The rc.local file could be used to mount these samba shares at boot, but
# this way the logic can be checked into git, and be more easily modified.
#
# This script can be added to /etc/crontab with a line like:
# @reboot root /path/to/mount_network_shares.sh

log(){
  echo "$(date --rfc-3339=s) $*" >> /var/log/mount_network_shares.log
}

log 'Starting...'

# Wait for iSCSI targets to come online.
while [ "$(iscsiadm -m session 2>&1)" == 'iscsiadm: No active sessions.' ]; do
  sleep 3
done

log 'iSCSI targets online'

if source /etc/environment
  then log '/etc/environment sourced'
  else log 'Failed to source /etc/environment'
fi

if mkdir "$SAMBA_MOUNT_POINT" &>/dev/null
  then log 'Created mount point'
  else log 'Mount point already exists'
fi

log 'attempting to mount shares'

if mount -t cifs -o username="$SAMBA_USERNAME",password="$SAMBA_PASSWORD",vers=3.0 \
    "$SAMBA_SHARE" "$SAMBA_MOUNT_POINT"
  then log 'Mounted shares'
  else log 'Failed to mount shares'
fi

log 'Mounts complete'
