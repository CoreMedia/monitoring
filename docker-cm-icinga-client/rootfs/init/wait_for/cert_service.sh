
# wait for the Certificate Service
#
wait_for_icinga_cert_service() {

  # the CERT-Service API use an Basic-Auth as first Authentication *AND*
  # use an own API Userr
  [[ "${USE_CERT_SERVICE}" == "false" ]] && return

  # use the new Cert Service to create and get a valide certificat for distributed icinga services
  if (
    [[ ! -z ${ICINGA_CERT_SERVICE_SERVER} ]] &&
    [[ ! -z ${ICINGA_CERT_SERVICE_PORT} ]] &&
    [[ ! -z ${ICINGA_CERT_SERVICE_BA_USER} ]] &&
    [[ ! -z ${ICINGA_CERT_SERVICE_BA_PASSWORD} ]] &&
    [[ ! -z ${ICINGA_CERT_SERVICE_API_USER} ]] &&
    [[ ! -z ${ICINGA_CERT_SERVICE_API_PASSWORD} ]]
  )
  then
    log_info "waiting for our certificate service on '${ICINGA_CERT_SERVICE_SERVER}:${ICINGA_CERT_SERVICE_PORT}/${ICINGA_CERT_SERVICE_PATH}' to come up"

    RETRY=35
    # wait for the running certificate service
    #
    until [[ ${RETRY} -le 0 ]]
    do
      nc -z ${ICINGA_CERT_SERVICE_SERVER} ${ICINGA_CERT_SERVICE_PORT} < /dev/null > /dev/null

      [[ $? -eq 0 ]] && break

      sleep 15s
      RETRY=$(expr ${RETRY} - 1)
    done

    if [[ $RETRY -le 0 ]]
    then
      log_error "Could not connect to the certificate service on '${ICINGA_CERT_SERVICE_SERVER}'"
      exit 1
    fi

    # okay, the web service is available
    # but, we have a problem, when he runs behind a proxy ...
    # eg.: https://monitoring-proxy.tld/cert-cert-service
    #

    RETRY=30
    # wait for the certificate service health check behind a proxy
    #
    until [[ ${RETRY} -le 0 ]]
    do
      health=$(curl \
        --silent \
        --request GET \
        --write-out "%{http_code}\n" \
        --request GET \
        http://${ICINGA_CERT_SERVICE_SERVER}:${ICINGA_CERT_SERVICE_PORT}/${ICINGA_CERT_SERVICE_PATH}/v2/health-check)

      if ( [[ $? -eq 0 ]] && [[ "${health}" == "healthy200" ]] )
      then
        break
      fi

      health=

      # log_info "wait for the health check on '${ICINGA_CERT_SERVICE_SERVER}' for the certificate service"
      sleep 15s
      RETRY=$(expr ${RETRY} - 1)
    done

    if [[ $RETRY -le 0 ]]
    then
      log_error "The health-check could not be reached"
      exit 1
    fi

    sleep 5s
  fi
}

wait_for_icinga_cert_service
