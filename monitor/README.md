# Monitoring Server

This server is intended to run an Grafana, Influx dB, and Uptime Kuma to monitor the health and status of other servers.

## Containers

* Grafana
* Influx dB
* Netdata
* Uptime Kuma

## Preflight Configuration

* Duplicate the `.env.tmpl` file removing the `.tmpl` extension. Edit the duplicated files with the required environment variables before executing `docker-compose up -d`
