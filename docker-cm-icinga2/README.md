
# CoreMedia icinga2


## short Description

Based on [bodsch/docker-icinga2](https://hub.docker.com/r/bodsch/docker-icinga2/)

## Environment Variables

| Environmental Variable             | Default Value        | Description                                                     |
| :--------------------------------- | :-------------       | :-----------                                                    |
| `MYSQL_HOST`                       | -                    | MySQL Host                                                      |
| `MYSQL_PORT`                       | `3306`               | MySQL Port                                                      |
| `MYSQL_ROOT_USER`                  | `root`               | MySQL root User                                                 |
| `MYSQL_ROOT_PASS`                  | *randomly generated* | MySQL root password                                             |
| `IDO_DATABASE_NAME`                | `icinga2core`        | Schema Name for IDO                                             |
| `IDO_PASSWORD`                     | *randomly generated* | MySQL password for IDO                                          |
|                                    |                      |                                                                 |
| `CARBON_HOST`                      | -                    | hostname or IP address where Carbon/Graphite daemon is running  |
| `CARBON_PORT`                      | `2003`               | Carbon port for graphite                                        |
|                                    |                      |                                                                 |
| `ICINGA_CLUSTER`                   | `false`              | Icinga2 Cluster Mode - enable a Master / Satellite Setup        |
| `ICINGA_MASTER`                    | -                    | The Icinga2-Master FQDN for a Satellite Node                    |
|                                    |                      |                                                                 |
| `ICINGA_API_USERS`                 | -                    | comma separated List to create API Users. The Format are `username:password` |
|                                    |                      | (e.g. `admin:admin,dashing:dashing` and so on)                  |
|                                    |                      |                                                                 |
| `ICINGA_CERT_SERVICE`              | `false`              | enable the Icinga2 Certificate Service                          |
| `ICINGA_CERT_SERVICE_BA_USER`      | `admin`              | The Basic Auth User for the certicate Service                   |
| `ICINGA_CERT_SERVICE_BA_PASSWORD`  | `admin`              | The Basic Auth Password for the certicate Service               |
| `ICINGA_CERT_SERVICE_API_USER`     | -                    | The Certificate Service needs also an API Users                 |
| `ICINGA_CERT_SERVICE_API_PASSWORD` | -                    |                                                                 |
| `ICINGA_CERT_SERVICE_SERVER`       | `localhost`          | Certificate Service Host                                        |
| `ICINGA_CERT_SERVICE_PORT`         | `80`                 | Certificate Service Port                                        |
| `ICINGA_CERT_SERVICE_PATH`         | `/`                  | Certificate Service Path (needful, when they run begind a Proxy |
|                                    |                      |                                                                 |
| `ICINGA_SSMTP_RELAY_SERVER`        | -                    | SMTP Service to send Notifications                              |
| `ICINGA_SSMTP_REWRITE_DOMAIN`      | -                    |                                                                 |
| `ICINGA_SSMTP_RELAY_USE_STARTTLS`  | -                    |                                                                 |
| `ICINGA_SSMTP_SENDER_EMAIL`        | -                    |                                                                 |
| `ICINGA_SSMTP_SMTPAUTH_USER`       | -                    |                                                                 |
| `ICINGA_SSMTP_SMTPAUTH_PASS`       | -                    |                                                                 |
| `ICINGA_SSMTP_ALIASES`             | -                    |                                                                 |
|                                    |                      |                                                                 |
