#
#
#

set -e

# -------------------------------------------------------------------------------------------------

is_ip() {
  echo $(ipcalc ${1} | head -n1 | grep -c 'INVALID ADDRESS')
}

check_ip() {

  if [ $(is_ip ${1}) -eq 1 ]
  then
    name=$(host -t A ${1} | grep "has address" | cut -d ' ' -f 4)

    if [ -z ${name} ]
    then
      echo ${1}
    else
      echo ${name}
    fi
#    echo $(host -t A ${1} | grep "has address" | cut -d ' ' -f 4)
  else
    echo ${1}
  fi
}


add_dns() {

  local name=${1}
  local ip=${2}
  local aliases="${3}"

  ip="$(check_ip ${ip})"

  if [ -z ${ip} ]
  then
    echo " [E] - the ip can't resolve! :("
    return
  fi

  [ -z "${aliases}" ] || aliases=$(echo "${aliases}" | sed -e 's| ||g' -e 's|,|","|g')

  if [ "${name}" == "blueprint-box" ]
  then
    aliases="\"aliases\":[\"${aliases}\", \"${ip}.xip.io\", \"${name}\", \"${name}.docker\"]"
  else
    aliases="\"aliases\":[\"${name}\",\"${aliases}\"]"
  fi

  echo "add host '${name}' with ip '${ip}' and aliases '${aliases}' to dns"

  curl \
    http://dnsdock/services/${name} \
    --silent \
    --request PUT \
    --data-ascii "{\"name\":\"${name}\",\"image\":\"${name}\",\"ips\":[\"${ip}\"],\"ttl\":0,${aliases}}"
}


read_additional_dns() {

  if [ ! -z "${ADDITIONAL_DNS}" ]
  then

    echo "${ADDITIONAL_DNS}" | jq --compact-output --raw-output ".[]" | while IFS='' read x
    do

      if [[ ${x} == null ]]
      then
        continue
      fi

      name=$(echo "${x}" | jq --raw-output .name)
      ip=$(echo "${x}" | jq --raw-output .ip)
      aliases=$(echo "${x}" | jq --raw-output '.aliases | join(", ")')

      [ ${name} == null ] && continue
      [ "${aliases}" == null ] && aliases=

      add_dns "${name}" "${ip}" "${aliases}"
    done

  fi
}

read_additional_dns
