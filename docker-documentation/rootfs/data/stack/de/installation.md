Installation
============

Beispielhaft wird hier eine Installation auf einem *Linux* System beschrieben.
MacOS bzw. Windows sollten ähnlich funktionieren.

### Docker-Engine

Zum Betrieb der Toolbox wird eine `docker-engine` benötigt.

Die Empfehlung hierbei ist eine Version >= `17.04`

Je nach Distribution muß dazu eine bereits bestehende Docker Installation entfernt werden und ggf. das Repositoriy von *docker-ce* eingebunden werden.

**Debian**

```bash
apt-get remove \
  docker docker-engine

apt-get install apt-transport-https \
  ca-certificates curl python-software-properties

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

apt-get update

apt-get install docker-ce
```

**CentOS**

```bash
yum remove \
  docker docker-common container-selinux docker-selinux docker-engine

yum install -y \
  yum-utils

yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

yum makecache \
  fast

yum install \
  docker-ce
```

### Docker-Compose

Neben dem eigentlichen `docker` benötigen wir noch das `docker-compose` binary.
Dieses bietet eine einfach Möglichkeit, viele Container und deren Abhängigkeiten einfach zu orchestrieren.

```bash
COMPOSE_VERSION="1.16.1"
URL="https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)"

curl -L ${URL} > /usr/bin/docker-compose_${COMPOSE_VERSION}

ln -s /usr/bin/docker-compose_${COMPOSE_VERSION} /usr/bin/docker-compose
```

### Post-Installation (optional)

Wenn ein spezieller User `docker` benutzen soll, benötigen wir noch eine entsprechende Gruppe und fügen diesen User dier Gruppe hinzu:

```bash
groupadd docker

usermod -aG docker $USER
```

Damit wäre die Basisvoraussetzung erfüllt.



### Monitoring-Toolbox

Als nächstes muß die CoreMedia Monitoring-Toolbox installiert werden.

```bash
cd ~
mkdir cm-monitoring-toolbox
cd cm-monitoring-toolbox

git clone https://github.com/cm-xlabs/monitoring.git
```

Nach dem erfolgreichen clonen sollte ungefähr diese Verzeichnissstruktur vorhanden sein:

```bash
monitoring
  ├── bin
  ├── docker-cm-carbon-client
  ├── docker-cm-dashing
  ├── docker-cm-data
  ├── docker-cm-data-collector
  ├── docker-cm-external-discover
  ├── docker-cm-grafana-client
  ├── docker-cm-graphite-client
  ├── docker-cm-icinga2
  ├── docker-cm-icinga-client
  ├── docker-cm-jolokia
  ├── docker-cm-notification-client
  ├── docker-cm-rest-service
  ├── docker-cm-service-discovery
  ├── documentation
  ├── environments
  │    ├── aio
  │    │    ├── docker-compose.yml
  │    │    └── environments.yml
  │    ├── data-capture
  │    └── data-visualization
  │
  └── tools
```

Alle Verzeichnisse, die mit `docker-cm` beginnen, beinhalten die komplette CoreMedia Logik bezüglich des Monitorings, 
oder sind spezielle Clients für OpenSource Komponenten.


Im Verzeichniss `environments` befinden sich 3 verschieden Monitoringumgebungen:

  * `aio` (All-In-One) - beinhaltet die komplette Toolbox. 
   Diese kann idealerweise auf einem dezidiertem Server oder einem Notebook installiert werden und bietet die geringsten Einstiegshürden.
   Dies ist die Basis für den folgenden Schnelleinstieg.
  * `data-capture` - beinhaltet alle Services um Daten zu erfassen und an externe Services weiterzuleiten.
  * `data-visualization` - beinhaltet alle Services um Monitoringdaten darzustellen.

Um den Startvorgang zu beschleunigen, werden pre-compiled OpenSource Container von [Docker Hub](https://hub.docker.com/r/bodsch/) benutzt.

---

### Links

#### Linux

 - [docker-compose](https://docs.docker.com/compose/install/)
 - [docker-engine](https://docs.docker.com/engine/installation/linux/)

#### MacOS
 - [docker-compose](https://docs.docker.com/compose/install/)
 - [docker-engine](https://docs.docker.com/engine/installation/mac/)

#### Windows

 - [docker-compose](https://docs.docker.com/compose/install/)
 - [docker-engine](https://docs.docker.com/engine/installation/windows/)
