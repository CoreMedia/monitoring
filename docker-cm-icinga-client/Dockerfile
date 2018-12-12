
FROM alpine:3.8

ARG BUILD_DATE
ARG BUILD_VERSION

ENV \
  VERSION="${BUILD_VERSION}" \
  BUILD_DATE="${BUILD_DATE}" \
  TERM=xterm \
  TZ='Europe/Berlin' \
  ICINGA2_GEM_TYPE="stable" \
  ICINGA2_GEM_VERSION="1.0.0"

# ---------------------------------------------------------------------------------------

COPY build /build

RUN \
  apk --quiet --no-cache update && \
  apk --quiet --no-cache upgrade && \
  apk add --quiet --no-cache --virtual .build-deps \
    build-base git ruby-dev ruby-rdoc tzdata && \
  apk --quiet --no-cache add \
    bind-tools curl drill mariadb-dev mariadb-connector-c jq libressl-dev ruby-irb yajl-tools && \
  cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
  echo ${TZ} > /etc/timezone && \
  echo 'gem: --no-document' >> /etc/gemrc && \
  gem install --quiet --no-rdoc --no-ri \
    io-console bundler json && \
  cd /build && \
  if [ "${ICINGA2_GEM_TYPE}" == "local" ] ; then \
    for g in $(ls -1 /build/*.gem 2> /dev/null) ; do \
      echo "install local gem '${g}'" && \
      gem install --quiet --no-rdoc --no-ri ${g} ; \
    done ; \
  elif [ "${ICINGA2_GEM_TYPE}" == "stable" ] ; then \
    echo "gem 'icinga2', '~> ${ICINGA2_GEM_VERSION}'" >> Gemfile ; \
  fi && \
  bundle install --quiet && \
  gem uninstall --quiet \
    io-console bundler && \
  apk del --quiet .build-deps && \
  rm -rf \
    /opt/* \
    /tmp/* \
    /build \
    /root/.bundle \
    /root/.gem \
    /var/cache/apk/*

COPY rootfs/ /

WORKDIR /

HEALTHCHECK \
  --interval=5s \
  --timeout=2s \
  --retries=12 \
  CMD ps ax | grep -c icinga-client.rb || exit 1

ENTRYPOINT [ "/init/run.sh" ]

CMD [ "/usr/local/bin/icinga-client.rb" ]

# ---------------------------------------------------------------------------------------

LABEL \
  version="${BUILD_VERSION}" \
  maintainer="Bodo Schulz <bodo@coremedia.com>" \
  org.label-schema.build-date=${BUILD_DATE}

# ---------------------------------------------------------------------------------------
