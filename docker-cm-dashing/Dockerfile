
FROM bodsch/docker-dashing:1808

ARG BUILD_DATE
ARG BUILD_VERSION

ENV \
  VERSION="${BUILD_VERSION}" \
  BUILD_DATE="${BUILD_DATE}" \
  TZ='Europe/Berlin' \
  DASHBOARD="coremedia" \
  ICINGA2_GEM_TYPE="stable" \
  ICINGA2_GEM_VERSION="1.0.0"

EXPOSE 3030

# ---------------------------------------------------------------------------------------

COPY build /build

RUN \
  apk update  --quiet --no-cache && \
  apk upgrade --quiet --no-cache && \
  apk add --quiet --virtual .build-deps \
    build-base git ruby-dev openssl-dev && \
  apk add --quiet --no-cache \
    jq tzdata yajl-tools && \
  cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
  echo ${TZ} > /etc/timezone && \
  cd /opt && \
  smashing new ${DASHBOARD} && \
  rm -f /opt/${DASHBOARD}/jobs/twitter* && \
  rm -f /opt/${DASHBOARD}/dashboards/* && \
  cd ${DASHBOARD} && \
  sed -i "/gem 'twitter'/d" Gemfile && \
  echo "gem 'puma', '~> 3.10'" >> Gemfile && \
  if [ "${ICINGA2_GEM_TYPE}" == "local" ] ; then \
    for g in $(ls -1 /build/*.gem 2> /dev/null) ; do \
      echo "install local gem '${g}'" && \
      gem install --quiet --no-rdoc --no-ri ${g} ; \
    done ; \
  elif [ "${ICINGA2_GEM_TYPE}" == "stable" ] ; then \
    echo "gem 'icinga2', '~> ${ICINGA2_GEM_VERSION}'" >> Gemfile ; \
  fi && \
  gem install --quiet --no-rdoc --no-ri \
    etc && \
  bundle update --quiet && \
  apk del --quiet --purge .build-deps && \
  rm -rf \
    /tmp/* \
    /build \
    /var/cache/apk/* \
    /usr/lib/ruby/gems/current/cache/* \
    /root/.gem \
    /root/.bundle

COPY rootfs/ /

WORKDIR /opt/${DASHBOARD}

HEALTHCHECK \
  --interval=5s \
  --timeout=2s \
  --retries=12 \
  CMD curl --silent --fail http://localhost:3030/dashing/${DASHBOARD} || exit 1

CMD [ "/init/run.sh" ]

# ---------------------------------------------------------------------------------------

LABEL \
  version="${BUILD_VERSION}" \
  maintainer="Bodo Schulz <bodo@coremedia.com>" \
  org.label-schema.build-date=${BUILD_DATE}

# ---------------------------------------------------------------------------------------
