# CoreMedia Monitoring Toolbox - Operations Guide

## Content Feeder

Der Contentfeeder befüllt den Solr-Index (core: studio) der Suchmaschinen für die Studios.

Dieser Feeder wird aktiv, sobald Content durch das Studio, oder durch einen Seitenkanal (automatischer Contentimport über einen UAPI-Client) hinzugefügt oder geändert wird.

Dazu gehören auch Rechteänderungen!

Da dieser Feeder - im Gegensatz zu den CAE Feedern - den kompletten Content kennt und bearbeitet sind entsprechend ausgelöste Tasks entsprechende Langläufer!

Der Contentfeeder kann ausschließlich über ein Webinterface zurückgesetzt werden!

Dazu muß man eine Verbindung auf den entsprechenden HTTP Port des Services aufbauen:

```bash
http://${SERVER}:40480/contentfeeder/admin
```

Um den Feeder zurückzusetzen, muß man diesen ersteinmal stoppen. Anschließend kann man `Clear the Search Engine index` auswählen.

Der Feeder bleibt so lange im Zustand *stopped*, bis man ihn auf der Kommandozeile neu gestartet hat

```bash
service content-feeder restart
```
