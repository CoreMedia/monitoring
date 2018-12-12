#!/bin/sh

AUTH_TOKEN=${AUTH_TOKEN:-$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)}

export WORK_DIR=/srv

# -------------------------------------------------------------------------------------------------

. /init/output.sh
. /init/configure_smashing.sh
. /init/icinga_cert.sh

log_info "==================================================================="
log_info " Dashing AUTH_TOKEN set to '${AUTH_TOKEN}'"
log_info "==================================================================="

# -------------------------------------------------------------------------------------------------

log_info "start init process ..."

cd /opt/${DASHBOARD}

/usr/bin/puma \
  --config /opt/${DASHBOARD}/config/puma.rb > /dev/null

# EOF
