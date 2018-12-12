# CoreMedia dashing

A small and powerful dashboard system.


Docker Container based on [docker-dashing](https://github.com/bodsch/docker-dashing) with Icinga2 Integration

This Container use the [icinga2 gem](https://rubygems.org/gems/icinga2) and implements the
dashboard from the official [Icinga2 Dashing](https://github.com/Icinga/dashing-icinga2)

# Build

Your can use the included Makefile.

# supported environment variables

- `ICINGA_MASTER` (default: `icinga2`) - icinga2 Master
- `ICINGA_API_PORT` (default: `5665`) - icinga2 API Port
- `ICINGA_API_USER` (default: `admin`) - icinga2 API User
- `ICINGA_API_PASSWORD` (default: ``) - icinga2 API Password

- `ICINGA_CERT_SERVICE_BA_USER` (default: `admin`) - the basic auth user for the certificate service
- `ICINGA_CERT_SERVICE_BA_PASSWORD` (default: `admin`) - the basic auth password for the certificate service
- `ICINGA_CERT_SERVICE_API_USER` (default: ``) - the certificate service needs also an valid API users
- `ICINGA_CERT_SERVICE_API_PASSWORD` (default: ``)
- `ICINGA_CERT_SERVICE_SERVER` (default: ``) - certificate service Host
- `ICINGA_CERT_SERVICE_PORT` (default: `8080`) - certificate service Port
- `ICINGA_CERT_SERVICE_PATH` (default: `/`) - certificate service Path (needful, when they run behind a Proxy

- `ICINGAWEB_URL` (default: `http://localhost/icingaweb2`) - (not yet used)
