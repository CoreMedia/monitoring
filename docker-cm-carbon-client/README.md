
CoreMedia carbon client
=======================

# short Description

Reads data from `redis`, normalized data. calculate some values and build compared data between services (Sequencenumbers between MLS and RLS) and push the result to the `carbon` Service.

This service runs every `INTERVAL` seconds and has no requirements to an message-queue.


# Environment Variables

| Environmental Variable             | Default Value        | Description                                                     |
| :--------------------------------- | :-------------       | :-----------                                                    |
| `REDIS_HOST`                       | `redis`              | redis Host                                                      |
| `REDIS_PORT`                       | `6379`               | redis Port                                                      |
| `GRAPHITE_HOST`                    | `carbon`             | carbon Host                                                     |
| `GRAPHITE_PORT`                    | `2003`               | carbon Port                                                     |
| `MYSQL_HOST`                       | `database`           | database Host                                                   |
| `DISCOVERY_DATABASE_NAME`          | `discovery`          | database schema name for the discovery service                  |
| `DISCOVERY_DATABASE_USER`          | `discovery`          | database user for the discovery service                         |
| `DISCOVERY_DATABASE_PASS`          | `discovery`          | database password for the discovery service                     |
| `INTERVAL`                         | `30`                 | run interval for the scheduler                                  |
| `RUN_DELAY`                        | `10`                 | delay for the first run                                         |

