# CoreMedia Monitoring Toolbox - Operations Guide

## CAE Feeder

Die CAE Feeder sind ein integraler Bestandteil der Suche und stellen ebenso den Content für dynamische Seiten zur Verfügung.


CAE Feeder gibt es in 2 verschiedenen Ausführungen:

- der *Preview Feeder*: er befüllt den Index (Solr-Core: preview) der Suchmaschine aus Inhalten aus dem CMS (d.h. noch nicht publizierte Inhalte)
- der *Live Feeder*: er befüllt den Index (Solr-Core: live) der Suchmaschinen aus publizierten Inhalten (d.h. aus MLS oder einem RLS)

----

Unter Umständen ist es nötig, das ein Feeder den completten Content neu indizieren soll.

**Dieser Vorgang ist abhängig vom vorliegenden Content und kann sehr zeitaufwändig sein!**

Ein Feeder reset kann aktuell nur mit den zugehörigen `cm` Tools durchgeführt werden:

```bash
# export JAVA_HOME=/usr/java/latest
# /opt/coremedia/caefeeder-live-tools/bin/cm resetcaefeeder reset
The CAE Feeder will be reset when restarted.
# service caefeeder-live restart
```

Für den *Preview Feeder* funktioniert das äquivalent.

----

## Operating

| Fehler  | ToDo      |
| :------ | :-------- |
|         |           |

