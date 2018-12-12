#!/bin/sh

# set -x

. /init/output.sh

# -------------------------------------------------------------------------------------------------

run() {

  . /init/database/mysql.sh

#   . /init/dns.sh

  /usr/local/bin/rest-service.rb
}

run

# EOF
