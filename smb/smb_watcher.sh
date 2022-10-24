#!/usr/bin/env bash

# shellcheck disable=SC2012
# shellcheck disable=SC2086

# This script takes in 6 arguments, the path to watch, services to restart,
# the docker containers to restart, if the host is an smb server (optional),
# how long to sleep between tests (optional), and the failure threshold (optional).
#
# If the host is an smb server, the script will monitor smbd & greyhole services.
# If either services are inactive, they will be attempted to be brought back online.
# The script will then remount entries in /etc/fstab, and retest.
#
# If the host is not an smb server, and the given path is empty it is assumed
# that the mount has dropped and will be remounted. If the path remains empty,
# the script will keep attempting a remount. Once successful, the script will
# restart any docker containers and services mentioned.

echo 'smb watcher started'
echo 'Sourcing /etc/environment'; source /etc/environment
echo 'For logging information set the SMB_WATCHER_DEBUG environment variable to true'


# Functions #
debug(){
  if [ "${SMB_WATCHER_DEBUG,,}" == "true" ]; then
    echo "$1"
  fi
}

send_status_alert(){
  case "$1" in
    down) title="❌ smb share is down for $HOSTNAME" ;;
    up)   title="✔️ smb share is up for $HOSTNAME" ;;
  esac

  if [[ -n $PUSHBULLET_API_KEY ]]; then
    curl --silent -u """$PUSHBULLET_API_KEY"":" \
      -d type="note" -d title="$title" \
      -d body="$(date)\nDirectory: $path\nHost: $HOSTNAME\nMode: $mode"\
       'https://api.pushbullet.com/v2/pushes'
  else
    debug 'PUSHBULLET_API_KEY not set. Alert cannot be sent'
  fi
}

test_path(){
  if [ "$(ls -A "$path" | wc -l)" -gt 0 ]
    then return 0;
    else return 1;
  fi
}

test_service(){
  if ! systemctl is-active --quiet $1; then
    debug "$1 is not active, attempting restart"
    systemctl restart --quiet $1
  fi
}


# Arguments #
while getopts "c:f:m:p:s:t:" OPT; do
  case "$OPT" in
    c) containers="$OPTARG";;
    f) failure_threshold="${OPTARG:=3}";;
    m) mode="${OPTARG:=client}";;
    p) path="$OPTARG";;
    s) services="$OPTARG";;
    t) sleep_time="${OPTARG:=10}";;
    *) printf "Invalid argument passed -$OPT. Ignoring\n";;
  esac
done


# Debug information #
echo "containers argument is: $containers"
echo "failure_threshold argument is: $failure_threshold"
echo "mode argument is: $mode"
echo "path argument is: $path"
echo "services argument is: $services"
echo "sleep_time argument is: $sleep_time"
echo "Found $(grep 'cifs' /etc/fstab -c) smb/cifs mounts found in /etc/fstab"

n=0

# Start #
case "$mode" in

  'client')
    debug "Determined host is not an smb server. Running in 'client mode'"

    while true; do
      if test_path; then
        debug 'Directory is mounted and accessible.'
        if [ "$n" -ge "$failure_threshold" ]; then send_status_alert up; fi
        n=0

      else
        debug 'Directory appears empty, attempting remount'
        mount -a
        ((n++))

        if test_path; then
          debug 'Directory is back online. Restarting services and containers'
          if [[ -n "$services" ]]; then systemctl restart $services; fi
          if [[ -n "$containers" ]]; then docker container restart $services; fi
          n=0

        else debug 'Failed to remount directory. Will attempt again after sleep'
        fi
      fi

      if [ $n -eq $failure_threshold ]; then send_status_alert down; fi
      debug "Sleeping for $sleep_time seconds"
      sleep $sleep_time
    done
  ;;

  'server')
    debug "Determined host is an smb server. Running in 'server mode'"

    while true; do
      test_service smbd.service
      test_service greyhole.service

      if test_path; then
        debug 'Directory is mounted and accessible.'
        if [ $n -ge $failure_threshold ]; then send_status_alert up; fi
        n=0

      else
        systemctl restart smbd.service greyhole.service
        mount -a
        if ! test_path; then
          debug 'Failed to remount directory. Will attempt again after sleep';
          ((n++))
        fi
      fi

      if [ $n -eq $failure_threshold ]; then send_status_alert down; fi
      debug "Sleeping for $sleep_time seconds"
      sleep $sleep_time
    done
  ;;
esac
