
# Integration einer CoreMedia Blueprint Box

Wenn eine lokale Blueprint Box für ein Monitoring genutzt werden soll, muß darauf geachtet werden, dass die benötigte DNS Auflösung gewährleistet ist.

In der Regel ist die Blueprint Box folgendermaßen erreichbar:

  - IP: `192.168.252.100`
  - xip.io: `192.168.252.100.xip.io`
  - Name: `blueprintbox`

Vorab sollten wir die DNS Auflösung prüfen:

```bash
$ nslookup 192.168.252.100
100.252.168.192.in-addr.arpa    name = blueprint-box.

$ dig -t any 192.168.252.100.xip.io +short
192.168.252.100

$ dig -t any blueprint-box +short
192.168.252.100
```

Sollten die hier gezeigten Auflösungen nicht funktionieren, muß ein lokaler DNS konfiguriert werden.
Unter Linux empfiehlt sich `dnsmasq` und eine erweiterung der `/etc/hosts`:

```bash
$ cat /etc/hosts

192.168.252.100         blueprint-box
192.168.252.100         corporate.blueprint-box
192.168.252.100         preview.blueprint-box
192.168.252.100         sitemanager.blueprint-box
192.168.252.100         studio.blueprint-box
192.168.252.100         overview.blueprint-box
```

`dnsmasq` nutzt die Einträge in der `/etc/hosts` und löst diese dann entsprechend auf.
