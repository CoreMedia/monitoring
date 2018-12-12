
SHELL := /bin/bash

.PHONY: build clean carbon-client dashing data-collector grafana-client icinga2-master icinga-client jolokia rest-service service-discovery documentation

default: build

# build jobs
#
carbon-client:
	pushd docker-cm-carbon-client && make && popd

dashing:
	pushd docker-cm-dashing && make && popd

data-collector:
	pushd docker-cm-data-collector && make && popd

grafana-client:
	pushd docker-cm-grafana-client && make && popd

icinga2-master:
	pushd docker-cm-icinga2 && make && popd

icinga-client:
	pushd docker-cm-icinga-client && make && popd

jolokia:
	pushd docker-cm-jolokia && make && popd

notification-client:
	pushd docker-cm-notification-client && make && popd

rest-service:
	pushd docker-cm-rest-service && make && popd

service-discovery:
	pushd docker-cm-service-discovery && make && popd

documentation:
	pushd docker-documentation && make && popd

# clean jobs
#
carbon-client-clean:
	pushd docker-cm-carbon-client && make clean && popd

dashing-clean:
	pushd docker-cm-dashing && make clean  && popd

data-collector-clean:
	pushd docker-cm-data-collector && make clean  && popd

grafana-client-clean:
	pushd docker-cm-grafana-client && make clean  && popd

icinga2-master-clean:
	pushd docker-cm-icinga2 && make clean  && popd

icinga-client-clean:
	pushd docker-cm-icinga-client && make clean  && popd

jolokia-clean:
	pushd docker-cm-jolokia && make clean && popd

notification-client-clean:
	pushd docker-cm-notification-client && make clean && popd

rest-service-clean:
	pushd docker-cm-rest-service && make clean && popd

service-discovery-clean:
	pushd docker-cm-service-discovery && make clean && popd

documentation-clean:
	pushd docker-documentation && make clean && popd



clean:	 carbon-client-clean	dashing-clean	data-collector-clean	grafana-client-clean	icinga2-master-clean	icinga-client-clean	jolokia-clean	rest-service-clean	service-discovery-clean	documentation-clean

build: carbon-client	dashing	data-collector grafana-client icinga-client icinga2-master jolokia rest-service service-discovery documentation
