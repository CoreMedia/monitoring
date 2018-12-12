
# Changelog

## 1810

- update to grafana 5.2.4
- update to icinga2 2.9.2
- remove postgres support in data-collector
- enhanced support of moebius' multi-node-deployment
  - import only the really needed Grafana templates
  - support multiple installations of CAE(Live) on one host
- better errorhandling at importing of grafana dashboards
- support for the Publisher mbean (used in the content-management-server application)
- add check_publisher for icinga2
- add open file descriptors monitoring to icinga and grafana
- fix double entries in the prepared service cache
- more measuring points for mysql / mariadb monitoring
- change markdown browser backend to algernon
- remove postgres support
- enable cors for external integration
- remove obsolete code


## 1808

- updates for mongodb 3.6
  - MongoDB 3.6 removes the deprecated HTTP interface and REST API to MongoDB
    we support now the official ruby client
- support alpine 3.8
- update to grafana 5.2.2
- update to icinga2 2.9.1
- update to icingaweb2 1.6.1
- update to jolokia 1.6.0
- updates for mongodb 3.6 (remove deprecated HTTP interface and REST API)
- updates for more than one node deployment
- enable the refresh task in the service-discovery per default
- fix bug with ecommerce cache dashboard
- fix some grafana 5 dashboards
- create team prefixed docker-compose files
- fix bug for content server detection when the hostname was 'localhost'


## 1806

- update to grafana 5.1.3
- grafana folder support
- set grafana 5 as default
- split annotations into more types
- update to icinga2 2.8.4
- update to icingaweb2 2.5.3
- update to jolokia 1.5.0
- update to graphite 1.1.3
- jolokia supports now authentication
- update to grafana gem 0.10.1
- update to icinga2 gem 1.0.0
- add new documentations container
  - including the stack documentation and a operation guide
- support node_exporter v0.16.x


## 1804

- add more documentations
- bugfix for icinga2 memory check
- update to grafana 5.0.4
- update icingaweb2
- set warning and critical values in some icinga2 checks
- add max feeder elements for CAE Feeders
- add this web UI
- add Background Feeder graphs for Content Feeder
- remove 'used UAPI Cache' from Grafana Overview


## 1803

- environments
  - update data-visualisation environment
  - update data-compose environment

- default log output is now stdout
- DNS resolver rewritten
- change output format
- singulary environment and json are now possible
- add Loglevel over Environment Variable
  * you can now set a LOG_LEVEL Environment to modify the Loglevel
    possible values are: DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
    default is INFO
    no valid value will set to UNKNOWN
- remove some obsolete parts

- use new version for icinga2 certificate exchange (0.17.5)

- fix timing problems for RLS (#126)

- icinga2-master / icinga2-satellite / icinga-client
  - update the complete icinga suite
  - enable safe master/satellite communication with self-monitoring
  - use icinga2 gem in version 0.9.3.7 (1.0-rc)

- dashing
  - update for icinga-cert-service
  - use puma instead of thin

- grafana / grafana-client
  - overview dashboards can now be grouped by an array of tags
  - use the new annotation feature of Grafana 4.6
    remove the graphite-client, container is no longer needed
  - fix typos
  - fix bug with template_directory
  - enable grafana5
  - the grafana-client used now ruby erb templates insteed prepared json files

- carbon-client
  - code optimizations
  - add support for CoreMedia/cms#13125

- remove cm-external-discover container (is no longer needed)

- https support for webservice

- more documentations

## 1712


**BREAKING CHANGES**
 - The *internal API Port* was changed from 4567 to 8080
 - The Icinga2 Container has updated to v2.8.0 including certificateshandling
    **the docker volumes should be deleted for this container to create a new CA:** `docker volume rm -f aio_icinga`

----
update some containers
add healthchecks to all Containers
rewrite dokumentation
consolidate all Dockerfiles
reduce environment variables
move some mq-jobs from the rest-service to service-discovery

- data-collector
  add exception for missing MLS  DNS entry
  all non-coremedia services (mysql, node_exporter, etc.) can now be in the cm-service.yaml configured
  e.g. port and cretentials

      mysql:
        description: MySQL
        port: 3306
        monitoring_user: monitoring
        monitoring_password: monitoring

- service-discovery
  implement a 'rediscovery' feature
  after the service refreshing for the data-collector
  update the grafana dashboards.
  the overview and the license dashboard must be deleted before we can call the create_dashboard_for_host() function.

- icinga-client
  add certificate support for the icinga-client
  update cm-icinga-client to use the service refresh event from our service-discovery

- docker-compose
  remove all hard coded network ip
  use now the DNS from docker-host
  put all environment variables from environment.yaml back to docker-compose.yaml (possible depricated)

- grafana-client
  update grafana gem
  update all API calls
  integrate the new annotation feature of grafana (#104)
  the configure_server function for grafana can now handle inline ruby erb template parts

- rest-service
  minor improvements
  sanity checks for the REST API
  interanl cleanup and use of ruby styleguide

- icinga2
  add node_exporter check for load, memory and filesystem
  change icinga check for the sequence numbers between msl and rls
  use icinga2 side-channel to inject an inotify script for watching added hosts

- Dashboards:
  fix short link for mongodb
  add load, and cpu count for the OS row


## 1711

- recreate monitoring class as module and use a better structure
- optimize the rest service
- fix bug with the 'force' flag for creating hosts (#85)
- support https (#98)
- integrate ruby gem for grafana (#91)
- update some docker container
- enhance icinga2 checks (#84)
- add LDAP Support for grafana and icinga2 (#83)
- fixes for creating annotations
- optimize code


## 1710

- fix problems with API access to grafana
- the API force flag are now stable
- new Port-Scanner
- fix problems with the 0.9 version of icinga2 gem
- the CAEs (live and preview) report there ContentServer similar to the MasterLiverServer for the ReplicationLiveServer
- the CAE ContentServer and the MasterLiveServer for the RLS are now available as custom vars into Icinga Host Information
- some documentation exapmles for our API
- reduce timing issues for add Host into Icinga and/or Grafana
- generally updates


## 1708-31

- new LTS Version with many feature for monitoring in the AWS environment


## 1708-30

- new LTS Version with many feature for monitoring in the AWS environment
