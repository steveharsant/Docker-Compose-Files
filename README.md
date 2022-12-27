# Local Infrastructure

Docker compose files (and some helper scripts) for managing my homelab.

## Quick Run

Run the below command to pull the latest changes and apply them for both the host specific and shared compose files.

`cd /srv/Local-Infrastructure/ && git pull && cd $(hostname) && docker-compose up -d --remove-orphans && cd ../shared/ && docker-compose up -d`
