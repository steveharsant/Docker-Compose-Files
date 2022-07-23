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
* Watchtower

## Paths

* Docker container config paths are exposed at: `/srv/docker/<<container-name>>`
* The `/data` directory is the root for all user data. Required directory hireachy is:
  * `/data/downloads'
  * `/data/media'
    * `/data/media/movies'
    * `/data/media/tv'

## Preflight Configuration

* Duplicate each template file removing the `.tmpl` extension. Edit the duplicated files with the required environment variables before executing `docker-compose up -d`

* Edit the devices for the Scrutiny container to set the disk paths for your host.
