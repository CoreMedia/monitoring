#### Blueprint-Box / Hinzufügen eines einzelnen Services (content-management-server)

Um einen eizelnen Service in das Monitoring auzunehmen, muß man nur den Portbereich eingrenzen, der durch die ServiceDiscovery abgefragt wird.

```bash
$ curl --request POST http://localhost/api/v2/host/blueprint-box --data '{"config":{"ports": [40199]}}'
{
  "blueprint-box": {
    "request": {
      "config": {
        "ports": [
          40199
        ]
      }
    }
  },
  "status": 200,
  "message": "the message queue is informed ..."
}
```
Ein kurzer Blick in das REST-Interface zeigt uns, dass auch nur der Content Server ins Monitoring aufgenommen wurde:

```bash
$ curl --request GET http://localhost/api/v2/host/blueprint-box
{
  "blueprint-box": {
    "dns": {
      "ip": "192.168.252.100",
      "short": "blueprint-box",
      "fqdn": "blueprint-box"
    },
    "status": {
      "created": "2017-09-28 10:35:45 +0000",
      "status": "online"
    },
    "custom_config": {
      "ports": [
        40199
      ]
    },
    "services": {
      "content-management-server": {
        "port": 40199,
        "description": "ContentServer CMS",
        "port_http": 40180,
        "ior": true,
        "runlevel": true,
        "license": true,
        "heap_cache": true
      }
    }
  },
  "status": 200
}
```

#### Blueprint-Box / Erweiterung der Service Discovery um den Replication Live Server

Wenn man in einer Continous Integration arbeitet, kann es vorkommen, dass man einen Host möglichst frühzeitig in das Monitoring integrieren möchte.
Zum Start des Hosts stehen aber entweder noch nicht alle Services zur Verfügung - z.B. aufgrund längerer Startzeiten - oder aber das Deployment ist zu dem Zeitpunkt noch gar nicht gestartet.
Von einer anderen Seite betrachtet, kann es aber auch sein, dass man einen weiteren Service ausrollen möchte, der nicht zu der Hostkonfiguration passt und
trotz alledem ein Monitoring etablieren möchte.
Zu diesem Zweck kann man in dem Request für das REST-Interface eine Liste von Services mitgeben, die man erwartet, aber (z.B.) zeitversetzt starten.

In unserem Beispiel fügen wir explizit den Replication Live Server zu unserer Service Discovery hinzu.

```bash
$ curl --request POST http://localhost/api/v2/host/blueprint-box --data '{"config":{"services": ["replication-live-server"]}}'
{
  "blueprint-box": {
    "request": {
      "config": {
        "services": [
          "replication-live-server"
        ]
      }
    }
  },
  "status": 200,
  "message": "the message queue is informed ..."
}
```


