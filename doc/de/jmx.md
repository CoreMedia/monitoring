# JMX Beans

## Beschreibung

Die Beschreibung der JMX Beans finden Sie in der Dokumentation (siehe entsprechende Links) oder mit dem CoreMedia Tool `jmxdump`.

### Beispiele

```bash
HOSTNAME=127.0.0.1

cm \
  jmxdump \
  --url service:jmx:rmi:///jndi/rmi://${HOSTNAME}:${PORT}/jmxrmi \
  -b com.coremedia:*type=Server* \
  -v
```

```bash
cm \
  jmxdump \
  --mbean 'com.coremedia:application=coremedia,type=Server#RepositorySequenceNumber' \
  --url service:jmx:rmi:///jndi/rmi://${HOSTNAME}:${PORT}/jmxrmi \
  com.coremedia:application=coremedia,type=Server
```

```bash
cm \
  jmxdump \
  --mbean 'com.coremedia:application=coremedia,type=Replicator' \
  --url service:jmx:rmi:///jndi/rmi://${HOSTNAME}:${PORT}/jmxrmi
```


Alle verwendeten JMX Beans werden in der Konfigurationsdatei `cm-application.yml` aufgeführt (siehe auch unter [Konfiguration](./konfiguration.md))



## Coremedia JMX Beans


| Type                           | CMS | MLS | RLS | WFS | CAE | Studio | Elastic-Worker | User-Changes | Content-Feeder | CAE-Feeder | Adobe-Drive |
| :----------------------------- | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| [CapConnection](./jmx/capconnection.md)                  |    |    |    | x  | x  | x | x | x |   |   | x |
| [Server](./jmx/content-servers.md#Server)                         | x  | x  | x  | x  |    |   |   |   |   |   |   |
| [Publisher](./jmx/content-servers.md#Publisher)                         | x |    |    |    |    |   |   |   |   |  |   |
| Store ([Connection-](./jmx/content-servers.md#ConnectionPool), [QueryPool](./jmx/content-servers.md#QueryPool)) | x  | x  | x  |    |    |   |   |   |   |   |   |
| Statistics                     | x  | x  | x  |    |    |   |   |   |   |   |   |
| WFS Statistics                 |    |    |    | x  |    |   |   |   |   |   |   |
| [Cache](./jmx/caches.md)                          |    |    |    |    | x  |   |   |   |   |   |   |
| [Replicator](./jmx/replication-live-server.md)                     |    |    | x  |    |    |   |   |   |   |   |   |
| [Feeder](./jmx/content-feeder.md)                         |    |    |    |    |    |   |   |   | x |   |   |
| [ContentDependencyInvalidator](./jmx/caefeeder.md#ContentDependencyInvalidator)   |    |    |    |    |    |   |   |   |   | x |   |
| [ProactiveEngine](./jmx/caefeeder.md#ProactiveEngine)                |    |    |    |    |    |   |   |   |   | x |   |
| [Health](./jmx/caefeeder.md#Health)                         |    |    |    |    |    |   |   |   |   | x |   |

<br>

- [Tomcats](./jmx/tomcat.md)
- [Solr](./jmx/solr.md)
- [CapConnection](./jmx/capconnection.md)
- [Caches](./jmx/caches.md)
- [Content Servers](./jmx/content-servers.md)
- [Replication Live Server](./jmx/replication-live-server.md)
- [Content Feeder](./jmx/content-feeder.md)
- [CAE Feeder](./jmx/caefeeder.md)
- [CAE](./jmx/cae.md)
- [Statistics](./jmx/statistics.md)
