Bereitschaft
=========

## Beschreibung

CoreMedia versucht hier einer Bereitschaft ein kurzes Manifest zu geben um ein entsprechendes Monitoring ohne die Benutzung dieser 
Toolbox zu implementieren.

**Hier aufgeführte Angaben basieren auf theoretischen Annahmen und sind zwingend in einer produktiven Umgebung anzupassen!** 


## Heap Memory
CoreMedia Applikationen sind mit 2GiB Heap Memory konfiguriert worden.

| green | yellow | red |
|:---:|:---:|:---:|
| < 80% used | 80:95 | > 95% used |

## Blob Cache
CoreMedia Applikationen sind mit 10GiB Blob Cache konfiguriert worden.

| green | yellow | red |
|:---:|:---:|:---:|
| < 80% used | 80:95 | > 95% used |

## CAEFeeder
CAEFeeder sollten Projektspezifisch überwacht werden. Die Schwellwerte sind hier von der Anzahl und der 
Abhängigkeitstiefe der jeweiligen Elemente abhängig.
Daher sind die folgenden Werte eher ein initialer Richtwert.

Die Feeder müssen einen **Healthstatus** von *HEALTHY* liefern, sonst ist deren Funktionalität nicht gegeben.

| green | yellow | red |
|:---:|:---:|:---:|
| < 200 | 200:500 | > 500 |



### CAEFeeder HeartBeat

| green | yellow | red |
|:---:|:---:|:---:|
| < 10 ms | 10 ms:60 s | > 60 s |


## Sequenznumbers zwischen MLS und RLS

| green | yellow | red |
|:---:|:---:|:---:|
| < 100 | 100:300 | > 300 |

## Runlevel

Ein *Runlevel* wird von ContentServern geliefert und sollte aud **online** stehen

Zur Beachtung, wenn eine Content Server in einen Maintenance Modus versetzt wird, kann ein Runlevel-Status nicht mehr 
sicher erfasst werden! Sollte dieser in den **offline** Modus versetzt werden, kann hier ein Alarm generiert werden. 

| green | yellow | red |
|:---:|:---:|:---:|
| online | N/A | offline |

## CapConnection

Eine CapConnection wird von Clients genutzt, die eine Verbindung zu einem Content-Server aufbauen.

| green | yellow | red |
|:---:|:---:|:---:|
| open |    | closed |


## UAPI Cache
Das Überwachen von UAPI Caches ist Projektspezifisch und sollte keinen Alarm auslösen.
 
| green | yellow | red |
|:---:|:---:|:---:|
| < 80% used | 80:95 | > 95% used |

## Pending Events / Documents

Pending Evenst bzw. Documents werden vom Content Feeder geliefert und sind ebenfalls Projektspezifisch zu implementieren.

## Lizenzen

Seit Version 170x bietet CoreMedia die Möglichkeit alle Lizenzen zu überwachen.
Das betrifft zum einen die Laufzeit der Content Server Lizenzen, als auch der *concurrent* / *named* Lizenzen

Die Laufzeit der Lizenzen steht sowohl in Tagen, Wochen und Monaten zur Verfügungund sollte mit einer Alarmierung versehen werden.

