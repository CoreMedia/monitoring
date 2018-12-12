# CoreMedia Monitoring Toolbox - Operations Guide

## License

Alle CoreMedia Contentserver (CMS, MLS, RLS) werden mit seperaten Lizenzen ausgestattet.

----

Ist die Lizenz abgelaufen, dann schalten sich die Services in eine Art Standby-Modus.
Sollte das passieren, sind sämtliche Komponenten Out-of-Business. Im Frontend werden dadurch keine Seiten mehr ausgeliefert!

Lizenzdateien können via Email über den Support bei Coremedia (support@coremedia.com) bestellt werden.

Bei einem Austausch von Lizenzen sollten die Services nicht neu gestartet werden müssen.

----

## Operating

### Der Lizenzcheck alarmiert

**Eine neue Lizenz muss über ein Supportticket angefordert werden!**


----

## Logfile

Im Logfile des RLS kann man sich weitere Informationen besorgen, wenn man diese nicht in einem Monitoring hat.

### Speicherort der Lizenzdatei

```bash
grep "cap.server.license" $logfile
```

# Gültigkeit der Lizenz

Sollten die CoreMedia Tools installiert worden sein, kann man auch hierüber die Lizendaten ausgeben:

```bash
/opt/coremedia/content-management-server-tools/bin/cm license -u admin
/opt/coremedia/master-live-server-tools/bin/cm license -u admin
/opt/coremedia/replication-live-server-tools/bin/cm license -u admin
```

Oder über den lokalen Check:

```bash
check_license --hostname osmc.local  -C content-management-server --hard --soft
soft: CoreMedia license is valid until 06.06.2018 - <b>88 days left</b> (OK)<br>hard: CoreMedia license is valid until 06.06.2018 - <b>88 days left</b> (OK) | valid_soft=88 valid_hard=88
```
