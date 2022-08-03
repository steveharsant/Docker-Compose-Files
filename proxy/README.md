# Reverse Proxy Server

This server is intended to run an nginx reverse proxy to proxy requests through Tailscales SDN to the App server running variable media containers.

## Containers

* Nginx Proxy Manager (and dB)
* Watch Tower

## Preflight Configuration

* Duplicate the template file for the Nginx Proxy Manager whilst removing the `.tmpl` extension, and set a password.
