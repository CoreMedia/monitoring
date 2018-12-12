
CoreMedia Monitoring REST
========================

# short Description

The monitoring REST API is the user entry point.

For more Information, please read the [API Doku](https://github.com/cm-xlabs/monitoring/blob/doc/de/api.md)!


# Environment Variables

| Environmental Variable             | Default Value        | Description                                                     |
| :--------------------------------- | :-------------       | :-----------                                                    |
| `REST_SERVICE_PORT`                | `8080`               | REST Service Port                                               |
| `REST_SERVICE_BIND`                | `0.0.0.0`            | REST Service bind-address                                       |
| `MQ_HOST`                          | `beanstalkd`         | beanstalkd (message queue) Host                                 |
| `MQ_PORT`                          | `11300`              | beanstalkd (message queue) Port                                 |
| `MQ_QUEUE`                         | `mq-rest-service`    | beanstalkd (message queue) Queue                                |
| `REDIS_HOST`                       | `redis`              | redis Host                                                      |
| `REDIS_PORT`                       | `6379`               | redis Port                                                      |
| `MYSQL_HOST`                       | `database`           | database Host                                                   |
| `DISCOVERY_DATABASE_NAME`          | `discovery`          | database schema name for the discovery service                  |
| `DISCOVERY_DATABASE_USER`          | `discovery`          | database user for the discovery service                         |
| `DISCOVERY_DATABASE_PASS`          | `discovery`          | database password for the discovery service                     |

* **`create`**

```bash
HOSTNAME=blueprintbox.local

curl \
  --silent \
  --request POST \
  --data '{ "command": "create" }' \
  http://localhost/api/v2/annotation/${HOSTNAME} | \
  json_reformat
```

* **`destroy`**

```bash
HOSTNAME=blueprintbox.local

curl \
  --silent \
  --request POST \
  --data '{ "command": "destroy" }' \
  http://localhost/api/v2/annotation/${HOSTNAME} | \
  json_reformat
```

* **`loadtest`**

```bash
HOSTNAME=blueprintbox.local

curl \
  --silent \
  --request POST \
  --data '{ "command": "loadtest", "argument": "start" }' \
  http://localhost/api/v2/annotation/${HOSTNAME} | \
  json_reformat


curl \
  --silent \
  --request POST \
  --data '{ "command": "loadtest", "argument": "stop" }' \
  http://localhost/api/v2/annotation/${HOSTNAME} | \
  json_reformat
```

* **`deployment`**

```bash
HOSTNAME=blueprintbox.local

curl \
  --silent \
  --request POST \
  --data '{ "command": "deployment", "message": "version 7.1.50", "tags": ["7.1.50"] }' \
  http://localhost/api/v2/annotation/${HOSTNAME} | \
  json_reformat
```
