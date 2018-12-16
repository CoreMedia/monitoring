
FROM golang:1-alpine as builder

COPY build/ /build

WORKDIR /build

# hadolint ignore=DL3003,DL3017,DL3018,DL3019
RUN \
  apk update  --quiet && \
  apk upgrade --quiet && \
  apk add     --quiet \
    g++ git make && \
  export GOPATH=/build && \
  cd ${GOPATH}/src && \
  go get github.com/gorilla/mux && \
  go build -ldflags="-s -w" -o service-discovery && \
  mv service-discovery /

# ---------------------------------------------------------------------------------------

FROM bodsch/docker-jolokia:1.6.0

ARG BUILD_DATE
ARG BUILD_VERSION

ENV \
  VERSION="${BUILD_VERSION}" \
  BUILD_DATE="${BUILD_DATE}" \
  TERM="xterm" \
  TZ="Europe/Berlin"

# hadolint ignore=DL3018
RUN \
  apk update --quiet && \
  apk add    --quiet --no-cache --virtual .build-deps \
    tzdata && \
  cp "/usr/share/zoneinfo/${TZ}" /etc/localtime && \
  echo "${TZ}" > /etc/timezone && \
  apk --quiet --purge del .build-deps && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

COPY --from=builder /service-discovery /usr/bin/
COPY rootfs/ /

WORKDIR /

EXPOSE 8080 8088

# ---------------------------------------------------------------------------------------

LABEL \
  version="${BUILD_VERSION}" \
  maintainer="Bodo Schulz <bodo@coremedia.com>" \
  org.label-schema.build-date=${BUILD_DATE}

# ---------------------------------------------------------------------------------------
