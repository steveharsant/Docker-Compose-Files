# Docker App Server

This Docker compose file is intended for an application/media server. Applications include:

* Deluge
* Emby
* Flaresolverr
* Jakett
* Ombi
* Netdata
* Nginx Proxy Manager (and dB)
* Radarr
* Scrutiny
* Sonarr
* Syncthing
* Tdarr (with internal node)
* Watchtower
* YouTube-DL Material (and dB)

## Paths

* Docker container config paths are exposed at: `/srv/docker/<<container-name>>`
* The `/data` directory is the root for all user data. Media is expected to be found at:
  * `/data/media'
    * `/data/media/movies'
    * `/data/media/tv'

> **Note:** *Other directories like `/data/downloads` that are not expected to have data in them when creating the containers will be created as needed.*

## Preflight Configuration

* Duplicate each template file removing the `.tmpl` extension. Edit the duplicated files with the required environment variables before executing `docker-compose up -d`

* Edit the devices for the Scrutiny container to set the disk paths for your host.

## Helper Scripts

### `iscsi_watcher.sh`

A small utility that takes one (positional) parameter of the directory where an iSCSI device is mounted and ensures its contents are reachable. If they are not, the script restarts the iSCSI daemon via `systemctl`.

A companion service file exists to run this script as a service. It is set to run as `root`. This is not recommended generally and should be changed to a user with only the scope to restart services. The path of the script it starts will likely need to be changed as well to point to the cloned location.

If sleep times or retry thresholds need to be changed, that can be done at the top of the script. (Not parameters as this likely  won't need changing.)

To enable debugging, set the environment variable `ISCSI_WATCHER_DEBUG` to `true`
