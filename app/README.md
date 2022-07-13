# Docker App Server

This Docker compose file is intended for an application/media server. Applications include:

* Bazarr
* Deluge
* Emby
* Jakett
* Ombi
* Nginx Proxy Manager
* Radarr
* Sonarr
* Syncthing
* Watchtower
* Windscribe Proxy

## Paths

* Docker container config paths are exposed at: `/srv/docker/<<container-name>>`
* The `/data` directory is the root for all user data. Required directory hireachy is:
  * `/data/downloads'
  * `/data/media'
    * `/data/media/movies'
    * `/data/media/tv'

## Preflight Configuration

Duplicate each template file removing the `.tmpl` extension. Edit the duplicated files with the required environment variables before executing `docker-compose up`
