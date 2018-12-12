Konfiguration
=============

Alle Konfigurationsdateien sind im YAML Stil ausgeführt.

Diese befinden sich in einem speziellen Daten Container um einen einheitlichen Speicherort zu gewährleisten.

```bash
cd ~/cm-monitoring-toolbox/monitoring/docker-cm-data/rootfs/data/etc/
```

 - `cm-application.yaml`
 - `cm-monitoring.yaml`
 - `cm-service.yaml`
 - `grafana_config.yaml`
 - `cm-icinga2.yaml`


## Dateien

### *`cm-service.yaml`*

Beinhaltet alle bekannten und zu monitorenden Services.

Alle Services werden als Liste ausgeführt und haben folgenden Aufbau:

```
  cae-live-1:
    description: CAE Live
    port: 42199
    cap_connection: true
    uapi_cache: true
    blob_cache: true
    content_repository: true
    application:
    - cae
    - caches
    - caches-ibm
    template: cae
```

| Paramerter       | Beschreibung |
| :---------       | :----------- |
| `cae-live-1`     | Servicename, der durch das Service Discovery ermittelt wird. Der Servicename wird ausserdem benutzt um ein Grafana Dashboard anzulegen. |
| `description`    | Einfache Beschreibung des Services |
| `port`           | der RMI Port, unter denen die JMX-Anfragen gestellt werden.<br>**ACHTUNG** Der Port wird durch das Service Discovery gesetzt! |
| `port_http`      | sollte der Server eine *IOR* oder einen *HTTP* Port anbieten, wird dieser hier angegeben.<br>**ACHTUNG** Der Port wird durch das Service Discovery gesetzt! |
| `cap-connection` | wird auf `true` gesetzt, wenn dieser Service eine *Cap-Connection* besitzt |
| `uapi_cache`     | wird auf `true` gesetzt, wenn dieser Service ein *UAPI Cache* besitzt |
| `blob_cache`     | wird auf `true` gesetzt, wenn dieser Service ein *Blob Cache* besitzt |
| `ior`            | wird auf `true` gesetzt, wenn dieser Service eine *IOR* besitzt |
| `runlevel`       | wird auf `true` gesetzt, wenn dieser Service ein *Runlevel* besitzt (alle Contentserver) |
| `license`        | wird auf `true` gesetzt, wenn dieser Service eine *Lizenz* benötigt (alle Contentserver) |
| `workflow_repository` | wird auf `true` gesetzt, wenn dieser Service ein Workflow Repository nutzt. |
| `content_repository` | wird auf `true` gesetzt, wenn dieser Service ein Content Repository nutzt. |
| `application`    | Eine Liste mit *application beans*.<br>Diese Liste wird nach dem Service Discovery mit Daten aus `cm-application.yaml` zusammengeführt. |
| `template`       | Sollte eine Applikation gefunden werden, die vom Standard CoreMedia Namensschema abweicht, kann hier ein alternatives Template angegeben werden. |

Die Paramerter `port_http`, `cap-connection`, `uapi_cache`, `blob_cache`, `ior`, `runlevel` und `license` werden zusätzlich für **Icinga** Checks benötigt.


Der Service `solr-master` (bzw. `solr-slave`) besitzt zudem eine zusätzliche Angabe für die zu überwachenden Cores:

```
  solr-master:
    description: Solr Master
    port: 40099
    cores:
    - live
    - preview
    - studio
    application:
    - solr

  solr-slave:
    description: Solr Slave
    port: 40099
    cores:
    - live
    - preview
    - studio
    application:
    - solr
```

**Die Solr-Cores können beliebig erweitert werden.**

Im Beispiel wurden nur die Standardcores angegeben.


### *`cm-application.yaml`*

Beinhaltet aktuell alle bekannten und sinnvollen JMX beans sowie deren Attribute für die CoreMedia Services.
Diese werden mit denen duch die Service Discovery erkannten Services zusammengeführt und für das weitere Monitoring benutzt.

Der Aufbau ist einfach gehalten und entspricht folgenden Schema:

```
    tomcat:
      description: standard checks for all tomcats
      metrics:
      - description: Heap Memory Usage
        mbean: java.lang:type=Memory
      - description: Thread Count
        mbean: java.lang:type=Threading
        attribute: TotalStartedThreadCount,ThreadCount,DaemonThreadCount,PeakThreadCount
```

| Paramerter       | Beschreibung |
| :---------       | :----------- |
| `tomcat`         | Der Service Name |
| `description`    | Eine kurze Beschreibung des Service Names |
| `metrics`        | ein Array mit Metriken |
| `description`    | Eine kurze Beschreibung des folgenen mbeans |
| `mbean`          | der komplette mbean Name |
| `attribute`      | Eine Liste mit mbean Attributen. Sollte `attribute` nicht angegeben sein, werden alle ausgelesen  |


Es können wir eigene Gruppierungen von mbeans Vorgenommen werden. Diese können dann in der `cm-service.yml` unter `application` angegeben werden.


Während der Service `tomcat` mit allen (Java) Services explizit zusammen geführt wird, werden nur die konfigurierten Services,
welche unter `application` in der `cm-service.yml` angegeben wurden zusammen geführt.

Beispiel:
```bash
  studio:
    description: Studio
    port: 41099
    cap_connection: true
    uapi_cache: true
    blob_cache: true
    heap_cache: true
    application:
    - caches-studio
    - caches-ecommerce
```

Eine spezielle Besonderheit gibt es bei den `solr` Services.
```bash
    solr:
      description: Solr Standard Checks for Core %CORE%
      metrics:
      - mbean: solr/%CORE%:type=/replication,id=org.apache.solr.handler.ReplicationHandler
        attribute: errors,isMaster,isSlave,requests,medianRequestTime,indexVersion,indexSize,generation
```

Die Variable `%CORE%` wird mir den Cores aus `cm-service.yml` erweitert.


### *`grafana_config.yml`*

Über diese Konfigurationsdatei wird Grafana über dessen API konfiguriert.

Das betrift das anlegen von lokalen Benutzern bzw. von Datasources. Ebenso kann hier über der Organisation
oder die Zugangsdaten des Admin-Users geändert werden.

Desweiteren kann man darüber statische Dashboards importieren lassen.


### *`icinga_server_config.yml`*

Über diese Konfiguration kann z.Z. ausschließlich `contact-groups` und `contact-users` angelegt werden.
