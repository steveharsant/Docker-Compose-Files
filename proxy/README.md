# Reverse Proxy Server

This server is intended to run an nginx reverse proxy to proxy requests through Tailscales SDN to the App server running variable media containers.

## Containers

* Netdata
* Nginx Proxy Manager (and dB)
* Watch Tower

## Preflight Configuration

* Duplicate the `.env.tmpl` file removing the `.tmpl` extension. Edit the duplicated files with the required environment variables before executing `docker-compose up -d`
