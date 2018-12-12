# Node Exporter

Der Node Exporter ist ein Tool, welches aus dem Prometheus Umfeld entnommen wurde.

Aktuell gibt es keine Installationspakete für Betriebssysteme.
Man kannst sich ein entsprechendes binärpacket bei github herunterladen und installieren.

# Installation

```bash
cd /tmp

VERSION="0.15.2"
curl \
    --silent \
    --location \
    --output node_exporter.tar.gz \
    "https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-amd64.tar.gz"

tar -xzf node_exporter.tar.gz

mv node_exporter-${VERSION}.linux-amd64/node_exporter /bin/node_exporter
```

# Konfiguration & Start

Für *systemd* müssen wir eine entsprechende service Datei erstellen.

```bash
cat << EOF >> /etc/node_exporter.conf
--web.listen-address=:19100
--collector.diskstats.ignored-devices="^(ram|loop|fd|(h|s|v|xv)d[a-z]|nvme\\d+n\\d+p)\\d+$"
--collector.filesystem.ignored-mount-points="^/(sys|proc|dev)($|/)"
--collector.filesystem.ignored-fs-types="^(sys|proc|auto)fs$"
--collector.conntrack
--collector.cpu
--collector.diskstats
--collector.filefd
--collector.filesystem
--collector.hwmon
--collector.loadavg
--collector.meminfo
--collector.mountstats
--collector.netdev
--collector.netstat
--collector.ntp
--collector.stat
--collector.tcpstat
--collector.uname
--collector.vmstat
--collector.xfs
--collector.zfs
EOF

cat <<-"EOF" > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter

[Service]
User=root
ExecStart=/bin/bash --login -c "/bin/node_exporter $(< /etc/node_exporter.conf)"

[Install]
WantedBy=default.target

EOF

systemctl daemon-reload
systemctl enable node_exporter.service
```
