
CoreMedia grafana client
========================

# short Description

The grafana client use the message queue service.

This service runs every `INTERVAL` seconds.


# Environment Variables

| Environmental Variable      | Default Value        | Description                                                     |
| :-------------------------- | :-------------       | :-----------                                                    |
| `GRAFANA_HOST`              | `grafana`            | grafana Host                                                    |
| `GRAFANA_PORT`              | `80`                 | grafana Port                                                    |
| `GRAFANA_URL_PATH`          | `/grafana`           | grafana URL Path                                                |
| `GRAFANA_API_USER`          | `admin`              | grafana API user                                                |
| `GRAFANA_API_PASSWORD`      | `admin`              | grafana API password                                            |
| `GRAFANA_VERSION`           | `4`                  | grafana version. we support Version 4 and 5.<br>**templates for both version are different** |
| `GRAFANA_TEMPLATE_PATH`     | `/usr/local/templates` | base directory for all grafana templates. for every major version exists an seperate sub directory. |
| `MQ_HOST`                   | `beanstalkd`         | beanstalkd (message queue) Host                                 |
| `MQ_PORT`                   | `11300`              | beanstalkd (message queue) Port                                 |
| `MQ_QUEUE`                  | `mq-grafana`         | beanstalkd (message queue) Queue                                |
| `REDIS_HOST`                | `redis`              | redis Host                                                      |
| `REDIS_PORT`                | `6379`               | redis Port                                                      |
| `MYSQL_HOST`                | `database`           | database Host                                                   |
| `DISCOVERY_DATABASE_NAME`   | `discovery`          | database schema name for the discovery service                  |
| `DISCOVERY_DATABASE_USER`   | `discovery`          | database user for the discovery service                         |
| `DISCOVERY_DATABASE_PASS`   | `discovery`          | database password for the discovery service                     |
| `INTERVAL`                  | `20s`                | run interval for the scheduler (minimum are `20s`)              |
| `RUN_DELAY`                 | `30s`                | delay for the first run                                         |
| `SERVER_CONFIG_FILE`        | `/etc/server_config.yml` | configure file for grafana |

For all Scheduler Variables, you can use simple integer values like `10`, this will be interpreted as `second`.

Other Values are also possible:

- `1h` for 1 hour
- `1w` for 1 week

Kombinations are also possible:

- `5m10s` for 5 minutes and 10 seconds
- `1h10s` for 1 hour and 20 minutes

# Templates

- `slug`<br>
   *Example:* dns FQDN or overwrite with configuration `display_name`<br>
   `slug` is the url friendly version of the dashboard title.<br>
   `.` are replaced with `-`

- `short_hostname`<br>
   dns shortname

- `normalized_name`<br>
   normalized servicename<br>
   example: `content-management-server` => `CMS` or `caefeeder-live` => `FEEDER_LIVE`

- `description`<br>
   service description taken from `cm-service.yaml`

- `graphite_identifier`<br>
   dns FQDN or overwrite with configuration `graphite_identifier`

- `mls_identifier`<br>
   the `graphite_identifier` for an *Master Live Server*

- `icinga_identifier`<br>
   same as `graphite_identifier`, but `_` insteed of `.`
