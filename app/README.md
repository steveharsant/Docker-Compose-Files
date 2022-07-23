# Docker App Server

This Docker compose file is intended for an application/media server. Applications include:

* Deluge
* Emby
* Flaresolverr
* Jakett
* Ombi
* Nginx Proxy Manager (and dB)
* Radarr
* Scrutiny
* Sonarr
* Syncthing
* Tdarr
* Tdarr Node
* Watchtower

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
