
FROM golang:1-alpine as builder

COPY build/ /build

WORKDIR /build

RUN \
  apk update --quiet --no-cache && \
  apk upgrade --quiet --no-cache && \
  apk add --quiet --virtual .build-deps \
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
  TZ='Europe/Berlin'

EXPOSE 8080 8088

RUN \
  apk --quiet --no-cache update && \
  apk add --quiet --no-cache --virtual .build-deps \
    tzdata && \
  cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
  echo ${TZ} > /etc/timezone && \
  apk --quiet --purge del .build-deps && \
  rm -rf \
    /tmp/* \
    /var/cache/apk/*

COPY --from=builder /service-discovery /usr/bin/
COPY rootfs/ /

WORKDIR /

# ---------------------------------------------------------------------------------------

LABEL \
  version="${BUILD_VERSION}" \
  maintainer="Bodo Schulz <bodo@coremedia.com>" \
  org.label-schema.build-date=${BUILD_DATE}

# ---------------------------------------------------------------------------------------
