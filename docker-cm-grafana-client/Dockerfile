
FROM alpine:3.8

ARG BUILD_DATE
ARG BUILD_VERSION

ENV \
  VERSION="${BUILD_VERSION}" \
  BUILD_DATE="${BUILD_DATE}" \
  TERM=xterm \
  TZ='Europe/Berlin' \
  GRAFANA_GEM_TYPE="stable" \
  GRAFANA_GEM_VERSION="0.10.2"

# ---------------------------------------------------------------------------------------

COPY build /build

RUN \
  apk --quiet --no-cache update && \
  apk --quiet --no-cache upgrade && \
  apk add --quiet --no-cache --virtual .build-deps \
    build-base imagemagick-dev ruby-dev mariadb-dev tzdata && \
  apk add --quiet --no-cache \
    bind-tools drill mariadb-connector-c ruby-irb && \
  cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
  echo ${TZ} > /etc/timezone && \
  gem install --quiet --no-rdoc --no-ri \
    io-console bundler json && \
  cd /build && \
  if [ "${GRAFANA_GEM_TYPE}" == "local" ] ; then \
    for g in $(ls -1 /build/*.gem 2> /dev/null) ; do \
      echo "install local gem '${g}'" && \
      gem install --quiet --no-rdoc --no-ri ${g} ; \
    done ; \
  elif [ "${GRAFANA_GEM_TYPE}" == "stable" ] ; then \
    echo "gem 'grafana', '~> ${GRAFANA_GEM_VERSION}'" >> Gemfile ; \
  fi && \
  bundle install --quiet && \
  gem uninstall --quiet \
    io-console bundler && \
  apk del --quiet .build-deps && \
  rm -rf \
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
  CMD ps ax | grep -v grep | grep -c grafana-client.rb || exit 1

CMD [ "/usr/local/bin/grafana-client.rb" ]

# ---------------------------------------------------------------------------------------

LABEL \
  version="${BUILD_VERSION}" \
  maintainer="Bodo Schulz <bodo@coremedia.com>" \
  org.label-schema.build-date=${BUILD_DATE}

# ---------------------------------------------------------------------------------------
