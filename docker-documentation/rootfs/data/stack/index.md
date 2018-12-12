# CoreMedia Monitoring Toolbox

Die *CoreMedia Monitoring Toolbox* bündelt ein Set von Services um ein Monitoring von CoreMedia Applikationen zu ermöglichen.

Das Monitoring arbeitet passiv und es werden - bis auf kleinere Ausnahmen - keinerlei Anpassungen am Zielsystem nötig.

Aktuell sind folgende Services im Monitoring integriert:

  - Langzeitgraphen mittels Grafana
  - Alarmierungen mit Icinga2
  - einfaches Dashboard mit Dashing
  - Demonstration einer Bereitschaftsdokumentation mit Integration in das Webinterface von Icinga2

Alle im weiteren Verlauf erwähnten Meßpunkte werden durch eine *Service-Discovery* detektiert und dem Monitoring zur Verfügung gestellt.

Die Monitoring-Toolbox lässt sich über eine API manuell nutzen oder in einer CI Umgebung integrieren.


1. [Installation](./de/installation.md)
2. [Konfiguration](./de/konfiguration.md)
3. [API](./de/api.md)
4. [JMX](./de/jmx.md)
5. [Bereitschaft](./de/bereitschaft.md)
6. [Service Discovery](./de/service-discovery.md)
7. [Screenshots](./de/screenshots.md)


## CoreMedia Applikationen

Bei CoreMedia Applikationen lassen sich folgende Systmparameter überwachen:

  - Tomcat interne Speicher (Heap-Memory, Perm-Memory, Caches)
  - Contentserver Lizenzen (Gültigkeit und verbrauchte (concurrent / named) Lizenzen)
  - Runlevel der Contentserver
  - Sequenznummern von MLS & RLS, sowie eine automatisch berechnete Differenz der Sequenznummern
  - Gültigkeit von CapConnections
  - Auslastung der UAPI Caches
  - Auslastung der Blob Caches
  - zu feedende Elemete der CAEFeeder
  - Genutzte Lightweight Session von Clients
  - Auslastung der CAE Caches
  - Auslastung der eCommerce Caches
  - Gültigkeit von SSL Zertifikaten und deren Ablaufdatum

## Datenbanken

Sollten die Ports von MySQL und MongoDB erreichbar sein erhält man zusätzlich die Daten dieser Services.

## Betriebssystemdaten

Daten der Betriebssystemes können durch die Nutzung des `node_exporters` ausgelesen werden.

Dazu muß der entsprechende Service [installiert und gestartet](./de/node_exporter.md) werden.

## Webserver

Wenn der Apache Webserver `mod_status` aktiviert hat, können die darüber zur Verfügung stehenden Daten in das Monitoring integriert werden.
Wenn im default vhost eine `vhosts.json` Datein vorhanden ist, dann werden alle dort integrierten VHosts in das Monitoring aufgenommen.
Alternativ kann auch ein eigener VHost mit entsprechenden Port definiert werden.

