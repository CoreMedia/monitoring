
# wait for the Icinga2 Master
#
wait_for_icinga_master() {

  [[ ${USE_CERT_SERVICE} == "false" ]] && return

  RETRY=50

  until [[ ${RETRY} -le 0 ]]
  do
    nc -z ${ICINGA_MASTER} 5665 < /dev/null > /dev/null

    [[ $? -eq 0 ]] && break

    sleep 5s
    RETRY=$(expr ${RETRY} - 1)
  done

  if [[ $RETRY -le 0 ]]
  then
    log_error "could not connect to the icinga2 master instance '${ICINGA_MASTER}'"
    exit 1
  fi

  sleep 5s
}

wait_for_icinga_master
