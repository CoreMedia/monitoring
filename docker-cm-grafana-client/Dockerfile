
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

WORKDIR /usr/local/bin

RUN \
  apk update  --quiet && \
  apk upgrade --quiet && \
  apk add     --quiet --no-cache --virtual .build-deps \
    build-base imagemagick-dev ruby-dev mariadb-dev tzdata && \
  apk add     --quiet --no-cache \
    bind-tools drill mariadb-connector-c ruby-irb && \
  cp "/usr/share/zoneinfo/${TZ}" /etc/localtime && \
  echo "${TZ}" > /etc/timezone && \
  echo 'gem: --no-document' >> /etc/gemrc && \
  gem install --quiet --no-rdoc --no-ri \
    io-console bundler json && \
  cd /build && \
  if [ "${GRAFANA_GEM_TYPE}" == "local" ] ; then \
    for g in /build/*.gem ; \
    do \
      [[ -e ${g} ]] || continue ; \
      echo "local gem: '${g}'" ; \
      gem install --no-rdoc --no-ri ${g} ; \
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

CMD ["grafana-client.rb"]

HEALTHCHECK \
  --interval=5s \
  --timeout=2s \
  --retries=12 \
  CMD ps ax | grep -v grep | grep -c grafana-client.rb || exit 1

# ---------------------------------------------------------------------------------------

LABEL \
  version="${BUILD_VERSION}" \
  maintainer="Bodo Schulz <bodo@coremedia.com>" \
  org.label-schema.build-date=${BUILD_DATE}

# ---------------------------------------------------------------------------------------
