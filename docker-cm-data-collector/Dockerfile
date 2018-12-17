
FROM alpine:3.8

ARG BUILD_DATE
ARG BUILD_VERSION

ENV \
  VERSION="${BUILD_VERSION}" \
  BUILD_DATE="${BUILD_DATE}" \
  TERM="xterm" \
  TZ="Europe/Berlin"

# ---------------------------------------------------------------------------------------

COPY build /build

WORKDIR /usr/local/bin

# hadolint ignore=DL3003,DL3017,DL3018,DL3025,SC2086
RUN \
  apk update  --quiet && \
  apk upgrade --quiet && \
  apk add     --quiet --no-cache --virtual .build-deps \
    build-base imagemagick-dev mariadb-dev postgresql-dev ruby-dev ruby-rdoc tzdata zlib-dev && \
  apk add     --quiet --no-cache \
    bind-tools drill mariadb-connector-c mariadb-connector-c postgresql-client nano ruby-irb zlib && \
  cp "/usr/share/zoneinfo/${TZ}" /etc/localtime && \
  echo "${TZ}" > /etc/timezone && \
  echo 'gem: --no-document' >> /etc/gemrc && \
  gem install --quiet --no-rdoc --no-ri \
    io-console bundler json && \
  cd /build && \
  for g in /build/*.gem ; \
  do \
    [[ -e ${g} ]] || continue ; \
    echo "local gem: '${g}'" ; \
    gem install --no-rdoc --no-ri ${g} ; \
  done && \
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

CMD ["data-collector.rb"]

HEALTHCHECK \
  --interval=5s \
  --timeout=2s \
  --retries=12 \
  CMD ps ax | grep -c data-collector.rb || exit 1

# ---------------------------------------------------------------------------------------

LABEL \
  version="${BUILD_VERSION}" \
  maintainer="Bodo Schulz <bodo@coremedia.com>" \
  org.label-schema.build-date=${BUILD_DATE}

# ---------------------------------------------------------------------------------------
