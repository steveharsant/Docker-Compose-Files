#!/usr/bin/env bash

# This script takes in 1 argument, the path to the directory to watch and ensures that the directory is available.
# If the directory is not available (based on timeout of the ls command on that directory), the script will restart
# the iSCSI daemon. This is to ensure that the directory is available at all times.

debug(){
  if [ "${ISCSI_WATCHER_DEBUG,,}" == "true" ]; then
    echo "$1"
  fi
}

# Script variables
directory="$1"; debug "Monitoring $directory"
pid=32768 # Dummy pid to start the loop
threshold=3; debug "Attempt threshould is $threshold"
retest_sleep=0.5; debug "Retest sleep is $retest_sleep"
success_sleep=10; debug "Success sleep is $success_sleep"

# Start #

while true; do
  debug "Checking if pid $pid exists"

  if ps -o pid= -p "$pid"; then
    debug 'pid exists'

    ((i++))
    debug "Thread counter incremented to: $i"

    debug "Sleeping for $retest_sleep seconds"
    sleep $retest_sleep

  else
    debug 'pid does not exist. Assuming directory is reachable. Resetting threshould counter'
    i=1

    debug "Sleeping for $success_sleep seconds"
    sleep $success_sleep

    debug "Testing directory $directory is accessible"
    ls "$directory" > /dev/null 2>&1 &

    pid=$!
    debug "Subprocess pid for test is $pid"
  fi

  if [ $i -gt $threshold ]; then
    debug 'Threshold reached'

    if kill -9 "$pid"
      then debug 'Successfully killed test subprocess'
      else debug 'Failed to kill test suprocess'
    fi

    echo 'iSCSI target location appears to be unreachable. Attempting to restart iSCSI daemon'
    if systemctl restart iscsid
      then debug 'Successfully restarted iSCSI daemon. Resetting threshould counter'; i=1
      else echo 'Failed to restart iSCSI daemon'
    fi
  fi
done
