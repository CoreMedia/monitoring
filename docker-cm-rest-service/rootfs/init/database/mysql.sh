
# set -e
# set -x

MYSQL_HOST=${MYSQL_HOST:-"database"}
MYSQL_PORT=${MYSQL_PORT:-"3306"}

MYSQL_ROOT_USER=${MYSQL_ROOT_USER:-"root"}
MYSQL_ROOT_PASS=${MYSQL_ROOT_PASS:-""}
MYSQL_OPTS=

DATABASE_NAME=${DATABASE_NAME:-"discovery"}
DBA_USER="discovery"
DBA_PASSWORD="discovery"


[[ -z ${MYSQL_HOST} ]] && return

MYSQL_OPTS="--host=${MYSQL_HOST} --user=${MYSQL_ROOT_USER} --password=${MYSQL_ROOT_PASS} --port=${MYSQL_PORT}"


wait_for_database() {

  RETRY=50

  # wait for database #1
  #
  until [[ ${RETRY} -le 0 ]]
  do
    d=$(dig -t a ${MYSQL_HOST} +short | wc -w)

    [[ ${d} -eq 1 ]] && break

    log_info "Waiting for database host '${MYSQL_HOST}' to come up (${RETRY})"

    sleep 3s
    RETRY=$(expr ${RETRY} - 1)
  done

  if [[ $RETRY -le 0 ]]
  then
    log_error "could not find a database on ${MYSQL_HOST}:${MYSQL_PORT}"
    exit 1
  fi

  RETRY=50

  # wait for database #2
  #
  until [[ ${RETRY} -le 0 ]]
  do
    nc ${MYSQL_HOST} ${MYSQL_PORT} < /dev/null > /dev/null

    [[ $? -eq 0 ]] && break

    log_info "Waiting for database to come up (${RETRY})"

    sleep 3s
    RETRY=$(expr ${RETRY} - 1)
  done

  if [[ $RETRY -le 0 ]]
  then
    log_error "could not connect to database on ${MYSQL_HOST}:${MYSQL_PORT}"
    exit 1
  fi

  RETRY=50

  # must start initdb and do other jobs well
  #
  until [[ ${RETRY} -le 0 ]]
  do
    mysql ${MYSQL_OPTS} --execute="select 1 from mysql.user limit 1" > /dev/null

    [[ $? -eq 0 ]] && break

    log_info "wait for the database for her initdb and all other jobs (${RETRY})"
    sleep 2s
    RETRY=$(expr ${RETRY} - 1)
  done

  if [[ $RETRY -le 0 ]]
  then
    log_error "timeout for initdb on ${MYSQL_HOST}:${MYSQL_PORT}"
    exit 1
  fi

}


configure_database() {

  # create user - when they NOT exists
  query="select host, user, password from mysql.user where user = '${DATABASE_NAME}';"
  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}" | wc -w)

  if [[ ${status} -eq 0 ]]
  then
    log_info "create database '${DATABASE_NAME}' with user and grants for 'discovery'"
    (
      echo "create user '${DATABASE_NAME}'@'%' IDENTIFIED BY '${DBA_PASSWORD}';"
      echo "--- CREATE DATABASE IF NOT EXISTS ${DATABASE_NAME};"
      echo "GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, CREATE, INDEX, EXECUTE ON ${DATABASE_NAME}.* TO 'discovery'@'%' IDENTIFIED BY '${DBA_PASSWORD}';"
      echo "FLUSH PRIVILEGES;"
    ) | mysql ${MYSQL_OPTS}

    if [[ $? -eq 1 ]]
    then
      log_error "can't create Database '${DATABASE_NAME}'"
      exit 1
    fi
  fi

  # check if database already created ...
  #
  query="SELECT TABLE_SCHEMA FROM information_schema.tables WHERE table_schema = \"${DATABASE_NAME}\" limit 1;"

  status=$(mysql ${MYSQL_OPTS} --batch --execute="${query}")

  if [[ $(echo "${status}" | wc -w) -eq 0 ]]
  then
    # Database isn't created
    # well, i do my job ...
    #
    log_info "Initializing database."

    (
      echo "CREATE DATABASE IF NOT EXISTS ${DATABASE_NAME};"
      echo "--- GRANT SELECT, INSERT, UPDATE, DELETE, DROP, CREATE VIEW, CREATE, INDEX, EXECUTE ON ${DATABASE_NAME}.* TO 'discovery'@'%' IDENTIFIED BY '${DBA_PASSWORD}';"
      echo "FLUSH PRIVILEGES;"
    ) | mysql ${MYSQL_OPTS}

    if [[ $? -eq 1 ]]
    then
      log_error "can't create Database '${DATABASE_NAME}'"
      exit 1
    else

      mysql ${MYSQL_OPTS} --execute="select user from mysql.user where user = 'discovery' limit 1" > /dev/null

      if [[ $? -gt 0 ]]
      then
        log_error "user are not successful created :("
      fi
    fi

  fi

}


wait_for_database

configure_database

